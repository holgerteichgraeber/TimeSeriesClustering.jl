# optimization problems
"""
function setup_cep_opt_sets(ts_data::ClustData,opt_data::CEPData)

fetching sets from the time series (ts_data) and capacity expansion model data (opt_data) and returning Dictionary with Sets as Symbols
"""
function setup_opt_cep_set(ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any};
                            k_ids::Array{Int64}=Array{Int64,1}())
  set=Dict{String,Array}()
  set["nodes"]=opt_data.nodes[:nodes]
  #Seperate sets for fossil and renewable technology
  if opt_config["transmission"]
    set["lines"]=opt_data.lines[:lines]
  end
  set["tech"]=Array{String,1}()
  for categ in unique(opt_data.techs[:categ])
    if opt_config[categ]
      set["tech_"*categ]=opt_data.techs[opt_data.techs[:categ].==categ,:tech]
      set["tech"]=[set["tech"];set["tech_"*categ]]
    end
  end
  set["impact"]=String.(names(opt_data.cap_costs))[2:end]
  set["account"]=["cap_fix","var"]
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
  if opt_config["interstorage"]
    set["time_I"]=1:length(k_ids)
  end

  return set
end

"""
function setup_cep_opt_basic(ts_data::ClustData,opt_data::CEPData)

fetching sets from the time series (ts_data) and capacity expansion model data (opt_data) and returning Dictionary with Sets as Symbols
"""
function setup_opt_cep_basic(ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any},
                            solver::Any;
                            kwargs...)
   ## MODEL CEP ##
   # Initialize model
   model=Model(solver=solver)
   # Initialize info
   info=[opt_config["descriptor"]]
   # Setup set
   set=setup_opt_cep_set(ts_data, opt_data, opt_config; kwargs...)
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
  push!(cep.info,"Variable CAP[tech, infrastruct, nodes] ≥ 0]")
  @variable(cep.model, CAP[tech=set["tech"],infrastruct=set["infrastruct"],node=set["nodes"]]>=0)
  # Generation #
  push!(cep.info,"Variable GEN[sector, tech, t, k, node]")
  @variable(cep.model, GEN[sector=set["sector"], tech=set["tech"], t=set["time_T"], k=set["time_K"], node=set["nodes"]])
  #TODO Include Slack into CEP
  #@variable(cep, SLACK[t=set["time_T"], k=set["time_K"]]>=0)
  return cep
end


"""
function setup_opt_cep_fossil!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  add variable and fixed Costs and limit generation to installed capacity for fossil power plants
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
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_generation"]], cep.model[:COST]["var",impact,tech]==sum(cep.model[:GEN]["el",tech,t,k,node]*ts_weights[k]*findvalindf(var_costs,:tech,tech,impact) for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
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
  basic storage within each period (needs to be matched with intrastorage or interstorage)
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

    ## VARIABLE ##existing_infrastructure
    # Storage
    push!(cep.info,"Variable INTRASTOR[sector, tech, t, k, node] ≥ 0")
    @variable(cep.model, INTRASTOR[sector=set["sector"], tech=set["tech_storage"], t=set["time_T"], k=set["time_K"], node=set["nodes"]] >=0)

    ## STORAGE ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = Δt ⋅ Σ_{t,k,node}GEN['el',t,k,node]⋅ ts_weights[k] ⋅ var_costs[tech,impact] ∀ impact, tech_storage")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_storage"]], cep.model[:COST]["var",impact,tech]==sum(cep.model[:GEN]["el",tech,t,k,node]*ts_weights[k]*findvalindf(var_costs,:tech,tech,impact) for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
    # Fix Costs storage
    push!(cep.info,"COST['fix',impact,tech] = Σ_{node}CAP[tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_storage")
    @constraint(cep.model, [tech=set["tech_storage"], impact=set["impact"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node] for node=set["nodes"])*(findvalindf(cap_costs,:tech,tech,impact)+findvalindf(fix_costs,:tech,tech,impact)))
    # Limit the Generation of the theoretical power part of the battery to its installed power
    push!(cep.info,"GEN['el',tech, t, k, node] ≤ Σ_{exist} CAP[tech,exist,node] ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"], t=set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech,t,k,node]<=sum(cep.model[:CAP][tech,exist,node] for exist=set["infrastruct"]))
    # Limit the storage of the theoretical energy part of the battery to its installed power
    push!(cep.info,"STOR['el',tech, t, k, node] ≤ Σ_{exist} STOR[tech,exist,node]*e_p_ratio[tech] ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"], t=set["time_T"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,t,k,node]<=sum(cep.model[:CAP][tech,exist,node] for exist=set["infrastruct"])*findvalindf(techs,:tech,tech,"e_p_ratio"))
    # Connecting each iteration
    push!(cep.info,"INTRASTOR['el',tech, t+1, k, node] = INTRASTOR['el',tech, t, k, node] - GEN['el', tech, t, k, node] ⋅ η[tech] ∀ node, tech_storage, t, k")
    for t in set["time_T"][1:end-1]
      @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,t+1,k,node]==cep.model[:INTRASTOR]["el",tech,t,k,node] - cep.model[:GEN]["el",tech,t,k,node]*findvalindf(techs,:tech,tech,"efficiency"))
    end
    return cep
end

"""
function setup_opt_cep_intrastorage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  Looping constraint for each period
"""
function setup_opt_cep_intrastorage!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    ## DATA ##
    set=cep.set
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs

    ## INTRASTORAGE ##
    # Looping constraint for each period
    push!(cep.info,"INTRASTOR['el',tech, 't[1]', k, node] = INTRASTOR['el',tech, 't[end]', k, node] - GEN['el', tech, t, k, node] ⋅ η[tech] ∀ node, tech_storage, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,1,k,node]== cep.model[:INTRASTOR]["el",tech,set["time_T"][end],k,node]-cep.model[:GEN]["el",tech,set["time_T"][end],k,node]*findvalindf(techs,:tech,tech,"efficiency"))
    return cep
end

"""
function setup_opt_cep_interstorage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  missing rn
"""
function setup_opt_cep_interstorage!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            k_ids::Array{Int64})
    ## DATA ##
    set=cep.set
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs

    ## VARIABLE ##
    # Storage
    push!(cep.info,"Variable INTERSTOR[sector, tech, i, node] ≥ 0")
    @variable(cep.model, INTERSTOR[sector=set["sector"], tech=set["tech_storage"], i=set["time_I"], node=set["nodes"]]>=0)


    ## INTERSTORAGE ##
    # Limit the storage of the theoretical seasonal energy part of the battery to its installed power
    push!(cep.info,"INTERSTOR['el',tech, t, k, node] ≤ Σ_{exist} INTERSTOR[tech,exist,node]*e push!(plots,plot(get_cep_variable_value(model.variables['TRANS'],['trans',:,:])))_p_ratio[tech] ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"], i=set["time_I"]], cep.model[:INTERSTOR]["el",tech,i,node]<=sum(cep.model[:CAP][tech,exist,node] for exist=set["infrastruct"])*findvalindf(techs,:tech,tech,"e_p_ratio"))
    # Looping constraint for entire year
    push!(cep.info,"INTERSTOR['el',tech, '1', node] = INTERSTOR['el',tech, 'end', node] ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"]], cep.model[:INTERSTOR]["el",tech,1,node]== cep.model[:INTERSTOR]["el",tech,set["time_I"][end],node] -cep.model[:GEN]["el",tech,set["time_T"][end],k_ids[set["time_I"][end]],node]*findvalindf(techs,:tech,tech,"efficiency"))
    # Connecting each iteration
    push!(cep.info,"INTERSTOR['el',tech, i+1, node] = INTERSTOR['el',tech, i, node] + INTRASTOR['el',tech, 'k[i]', 't[end]', node] - INTRASTOR['el',tech, 'k[i]', 't[1]', node] - GEN['el', tech, 't[end]', 'k[i]', node] ⋅ η[tech] ∀ node, tech_storage, i")
    for i in set["time_I"][1:end-1]
        @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"]], cep.model[:INTERSTOR]["el",tech,i+1,node] == cep.model[:INTERSTOR]["el",tech,i,node] + cep.model[:INTRASTOR]["el",tech,set["time_T"][end],k_ids[i],node] - cep.model[:INTRASTOR]["el",tech,1,k_ids[i],node] -cep.model[:GEN]["el",tech,set["time_T"][end],k_ids[i],node]*findvalindf(techs,:tech,tech,"efficiency"))
    end
    return cep
end

"""
function setup_opt_cep_intrastorage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  Looping constraint for each period
"""
function setup_opt_cep_transmission!(cep::OptModelCEP,
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
    #lines       lines x [node_start,node_end,reactance,resistance,power,voltage,circuits,length]
    lines=opt_data.lines
    #ts_weights  Dict( tech-node ): k
    ts_weights=ts_data.weights

    ## VARIABLE ##
    # Storage
    push!(cep.info,"Variable FLOW[sector,  tech, t, k, line]")
    @variable(cep.model, FLOW[sector=set["sector"], tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"], node=set["lines"]])
    push!(cep.info,"Variable TRANS[tech,  infrastruct, lines] ≥ 0")
    @variable(cep.model, TRANS[tech=set["tech_transmission"], infrastruct=set["infrastruct"], line=set["lines"]]>=0)


    ## TRANSMISSION ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = 0 ∀ impact, tech_transmission")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_transmission"]], cep.model[:COST]["var",impact,tech]==0)
    # Calculate Fixed Costs
    push!(cep.info,"COST['fix',impact,tech] = Σ_{node}TRANS[tech,'new',line] ⋅ length[line] ⋅ cap_costs[tech,impact] ∀ impact, tech_transmission")
    @constraint(cep.model, [tech=set["tech_transmission"], impact=set["impact"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:TRANS][tech,"new",line]*findvalindf(lines,:lines,line,:length) for line=set["lines"])*(findvalindf(cap_costs,:tech,tech,impact)+findvalindf(fix_costs,:tech,tech,impact)))
    # Transmission has no capacity so fix to zero
    push!(cep.info,"CAP[tech, infrastruct, node] = 0 ∀ node, tech_transmission")
    @constraint(cep.model, [node=set["nodes"], infrastruct=set["infrastruct"], tech=set["tech_transmission"]], cep.model[:CAP][tech,infrastruct,node]==0)
    # Limit the flow per line
    push!(cep.info,"| FLOW['el',tech, t, k, line] | ≤ Σ_{exist}TRANS[tech,exist,line] ∀ line, tech_transmission, t, k")
    @constraint(cep.model, [line=set["lines"], tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"]], cep.model[:FLOW]["el",tech, t, k, line] <=sum(cep.model[:TRANS][tech,exist,line] for exist=set["infrastruct"]))
    @constraint(cep.model, [line=set["lines"], tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"]], (-1)*cep.model[:FLOW]["el",tech, t, k, line] <=sum(cep.model[:TRANS][tech,exist,line] for exist=set["infrastruct"]))
    # Calculate flow of each line
    push!(cep.info,"GEN['el',tech, t, k, node] = Σ_{line[node_end]} FLOW['el',tech, t, k, line]-Σ_{line[node_start]} FLOW['el',tech, t, k, line] ∀ tech_transmission, t, k")
    for node in set["nodes"]
      @constraint(cep.model, [tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech, t, k, node] == sum(cep.model[:FLOW]["el",tech, t, k, pos_line] for pos_line=mapsetindf(lines,:node_end,node,:lines))-sum(cep.model[:FLOW]["el",tech, t, k, neg_line] for neg_line=mapsetindf(lines,:node_start,node,:lines)))
    end
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
  if "tech_transmission" in keys(set)
    # Force the demand to match the generation either on copperplate
    push!(cep.info,"Σ_{tech}GEN['el',tech,t,k,node] = ts[el_demand-node,t,k] ∀ node,t,k")
    @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for tech=set["tech"]) == ts["el_demand-"*node][t,k])
  else
    # Force the demand to match the generation either on copperplate
    push!(cep.info,"Σ_{tech,node}GEN['el',tech,t,k,node] = Σ_{node}ts[el_demand-node,t,k] ∀ t,k")
    @constraint(cep.model, [t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for node=set["nodes"], tech=set["tech"]) == sum(ts["el_demand-"*node][t,k] for node=set["nodes"]))
  end
  return cep
end

"""
function setup_opt_cep_emissions!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP; co2_limit::Number=Inf)
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
  push!(cep.info,"CAP[tech, 'ex', node] = existing infrastructure ∀ node, tech")
  @constraint(cep.model, [node=set["nodes"], tech=set["tech"]], cep.model[:CAP][tech,"ex",node]==findvalindf(nodes,:nodes,node,tech))
  if "transmission" in keys(set)
    push!(cep.info,"TRANS[tech, 'ex', line] = existing infrastructure ∀ tech, node")
    @constraint(cep.model, [line=set["lines"], tech=set["tech_transmission"]], cep.model[:TRANS][tech,"ex",node]==findvalindf(lines,:line,line,:power))
  end
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
function solve_cep_opt_model(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
solving the cep model and writing it's results and co2_limit into an OptResult-Struct
"""
function solve_opt_cep(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any})
  status=solve(cep.model)
  objective=getobjectivevalue(cep.model)
  variables=Dict{String,OptVariable}()
  variables["COST"]=OptVariable(getvalue(cep.model[:COST]),"ov")
  variables["CAP"]=OptVariable(getvalue(cep.model[:CAP]),"dv")
  variables["GEN"]=OptVariable(getvalue(cep.model[:GEN]),"ov")
  if opt_config["storage"]
    variables["INTRASTOR"]=OptVariable(getvalue(cep.model[:INTRASTOR]),"ov")
    if opt_config["interstorage"]
      variables["INTERSTOR"]=OptVariable(getvalue(cep.model[:INTERSTOR]),"ov")
    end
  end
  if opt_config["transmission"]
    variables["TRANS"]=OptVariable(getvalue(cep.model[:TRANS]),"dv")
    variables["FLOW"]=OptVariable(getvalue(cep.model[:FLOW]),"ov")
  end
  currency=variables["COST"].axes[2][1]
  @info("Solved Scenario $(opt_config["descriptor"]): "*String(status)*" min COST[$currency]: $objective s.t. CO₂-Emissions per MWh ≤ $(opt_config["co2_limit"])")
  return OptResult(status,objective,variables,cep.set,cep.info,opt_config)
end
