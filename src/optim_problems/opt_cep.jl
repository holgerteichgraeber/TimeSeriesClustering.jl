# optimization problems
"""
function setup_cep_opt_sets(ts_data::ClustData,opt_data::CEPData)
 fetching sets from the time series (ts_data) and capacity expansion model data (opt_data) and returning Dictionary with Sets as Symbols
"""
function setup_opt_cep_set(ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any})
  set=Dict{String,Array}()
  set["nodes"]=opt_data.nodes[:nodes]
  #Seperate sets for fossil and renewable technology
  set["tech"]=Array{String,1}()
  for categ in unique(opt_data.techs[:categ])
    if opt_config[categ]
      set["tech_"*categ]=opt_data.techs[opt_data.techs[:categ].==categ,:tech]
      set["tech"]=[set["tech"];set["tech_"*categ]]
    end
  end
  set["impact"]=String.(names(opt_data.cap_costs))[2:end]
  set["account"]=["cap_fix","var"]
  if opt_config["storage_e"] && opt_config["storage_p"]
    set["dir_storage"]=["charge","discharge"]
  end
  if opt_config["existing_infrastructure"]
    set["infrastruct"]=["new","ex"]
  else
    set["infrastruct"]=["new"]
  end
  #QUESTION How to integrate different secotors?
  set["sector"]=unique(opt_data.techs[:sector])
  #Different set: set["sector"]=unique(opt_data.techs[:sector]) .. CAP[node,tech,sector]
  #Or specific variables for each sector ELCAP, HEATCAP
  set["time_K"]=1:ts_data.K
  set["time_T"]=1:ts_data.T
  set["time_T_e"]=0:ts_data.T
  return set
end


"""
function setup_cep_opt_basic(ts_data::ClustData,opt_data::CEPData)
  setting up the basic core elements for a CEP-model
"""
function setup_opt_cep_basic(ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any},
                            solver::Any)
   ## MODEL CEP ##
   # Initialize model
   model=Model(solver=solver)
   # Initialize info
   info=[opt_config["descriptor"]]
   # Setup set
   set=setup_opt_cep_set(ts_data, opt_data, opt_config)
   # Setup Model CEP
   return OptModelCEP(model,info,set)
 end


"""
function setup_opt_cep_variables!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP) set::Dict)
  Adding variables COST, CAP and GEN based on set
"""
function setup_opt_cep_variables!(cep::OptModelCEP,
                                  ts_data::ClustData,
                                  opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set

  ## VARIABLES ##
  # Cost
  push!(cep.info,"Variable COST[account, impact, tech]")
  @variable(cep.model, COST[account=set["account"],impact=set["impact"],tech=set["tech"]])
  # Capacity
  push!(cep.info,"Variable CAP[tech, exist, nodes] ≥ 0]")
  @variable(cep.model, CAP[tech=set["tech"],exist=set["infrastruct"],node=set["nodes"]]>=0)
  # Generation #
  push!(cep.info,"Variable GEN[sector, tech, t, k, node]")
  @variable(cep.model, GEN[sector=set["sector"], tech=set["tech"], t=set["time_T"], k=set["time_K"], node=set["nodes"]])
  #TODO Include Slack into CEP
  #@variable(cep, SLACK[t=set["time_T"], k=set["time_K"]]>=0)
  return cep
end

"""
function setup_opt_cep_existing_infrastructure!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  fixing existing infrastructure to CAP[tech, 'ex', node]
"""
function setup_opt_cep_existing_infrastructure!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set
  #nodes: nodes x installed capacity of different tech
  nodes=opt_data.nodes

  ## ASSIGN VALUES ##
  # Assign the existing capacity from the nodes table
  push!(cep.info,"CAP[tech, 'ex', node] = existing infrastructure ∀ tech, node")
  @constraint(cep.model, [node=set["nodes"], tech=set["tech"]], cep.model[:CAP][tech,"ex",node]==findvalindf(nodes,:nodes,node,tech))
  return cep
end


"""
function setup_opt_cep_generation_el!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  add variable and fixed Costs and limit generation to installed capacity (and limiting time_series, if dependency in techs defined) for fossil and renewable power plants
"""
function setup_opt_cep_generation_el!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    #QUESTION Will we always have dispatch an no dispatch? Otherwise problem with two sets!
    ## DATA ##
    set=cep.set
    #cap_costs   tech x impact[USD, CO2]
    cap_costs=opt_data.cap_costs
    #var_costs   tech x impact[USD, CO2]
    var_costs=opt_data.var_costs
    #fix_costs   tech x impact[USD, CO2]
    fix_costs=opt_data.fix_costs
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs
    #ts          Dict( tech-node ): t x k
    ts=ts_data.data
    #ts_weights  Dict( tech-node ): k
    ts_weights=ts_data.weights

    ## GENERATION ELECTRICITY ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = Δt ⋅ Σ_{t,k,node}GEN['el',t,k,node]⋅ ts_weights[k] ⋅ var_costs[tech,impact] ∀ impact, tech_generation")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_generation"]], cep.model[:COST]["var",impact,tech]==sum(cep.model[:GEN]["el",tech,t,k,node]*ts_weights[k]*findvalindf(var_costs,:tech,tech,Symbol(impact)) for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
    # Calculate Fixed Costs
    push!(cep.info,"COST['cap_fix',impact,tech] = Σ_{node}CAP[tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_generation")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_generation"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node] for node=set["nodes"])*(findvalindf(cap_costs,:tech,tech,impact)+findvalindf(fix_costs,:tech,tech,impact)))

    # Limit the generation of dispathables to the existing capacity of dispachable power plants
    push!(cep.info,"0 ≤ GEN['el',tech, t, k, node] ≤ Σ_{exist} CAP[tech,exist,node] ∀ node, tech_generation{dispatchable}, t, k")
    # Limit the generation of dispathables to the existing capacity of non-dispachable power plants
    push!(cep.info,"0 ≤ GEN['el',tech, t, k, node] ≤ Σ_{exist}CAP[tech,exist,node]*ts[tech-node,t,k] ∀ node, tech_generation{non_dispatchable}, t, k")
    for tech in set["tech_generation"]
      # Limit the generation of dispathables to the existing capacity of dispachable power plants
      if findvalindf(techs,:tech,tech,:time_series)=="none"
      @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]], 0 <=cep.model[:GEN]["el",tech, t, k, node])
      @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]],     cep.model[:GEN]["el",tech, t, k, node] <=sum(cep.model[:CAP][tech,exist,node] for exist=set["infrastruct"]))
      else
      # Limit the generation of dispathables to the existing capacity of non-dispachable power plants
      @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]], 0 <=cep.model[:GEN]["el",tech, t, k, node])
      @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]],     cep.model[:GEN]["el",tech,t,k,node] <=sum(cep.model[:CAP][tech,exist,node] for exist=set["infrastruct"])*ts[findvalindf(techs,:tech,tech,:time_series)*"-"*node][t,k])
      end
    end

    return cep
end

"""
function setup_opt_cep_storage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  add variables INTRASTORGEN and INTRASTOR, variable and fixed Costs, limit generation to installed power-capacity, connect intra-storage levels (within period) with generation
  basis for either intrastorage or interstorage
"""
function setup_opt_cep_storage!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    ## DATA ##
    set=cep.set
    #cap_costs   tech x impact[USD, CO2]
    cap_costs=opt_data.cap_costs
    #var_costs   tech x impact[USD, CO2]
    var_costs=opt_data.var_costs
    #fix_costs   tech x impact[USD, CO2]
    fix_costs=opt_data.fix_costs
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs
    #ts_weights  Dict( tech-node ): k
    ts_weights=ts_data.weights
    #important if segements have differing lengths
    ts_delta=1
    ## VARIABLE ##existing_infrastructure
    # Storage has additional element 0 for storage at hour 0 of day
    push!(cep.info,"Variable INTRASTOR[sector, tech, t, k, node] ≥ 0")
    @variable(cep.model, INTRASTOR[sector=set["sector"], tech=set["tech_storage_e"], t=set["time_T_e"], k=set["time_K"], node=set["nodes"]] >=0)
    # Storage generation is necessary for the efficiency
    push!(cep.info,"Variable INTRASTORGEN[sector, dir, tech, t, k, node] ≥ 0")
    @variable(cep.model, INTRASTORGEN[sector=set["sector"], dir=set["dir_storage"], tech=set["tech_storage_p"], t=set["time_T"], k=set["time_K"], node=set["nodes"]] >=0)
    ## STORAGE ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = 0 ∀ impact, tech_storage")
    @constraint(cep.model, [impact=set["impact"], tech=[set["tech_storage_p"];set["tech_storage_e"]]], cep.model[:COST]["var",impact,tech]==0)
    # Fix Costs storage
    push!(cep.info,"COST['fix',impact,tech] = Σ_{node}CAP[tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_storage")
    @constraint(cep.model, [tech=[set["tech_storage_p"];set["tech_storage_e"]], impact=set["impact"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node] for node=set["nodes"])*(findvalindf(cap_costs,:tech,tech,impact)+findvalindf(fix_costs,:tech,tech,impact)))
    # Limit the Generation of the theoretical power part of the battery to its installed power
    push!(cep.info,"INTRASTORGEN['el',dir,tech, t, k, node] ≤ Σ_{infrastruct} CAP[tech,infrastruct,node] ∀ node, dir_storage, tech_storage_p, t, k")
    @constraint(cep.model, [node=set["nodes"], dir=set["dir_storage"], tech=set["tech_storage_p"], t=set["time_T"], k=set["time_K"]], cep.model[:INTRASTORGEN]["el",dir,tech,t,k,node]<=sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"]))
    # Fix the Generation of the theoretical energy part of the battery to 0
    push!(cep.info,"GEN['el',tech, t, k, node] =0 ∀ node, tech_storage_e, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t=set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech,t,k,node]==0)
    # Connect the previous storage level and the integral of the flows with the new storage level
    push!(cep.info,"INTRASTOR['el',tech, t, k, node] = INTRASTOR['el',tech, t-1, k, node] + Δt ⋅ (STORGEN['el','charge',tech, t, k, node] ⋅ η[tech] - STORGEN['el','discharge',tech, t, k, node] / η[tech])∀ node, tech_storage_e, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t in set["time_T"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,t,k,node]==cep.model[:INTRASTOR]["el",tech,t-1,k,node] - cep.model[:INTRASTORGEN]["el","discharge",split(tech,"_")[1]*"_p",t,k,node] / findvalindf(techs,:tech,tech,"eff_out") + cep.model[:INTRASTORGEN]["el","charge",split(tech,"_")[1]*"_p",t,k,node] * findvalindf(techs,:tech,tech,"eff_in"))
    # Sum the INTRASTORGEN up to calculate the actual GEN of the technology
    push!(cep.info,"GEN['el',tech, t, k, node] = INTRASTORGEN['el','discharge',tech, t, k, node] - INTRASTORGEN['el','charge',tech, t, k, node] ∀ node, tech_storage_e, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_p"], t in set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech,t,k,node]==cep.model[:INTRASTORGEN]["el","discharge",tech,t,k,node]-cep.model[:INTRASTORGEN]["el","charge",tech,t,k,node])
    return cep
end

"""
function setup_opt_cep_intrastorage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  Looping constraint for each period (same start and end level for all periods) and limit storage to installed energy-capacity
"""
function setup_opt_cep_intrastorage!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    ## DATA ##
    set=cep.set
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs
    ## INTRASTORAGE ##
    # Limit the storage of the theoretical energy part of the battery to its installed power
    push!(cep.info,"INTRASTOR['el',tech, t, k, node] ≤ Σ_{infrastruct} CAP[tech,infrastruct,node] ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t=set["time_T"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,t,k,node]<=sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"]))
    # Set storage level at beginning and end of day equal
    push!(cep.info,"INTRASTOR['el',tech, '0', k, node] = INTRASTOR['el',tech, 't[end]', k, node] ∀ node, tech_storage_e, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,0,k,node]== cep.model[:INTRASTOR]["el",tech,set["time_T_e"][end],k,node])
    # Set the storage level at the beginning of each representative day to the same
    push!(cep.info,"INTRASTOR['el',tech, '0', k, node] = INTRASTOR['el',tech, '0', k, node] ∀ node, tech_storage_e, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,0,k,node]== cep.model[:INTRASTOR]["el",tech,0,1,node])
    return cep
end


"""
function setup_opt_cep_demand!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  Add demand which shall be matched by the generation (GEN)
"""
function setup_opt_cep_demand!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set
  #ts          Dict( tech-node ): t x k
  ts=ts_data.data

  ## DEMAND ##
  # Force the demand to match the generation
  push!(cep.info,"Σ_{tech,node}GEN['el',tech,t,k,node] = Σ_{node}ts[el_demand-node,t,k] ∀ t,k")
  @constraint(cep.model, [t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for node=set["nodes"], tech=set["tech"]) == sum(ts["el_demand-"*node][t,k] for node=set["nodes"]))
  return cep
end

"""
function setup_opt_cep_co2_limit!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP; co2_limit::Number=Inf)
  Add co2 emission constraint
"""
function setup_opt_cep_co2_limit!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP;
                            co2_limit::Number=Inf)
  ## DATA ##
  set=cep.set
  #ts          Dict( tech-node ): t x k
  ts=ts_data.data

  ## EMISSIONS ##
  # Limit the Emissions with co2_limit if it exists
  push!(cep.info,"ΣCOST_{account,tech}[account,'$(set["impact"][1])',tech] ≤ co2_limit*Σ_{node,t,k}ts[el_demand-node,t,k]")
  @constraint(cep.model, sum(cep.model[:COST][account,"CO2",tech] for account=set["account"], tech=set["tech"])<= co2_limit*sum(sum(ts["el_demand-"*node]) for node=set["nodes"]))
  return cep
end

"""
function setup_opt_cep_objective!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
    Calculate total system costs and set as objective
"""
function setup_opt_cep_objective!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set

  ## OBJECTIVE ##
  # Minimize the total €-Costs s.t. the Constraints introduced above
  push!(cep.info,"min Σ_{account,tech}COST[account,'$(set["impact"][1])',tech] st. above")
  @objective(cep.model, Min, sum(cep.model[:COST][account,set["impact"][1],tech] for account=set["account"], tech=set["tech"]))
  return cep
end

"""
function solve_opt_cep(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
solving the cep model and writing it's results and co2_limit into an OptResult-Struct
"""
function solve_opt_cep(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any})
  status=solve(cep.model)
  objective=getobjectivevalue(cep.model)
  variables=Dict{String,OptVariable}()
  # cv - Cost variable, dv - design variable, which is used to fix variables in a dispatch model, ov - operational variable
  variables["COST"]=OptVariable(getvalue(cep.model[:COST]),"cv")
  variables["CAP"]=OptVariable(getvalue(cep.model[:CAP]),"dv")
  variables["GEN"]=OptVariable(getvalue(cep.model[:GEN]),"ov")
  if opt_config["storage_p"] && opt_config["storage_e"]
    variables["INTRASTOR"]=OptVariable(getvalue(cep.model[:INTRASTOR]),"ov")
  end

  currency=variables["COST"].axes[2][1]
  @info("Solved Scenario $(opt_config["descriptor"]): "*String(status)*" min COST[$currency]: $objective s.t. CO₂-Emissions per MWh ≤ $(opt_config["co2_limit"])")
  return OptResult(status,objective,variables,cep.set,cep.info,opt_config)
end
