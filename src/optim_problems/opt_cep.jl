# optimization problems
"""
    setup_cep_opt_sets(ts_data::ClustData,opt_data::CEPData)
fetching sets from the time series (ts_data) and capacity expansion model data (opt_data) and returning Dictionary with Sets as Symbols
"""
function setup_opt_cep_set(ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any};
                            k_ids::Array{Int64}=Array{Int64,1}())
  set=Dict{String,Array}()
  set["nodes"]=unique(opt_data.nodes[:nodes])
  #Seperate sets for fossil and renewable technology
  set["tech"]=Array{String,1}()
  for categ in unique(opt_data.techs[:categ])
    if opt_config[categ]
      set["tech_"*categ]=opt_data.techs[opt_data.techs[:categ].==categ,:tech]
      set["tech"]=[set["tech"];set["tech_"*categ]]
    end
  end
  set["impact"]=String.(names(opt_data.cap_costs))[4:end]
  set["account"]=["cap_fix","var"]
  if opt_config["storage_e"] && opt_config["storage_p"]
    set["dir_storage"]=["charge","discharge"]
  end
  if opt_config["transmission"]
    set["lines"]=opt_data.lines[:lines]
    set["dir_transmission"]=["uniform","opposite"]
  end
  if opt_config["existing_infrastructure"]
    set["infrastruct"]=["new","ex"]
  else
    set["infrastruct"]=["new"]
  end
  set["sector"]=unique(opt_data.techs[:sector])
  #Different set: set["sector"]=unique(opt_data.techs[:sector]) .. CAP[node,tech,sector]
  #Or specific variables for each sector ELCAP, HEATCAP
  set["time_K"]=1:ts_data.K
  set["time_T"]=1:ts_data.T
  set["time_T_e"]=0:ts_data.T
  if opt_config["seasonalstorage"]
    set["time_I_e"]=0:length(k_ids)
    set["time_I"]=1:length(k_ids)
  end
  return set
end


"""
    setup_cep_opt_basic(ts_data::ClustData,opt_data::CEPData)
setting up the basic core elements for a CEP-model
"""
function setup_opt_cep_basic(ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any},
                            optimizer::DataType,
                            optimizer_config::Dict{Symbol,Any};
                            kwargs...)
   ## MODEL CEP ##
   # Initialize model
   model =  JuMP.Model(with_optimizer(optimizer;optimizer_config...))
   # Initialize info
   info=[opt_config["descriptor"]]
   # Setup set
   set=setup_opt_cep_set(ts_data, opt_data, opt_config; kwargs...)
   # Setup Model CEP
   return OptModelCEP(model,info,set)
 end


"""
    setup_opt_cep_basic_variables!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP) set::Dict)
Adding basic variables COST, CAP and GEN based on set
"""
function setup_opt_cep_basic_variables!(cep::OptModelCEP,
                                  ts_data::ClustData,
                                  opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set

  ## VARIABLES ##
  # Cost
  push!(cep.info,"Variable COST[account, impact, tech] in $(set["impact"].*" "...)")
  @variable(cep.model, COST[account=set["account"],impact=set["impact"],tech=set["tech"]])
  # Capacity
  push!(cep.info,"Variable CAP[tech, infrastruct, nodes] ≥ 0 in MW]")
  if "tech_transmission" in keys(set) #if transmission is in tech, exclude the transmission technology from the setup of variable CAP
    @variable(cep.model, CAP[tech=setdiff(set["tech"],set["tech_transmission"]),infrastruct=set["infrastruct"] ,node=set["nodes"]]>=0)
  else
  @variable(cep.model, CAP[tech=set["tech"],infrastruct=set["infrastruct"] ,node=set["nodes"]]>=0)
  end
  # Generation #
  push!(cep.info,"Variable GEN[sector, tech, t, k, node] in MW")
  @variable(cep.model, GEN[sector=set["sector"], tech=set["tech"], t=set["time_T"], k=set["time_K"], node=set["nodes"]])
  return cep
end

"""
     setup_opt_cep_lost_load!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP) set::Dict)
  Adding variable SLACK, LL (LostLoad - if demand cannot be met with installed capacity -> Lost Load can be "purchased" to meet demand)
"""
function setup_opt_cep_lost_load!(cep::OptModelCEP,
                                  ts_data::ClustData,
                                  opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set
  #ts_weights: k - weight of each period:
  ts_weights=ts_data.weights
  #ts_deltas:  t x k - Δt of each segment x period
  ts_deltas=1

  ## LOST LOAD ##
  # Slack variable #
  push!(cep.info,"Variable SLACK[sector, t, k, node] ≥ 0 in MW")
  @variable(cep.model, SLACK[sector=set["sector"], t=set["time_T"], k=set["time_K"], node=set["nodes"]] >=0)
  # Lost Load variable #
  push!(cep.info,"Variable LL[sector, node] ≥ 0 in MWh")
  @variable(cep.model, LL[sector=set["sector"], node=set["nodes"]] >=0)
  # Calculation of Lost Load
  push!(cep.info,"LL[sector, node] = Σ SLACK[sector, t, k, node] ⋅ ts_weights[k] ⋅ Δt[t,k] ∀ sector, node")
  @constraint(cep.model, [sector=set["sector"], node=set["nodes"]], cep.model[:LL][sector, node]==sum(cep.model[:SLACK][sector, t, k, node]*ts_weights[k]*ts_deltas for t=set["time_T"], k=set["time_K"]))
  return cep
end

"""
     setup_opt_cep_lost_emission!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
  Adding variable LE (LostEmission - if demand cannot be met without breaking Emission-constraint -> Lost Emission can be "purchased" to meet demand with "dirty" production)
"""
function setup_opt_cep_lost_emission!(cep::OptModelCEP,
                              ts_data::ClustData,
                              opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set

  ## LOST EMISSION ##
  # Lost Emission variable #
  push!(cep.info,"Variable LE[impact_{environment}] ≥ 0 in kg")
  @variable(cep.model, LE[impact=["CO2"]] >=0)
  return cep
end

"""
     setup_opt_cep_fix_design_variables!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP) set::Dict)
Fixing variables CAP based on first stage vars
"""
function setup_opt_cep_fix_design_variables!(cep::OptModelCEP,
                                  ts_data::ClustData,
                                  opt_data::OptDataCEP;
                                  fixed_design_variables::Dict{String,OptVariable}=Dict{String,OptVariable}())
  ## DATA ##
  set=cep.set
  cap=fixed_design_variables["CAP"]

  ## VARIABLES ##
  # Capacity
  push!(cep.info,"CAP[tech, 'new', node] = existing infrastructure ∀ node, tech")
  @constraint(cep.model, [node=set["nodes"], tech=set["tech"]], cep.model[:CAP][tech,"new",node]==get_cep_variable_value(cap,[tech, "new", node]))
  return cep
end

"""
     setup_opt_cep_generation_el!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
add variable and fixed Costs and limit generation to installed capacity (and limiting time_series, if dependency in techs defined) for fossil and renewable power plants
"""
function setup_opt_cep_generation_el!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    ## DATA ##
    set=cep.set
    #nodes: nodes x region, infrastruct, capacity_of_different_tech...
    nodes=opt_data.nodes
    #cap_costs   tech x region, year, impact[USD, CO2]...
    cap_costs=opt_data.cap_costs
    #var_costs   tech x region, year, impact[USD, CO2]...
    var_costs=opt_data.var_costs
    #fix_costs   tech x region, year, impact[USD, CO2]...
    fix_costs=opt_data.fix_costs
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs
    #ts          Dict( tech-node ): t x k
    ts=ts_data.data
    #ts_weights: k - weight of each period:
    ts_weights=ts_data.weights
    #ts_deltas:  t x k - Δt of each segment x period
    ts_deltas=1


    ## GENERATION ELECTRICITY ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = Σ_{t,k,node}GEN['el',t,k,node]⋅ ts_weights[k] ⋅ ts_deltas ⋅ var_costs[tech,impact] ∀ impact, tech_generation")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_generation"]], cep.model[:COST]["var",impact,tech]==sum(cep.model[:GEN]["el",tech,t,k,node]*ts_weights[k]*ts_deltas*find_cost_in_df(var_costs,nodes,tech,node,impact) for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
    # Calculate Fixed Costs
    push!(cep.info,"COST['cap_fix',impact,tech] = Σ_{node}CAP[tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_generation")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_generation"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node] *(find_cost_in_df(cap_costs,nodes,tech,node,impact)+find_cost_in_df(fix_costs,nodes,tech,node,impact)) for node=set["nodes"]))

    # Limit the generation of dispathables to the infrastructing capacity of dispachable power plants
    push!(cep.info,"0 ≤ GEN['el',tech, t, k, node] ≤ Σ_{infrastruct} CAP[tech,infrastruct,node] ∀ node, tech_generation{dispatchable}, t, k")
    # Limit the generation of dispathables to the infrastructing capacity of non-dispachable power plants
    push!(cep.info,"0 ≤ GEN['el',tech, t, k, node] ≤ Σ_{infrastruct}CAP[tech,infrastruct,node]*ts[tech-node,t,k] ∀ node, tech_generation{non_dispatchable}, t, k")
    for tech in set["tech_generation"]
      # Limit the generation of dispathables to the infrastructing capacity of dispachable power plants
      if find_val_in_df(techs,:tech,tech,:time_series)=="none"
        @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]], 0 <=cep.model[:GEN]["el",tech, t, k, node])
        @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]],     cep.model[:GEN]["el",tech, t, k, node] <=sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"]))
      else
        # Limit the generation of dispathables to the infrastructing capacity of non-dispachable power plants
        @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]], 0 <=cep.model[:GEN]["el",tech, t, k, node])
        @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]],     cep.model[:GEN]["el",tech,t,k,node] <= sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"])*ts[find_val_in_df(techs,:tech,tech,:time_series)*"-"*node][t,k])
      end
    end

    return cep
end

"""
     setup_opt_cep_storage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
add variables INTRASTORGEN and INTRASTOR, variable and fixed Costs, limit generation to installed power-capacity, connect simple-storage levels (within period) with generation
basis for either simplestorage or seasonalstorage
"""
function setup_opt_cep_storage!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    ## DATA ##
    set=cep.set
    #nodes: nodes x region, infrastruct, capacity_of_different_tech...
    nodes=opt_data.nodes
    #cap_costs   tech x region, year, impact[USD, CO2]...
    cap_costs=opt_data.cap_costs
    #var_costs   tech x region, year, impact[USD, CO2]...
    var_costs=opt_data.var_costs
    #fix_costs   tech x region, year, impact[USD, CO2]...
    fix_costs=opt_data.fix_costs
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs
    #ts_deltas:  t x k - Δt of each segment x period
    ts_deltas=1

    ## VARIABLE ##existing_infrastructure
    # Storage has additional element 0 for storage at hour 0 of day
    push!(cep.info,"Variable INTRASTOR[sector, tech, t, k, node] ≥ 0 in MWh")
    @variable(cep.model, INTRASTOR[sector=set["sector"], tech=set["tech_storage_e"], t=set["time_T_e"], k=set["time_K"], node=set["nodes"]] >=0)
    # Storage generation is necessary for the efficiency
    push!(cep.info,"Variable INTRASTORGEN[sector, dir, tech, t, k, node] ≥ 0 in MW")
    @variable(cep.model, INTRASTORGEN[sector=set["sector"], dir=set["dir_storage"], tech=set["tech_storage_p"], t=set["time_T"], k=set["time_K"], node=set["nodes"]] >=0)
    ## STORAGE ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = 0 ∀ impact, tech_storage")
    @constraint(cep.model, [impact=set["impact"], tech=[set["tech_storage_p"];set["tech_storage_e"]]], cep.model[:COST]["var",impact,tech]==0)
    # Fix Costs storage
    push!(cep.info,"COST['fix',impact,tech] = Σ_{node}CAP[tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_storage")
    @constraint(cep.model, [tech=[set["tech_storage_p"];set["tech_storage_e"]], impact=set["impact"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node]*(find_cost_in_df(cap_costs,nodes,tech,node,impact)+find_cost_in_df(fix_costs,nodes,tech,node,impact)) for node=set["nodes"]))
    # Limit the Generation of the theoretical power part of the battery to its installed power
    push!(cep.info,"INTRASTORGEN['el',dir,tech, t, k, node] ≤ Σ_{infrastruct} CAP[tech,infrastruct,node] ∀ node, dir_storage, tech_storage_p, t, k")
    @constraint(cep.model, [node=set["nodes"], dir=set["dir_storage"], tech=set["tech_storage_p"], t=set["time_T"], k=set["time_K"]], cep.model[:INTRASTORGEN]["el",dir,tech,t,k,node]<=sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"]))
    # Fix the Generation of the theoretical energy part of the battery to 0
    push!(cep.info,"GEN['el',tech, t, k, node] =0 ∀ node, tech_storage_e, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t=set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech,t,k,node]==0)
    # Connect the previous storage level and the integral of the flows with the new storage level
    push!(cep.info,"INTRASTOR['el',tech, t, k, node] = INTRASTOR['el',tech, t-1, k, node] + ts_deltas ⋅ (STORGEN['el','charge',tech, t, k, node] ⋅ η[tech] - STORGEN['el','discharge',tech, t, k, node] / η[tech])∀ node, tech_storage_e, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t in set["time_T"], k=set["time_K"]], cep.model[:INTRASTOR]["el",tech,t,k,node]==cep.model[:INTRASTOR]["el",tech,t-1,k,node] + ts_deltas * (cep.model[:INTRASTORGEN]["el","charge",split(tech,"_")[1]*"_p",t,k,node] * find_val_in_df(techs,:tech,tech,"eff_in") - cep.model[:INTRASTORGEN]["el","discharge",split(tech,"_")[1]*"_p",t,k,node] / find_val_in_df(techs,:tech,tech,"eff_out")))
    # Sum the INTRASTORGEN up to calculate the actual GEN of the technology
    push!(cep.info,"GEN['el',tech, t, k, node] = INTRASTORGEN['el','discharge',tech, t, k, node] - INTRASTORGEN['el','charge',tech, t, k, node] ∀ node, tech_storage_e, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_p"], t in set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech,t,k,node]==cep.model[:INTRASTORGEN]["el","discharge",tech,t,k,node]-cep.model[:INTRASTORGEN]["el","charge",tech,t,k,node])
    return cep
end

"""
     setup_opt_cep_simplestorage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
Adding only intra-day storage:
Looping constraint for each period (same start and end level for all periods) and limit storage to installed energy-capacity
"""
function setup_opt_cep_simplestorage!(cep::OptModelCEP,
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
     setup_opt_cep_seasonalstorage!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
Adding inter-day storage:
add variable INTERSTOR, calculate seasonal-storage-level and limit total storage to installed energy-capacity
"""
function setup_opt_cep_seasonalstorage!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            #TODO get rid of k_ids here
                            k_ids::Array{Int64})
    ## DATA ##
    set=cep.set
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs

    ## VARIABLE ##
    # Storage
    push!(cep.info,"Variable INTERSTOR[sector, tech, i, node] ≥ 0 in MWh")
    @variable(cep.model, INTERSTOR[sector=set["sector"], tech=set["tech_storage_e"], i=set["time_I_e"], node=set["nodes"]]>=0)


    ## INTERSTORAGE ##
    # Set storage level at the beginning of the year equal to the end of the year
    push!(cep.info,"INTERSTOR['el',tech, '0', node] = INTERSTOR['el',tech, 'end', node] ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"]], cep.model[:INTERSTOR]["el",tech,0,node]== cep.model[:INTERSTOR]["el",tech,set["time_I_e"][end],node])
    # Connect the previous seasonal-storage level and the daily difference of the corresponding simple-storage with the new seasonal-storage level
    push!(cep.info,"INTERSTOR['el',tech, i+1, node] = INTERSTOR['el',tech, i, node] + INTRASTOR['el',tech, 'k[i]', 't[end]', node] - INTRASTOR['el',tech, 'k[i]', 't[1]', node] - GEN['el', tech, 't[end]', 'k[i]', node] ⋅ η[tech] ∀ node, tech_storage_e, i")
    # Limit the total storage (seasonal and simple) to be greater than zero and less than total storage cap
    push!(cep.info,"0 ≤ INTERSTOR['el',tech, i, node] + INTRASTOR['el',tech, t, k[i], node] ≤ Σ_{infrastruct} INTERSTOR[tech,infrastruct,node] ∀ node, tech_storage_e, i, t")
    push!(cep.info,"0 ≤ INTERSTOR['el',tech, i, node] + INTRASTOR['el',tech, t, k[i], node] ≤ Σ_{infrastruct} INTERSTOR[tech,infrastruct,node] ∀ node, tech_storage_e, i, t")
    for i in set["time_I"]
        @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"]], cep.model[:INTERSTOR]["el",tech,i,node] == cep.model[:INTERSTOR]["el",tech,i-1,node] + cep.model[:INTRASTOR]["el",tech,set["time_T"][end],k_ids[i],node] - cep.model[:INTRASTOR]["el",tech,0,k_ids[i],node])
        @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t=set["time_T_e"]], 0 <= cep.model[:INTERSTOR]["el",tech,i,node]+cep.model[:INTRASTOR]["el",tech,t,k_ids[i],node])
        @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage_e"], t=set["time_T_e"]], cep.model[:INTERSTOR]["el",tech,i,node]+cep.model[:INTRASTOR]["el",tech,t,k_ids[i],node] <= sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"]))
    end
    return cep
end

"""
     setup_opt_cep_transmission!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
Setup variable FLOW and TRANS, calculate fixed and variable COSTs, set CAP-trans to zero, limit FLOW with TRANS, calculate GEN-trans for each node
"""
function setup_opt_cep_transmission!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
    ## DATA ##
    set=cep.set
    #nodes: nodes x region, infrastruct, capacity_of_different_tech...
    nodes=opt_data.nodes
    #cap_costs   tech x region, year, impact[USD, CO2]...
    cap_costs=opt_data.cap_costs
    #var_costs   tech x region, year, impact[USD, CO2]...
    var_costs=opt_data.var_costs
    #fix_costs   tech x region, year, impact[USD, CO2]...
    fix_costs=opt_data.fix_costs
    #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
    techs=opt_data.techs
    #lines       lines x [node_start,node_end,reactance,resistance,power,voltage,circuits,length]
    lines=opt_data.lines

    ## VARIABLE ##
    # Add varibale FLOW
    push!(cep.info,"Variable FLOW[sector, dir, tech, t, k, line] ≥ 0 in MW")
    @variable(cep.model, FLOW[sector=set["sector"], dir=set["dir_transmission"], tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"], node=set["lines"]] >= 0)
    # Add variable TRANS
    push!(cep.info,"Variable TRANS[tech,  infrastruct, lines] ≥ 0 in MW")
    @variable(cep.model, TRANS[tech=set["tech_transmission"], infrastruct=set["infrastruct"], line=set["lines"]] >= 0)


    ## TRANSMISSION ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = 0 ∀ impact, tech_transmission")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_transmission"]], cep.model[:COST]["var",impact,tech] == 0)
    # Calculate Fixed Costs
    push!(cep.info,"COST['fix',impact,tech] = Σ_{node}(TRANS[tech,'new',line] ⋅ length[line]) ⋅ cap_costs[tech,impact] ∀ impact, tech_transmission")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_transmission"]], cep.model[:COST]["cap_fix",impact,tech] == sum(cep.model[:TRANS][tech,"new",line]*find_val_in_df(lines,:lines,line,:length) *(find_cost_in_df(cap_costs,nodes,tech,find_val_in_df(lines,:lines,line,:node_start),impact)+find_cost_in_df(fix_costs,nodes,tech,find_val_in_df(lines,:lines,line,:node_start),impact)) for line=set["lines"]))
    # Limit the flow per line to the existing infrastructure
    push!(cep.info,"| FLOW['el', dir, tech, t, k, line] | ≤ Σ_{infrastruct}TRANS[tech,infrastruct,line] ∀ line, tech_transmission, t, k")
    @constraint(cep.model, [line=set["lines"], dir=set["dir_transmission"], tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"]], cep.model[:FLOW]["el",dir, tech, t, k, line] <= sum(cep.model[:TRANS][tech,infrastruct,line] for infrastruct=set["infrastruct"]))
    # Calculate the sum of the flows for each node
    push!(cep.info,"GEN['el',tech, t, k, node] = Σ_{line_pos_float_to_node} FLOW['el',tech, t, k, line] ⋅ (1-η[tech]⋅length[line]) - Σ_{line_pos} FLOW['el',tech, t, k, line] ∀ tech_transmission, t, k")
    for node in set["nodes"]
      @constraint(cep.model, [tech=set["tech_transmission"], t=set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech, t, k, node] == sum(cep.model[:FLOW]["el","uniform",tech, t, k, line_end]*find_line_eff_in_df(lines,techs,line_end,tech,:eff_out) - cep.model[:FLOW]["el","opposite",tech, t, k, line_end]/find_line_eff_in_df(lines,techs,line_end,tech,:eff_in) for line_end=map_set_in_df(lines,:node_end,node,:lines)) + sum(cep.model[:FLOW]["el","opposite",tech, t, k, line_start]*find_line_eff_in_df(lines,techs,line_start,tech,:eff_out) - cep.model[:FLOW]["el","uniform",tech, t, k, line_start]/find_line_eff_in_df(lines,techs,line_start,tech,:eff_in) for line_start=map_set_in_df(lines,:node_start,node,:lines)))
    end
    return cep
end


"""
    setup_opt_cep_demand!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
Add demand which shall be matched by the generation (GEN)
"""
function setup_opt_cep_demand!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            lost_load_cost::Dict{String,Number})
  ## DATA ##
  set=cep.set
  #ts          Dict( tech-node ): t x k
  ts=ts_data.data

  ## DEMAND ##
  if "tech_transmission" in keys(set) && lost_load_cost["el"]!=Inf
    # Force the demand and slack to match the generation either with transmission
    push!(cep.info,"Σ_{tech}GEN['el',tech,t,k,node] = ts[el_demand-node,t,k]-SLACK['el',t,k,node] ∀ node,t,k")
    @constraint(cep.model, [node=set["nodes"], t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for tech=set["tech"]) == ts["el_demand-"*node][t,k]-cep.model[:SLACK]["el",t,k,node])
  elseif !("tech_transmission" in keys(set)) && lost_load_cost["el"]!=Inf
    # or on copperplate
    push!(cep.info,"Σ_{tech,node}GEN['el',tech,t,k,node]= Σ_{node}ts[el_demand-node,t,k]-SLACK['el',t,k,node] ∀ t,k")
    @constraint(cep.model, [t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for node=set["nodes"], tech=set["tech"]) == sum(ts["el_demand-"*node][t,k]-cep.model[:SLACK]["el",t,k,node] for node=set["nodes"]))
  elseif "tech_transmission" in keys(set) && lost_load_cost["el"]==Inf
    # Force the demand without slack to match the generation either with transmission
    for node in set["nodes"]
      push!(cep.info,"Σ_{tech}GEN['el',tech,t,k,node] = ts[el_demand-node,t,k] ∀ node,t,k")
      @constraint(cep.model, [t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for tech=set["tech"]) == ts["el_demand-"*node][t,k])
    end
  else
    # or on copperplate
    push!(cep.info,"Σ_{tech,node}GEN['el',tech,t,k,node]= Σ_{node}ts[el_demand-node,t,k]∀ t,k")
    @constraint(cep.model, [t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for node=set["nodes"], tech=set["tech"]) == sum(ts["el_demand-"*node][t,k] for node=set["nodes"]))
  end
  return cep
end

"""
     setup_opt_cep_co2_limit!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP; co2_limit::Number=Inf)
Add co2 emission constraint
"""
function setup_opt_cep_co2_limit!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            lost_emission_cost::Dict{String,Number};
                            co2_limit::Number=Inf)
  ## DATA ##
  set=cep.set
  #ts          Dict( tech-node ): t x k
  ts=ts_data.data
  #ts_weights: k - weight of each period:
  ts_weights=ts_data.weights
  #ts_deltas:  t x k - Δt of each segment x period
  ts_deltas=1

  ## EMISSIONS ##
  if lost_emission_cost["CO2"]!=Inf
    # Limit the Emissions with co2_limit if it exists
    push!(cep.info,"ΣCOST_{account,tech}[account,'$(set["impact"][1])',tech] ≤ LE['CO2'] + co2_limit Σ_{node,t,k} ts[el_demand-node,t,k] ⋅ ts_weights[k] ⋅ ts_deltas")
    @constraint(cep.model, sum(cep.model[:COST][account,"CO2",tech] for account=set["account"], tech=set["tech"])<= cep.model[:LE]["CO2"] +  co2_limit*sum(ts["el_demand-"*node][t,k]*ts_deltas*ts_weights[k] for t=set["time_T"], k=set["time_K"], node=set["nodes"]))
  else
    # Limit the Emissions with co2_limit if it exists
    # Total demand can also be determined with the function get_total_demand() edit both in case of changes of e.g. ts_deltas
    # QUESTION Do we want to include the the function here instead of the mathematical expression?
    push!(cep.info,"ΣCOST_{account,tech}[account,'$(set["impact"][1])',tech] ≤ co2_limit ⋅ Σ_{node,t,k} ts[el_demand-node,t,k] ⋅ ts_weights[k] ⋅ ts_deltas")
    @constraint(cep.model, sum(cep.model[:COST][account,"CO2",tech] for account=set["account"], tech=set["tech"])<= co2_limit*sum(ts["el_demand-$node"][t,k]*ts_weights[k]*ts_deltas for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
  end
  return cep
end

"""
     setup_opt_cep_existing_infrastructure!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
fixing existing infrastructure to CAP[tech, 'ex', node]
"""
function setup_opt_cep_existing_infrastructure!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set
  #nodes: nodes x region, infrastruct, capacity_of_different_tech...
  nodes=opt_data.nodes

  ## ASSIGN VALUES ##
  # Assign the existing capacity from the nodes table
  push!(cep.info,"CAP[tech, 'ex', node] = existing infrastructure ∀ node, tech")
  @constraint(cep.model, [node=set["nodes"], tech=set["tech"]], cep.model[:CAP][tech,"ex",node]==find_val_in_df(nodes,:infrastruct,"ex",:nodes,node,tech))
  if "transmission" in keys(set)
    push!(cep.info,"TRANS[tech, 'ex', line] = existing infrastructure ∀ tech, node")
    @constraint(cep.model, [line=set["lines"], tech=set["tech_transmission"]], cep.model[:TRANS][tech,"ex",node]==find_val_in_df(lines,:line,line,:power))
  end
  return cep
end

"""
     setup_opt_cep_limit_infrastructure!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
limit infrastructure setup of CAP[tech, sum(infrastuct), node]
NOTE just for CAP not for TRANS implemented
"""
function setup_opt_cep_limit_infrastructure!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP)
  ## DATA ##
  set=cep.set
  #nodes: nodes x region, infrastruct, capacity_of_different_tech...
  nodes=opt_data.nodes

  ## ASSIGN VALUES ##
  # Limit the capacity for each tech at each node with the limit provided in nodes table in column infrastruct
  push!(cep.info,"∑_{infrastuct} CAP[tech, infrastruct, node] <= limit infrastructure ∀ node, tech")
  @constraint(cep.model, [node=set["nodes"], tech=set["tech"]], sum(cep.model[:CAP][tech,infrastruct,node] for infrastruct=set["infrastruct"]) <= find_val_in_df(nodes,:nodes,node,:infrastruct,"lim",tech))
  return cep
end

"""
     setup_opt_cep_objective!(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
Calculate total system costs and set as objective
"""
function setup_opt_cep_objective!(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            lost_load_cost::Dict{String,Number},
                            lost_emission_cost::Dict{String,Number})
  ## DATA ##
  set=cep.set

  ## OBJECTIVE ##
  # Minimize the total €-Costs s.t. the Constraints introduced above
  if lost_load_cost["el"]==Inf && lost_emission_cost["CO2"]==Inf
    push!(cep.info,"min Σ_{account,tech}COST[account,'$(set["impact"][1])',tech] st. above")
    @objective(cep.model, Min,  sum(cep.model[:COST][account,set["impact"][1],tech] for account=set["account"], tech=set["tech"]))
  elseif lost_load_cost["el"]!=Inf && lost_emission_cost["CO2"]==Inf
    push!(cep.info,"min Σ_{account,tech}COST[account,'$(set["impact"][1])',tech] + Σ_{node} LL['el'] ⋅ $(lost_load_cost["el"]) st. above")
    @objective(cep.model, Min,  sum(cep.model[:COST][account,set["impact"][1],tech] for account=set["account"], tech=set["tech"]) + sum(cep.model[:LL]["el",node] for node=set["nodes"])*lost_load_cost["el"])
  elseif lost_load_cost["el"]==Inf && lost_emission_cost["CO2"]!=Inf
    push!(cep.info,"min Σ_{account,tech}COST[account,'$(set["impact"][1])',tech] +  LE['CO2'] ⋅ $(lost_emission_cost["CO2"]) st. above")
    @objective(cep.model, Min,  sum(cep.model[:COST][account,set["impact"][1],tech] for account=set["account"], tech=set["tech"]) +  cep.model[:LE]["CO2"]*lost_emission_cost["CO2"])
  else
    push!(cep.info,"min Σ_{account,tech}COST[account,'$(set["impact"][1])',tech] + Σ_{node} LL['el'] ⋅ $(lost_load_cost["el"]) +  LE['CO2'] ⋅ $(lost_emission_cost["CO2"]) st. above")
    @objective(cep.model, Min,  sum(cep.model[:COST][account,set["impact"][1],tech] for account=set["account"], tech=set["tech"]) + sum(cep.model[:LL]["el",node] for node=set["nodes"])*lost_load_cost["el"] + cep.model[:LE]["CO2"]*lost_emission_cost["CO2"])
  end
  return cep
end

"""
     solve_opt_cep(cep::OptModelCEP, ts_data::ClustData, opt_data::OptDataCEP)
solving the cep model and writing it's results and `co2_limit` into an OptResult-Struct
"""
function solve_opt_cep(cep::OptModelCEP,
                            ts_data::ClustData,
                            opt_data::OptDataCEP,
                            opt_config::Dict{String,Any})
  optimize!(cep.model)
  status=Symbol(termination_status(cep.model))
  objective=objective_value(cep.model)
  total_demand=get_total_demand(cep,ts_data)
  variables=Dict{String,OptVariable}()
  # cv - Cost variable, dv - design variable, which is used to fix variables in a dispatch model, ov - operational variable

  variables["COST"]=OptVariable(cep,:COST,"cv")
  variables["CAP"]=OptVariable(cep,:CAP,"dv")
  variables["GEN"]=OptVariable(cep,:GEN,"ov")
  lost_load=0
  lost_emission=0
  if opt_config["lost_load_cost"]["el"]!=Inf
    variables["SLACK"]=OptVariable(cep,:SLACK,"sv")
    variables["LL"]=OptVariable(cep,:LL,"sv")
    lost_load=sum(variables["LL"].data)
  end
  if opt_config["lost_emission_cost"]["CO2"]!=Inf
    variables["LE"]=OptVariable(cep,:LE,"sv")
    lost_emission=sum(variables["LE"].data)
  end
  if opt_config["storage_p"] && opt_config["storage_e"]
    variables["INTRASTOR"]=OptVariable(cep,:INTRASTOR,"ov")
    if opt_config["seasonalstorage"]
      variables["INTERSTOR"]=OptVariable(cep,:INTERSTOR,"ov")
    end
  end
  if opt_config["transmission"]
    variables["TRANS"]=OptVariable(cep,:TRANS,"dv")
    variables["FLOW"]=OptVariable(cep,:FLOW,"ov")
  end
  currency=variables["COST"].axes[2][1]
  if lost_load==0 && lost_emission==0
    opt_config["print_flag"] && @info("Solved Scenario $(opt_config["descriptor"]): "*String(status)*" min COST: $(round(objective,sigdigits=4)) [$currency] ⇨ $(round(objective/total_demand,sigdigits=4)) [$currency per MWh] s.t. Emissions ≤ $(opt_config["co2_limit"]) [kg-CO₂-eq. per MWh]")
  else
    opt_config["print_flag"] && @info("Solved Scenario $(opt_config["descriptor"]): "*String(status)*" min COST: $(round(sum(get_cep_variable_value(variables["COST"], [:,1,:])),sigdigits=4)) [$currency] ⇨ $(round(sum(get_cep_variable_value(variables["COST"], [:,1,:]))/total_demand,sigdigits=4)) [$currency per MWh] with LL: $lost_load [MWh] s.t. Emissions ≤ $(opt_config["co2_limit"]) + $(round(lost_emission/total_demand,sigdigits=4)) (violation) [kg-CO₂-eq. per MWh]")
  end
  return OptResult(status,objective,total_demand,variables,cep.set,cep.info,opt_config)
end
