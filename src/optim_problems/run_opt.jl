# optimization problems
"""
function setup_cep_opt_sets(tsdata::ClustInputData,cepdata::CEPData)

fetching sets from the time series (tsdata) and capacity expansion model data (cepdata) and returning Dictionary with Sets as Symbols
"""
function setup_cep_opt_sets(tsdata::ClustInputData,
                            cepdata::CEPData;
                            existing_infrastructure::Bool=false
                            )
  set=Dict{String,Array}()
  set["nodes"]=cepdata.nodes[:nodes]
  #Seperate sets for fossil and renewable technology
  for cat in unique(cepdata.techs[:categ])
      set["tech_"*cat]=cepdata.techs[cepdata.techs[:categ].==cat,:tech]
  end
  set["tech"]=cepdata.techs[:tech]
  set["impact"]=String.(names(cepdata.cap_costs))[2:end]
  set["account"]=["cap_fix","var"]
  if existing_infrastructure
    set["exist"]=["new","ex"]
  else
    set["exist"]=["new"]
  end
  #QUESTION How to integrate different secotors?
  set["sector"]=unique(cepdata.techs[:sector])
  #Different set: set["sector"]=unique(cepdata.techs[:sector]) .. CAP[node,tech,sector]
  #Or specific variables for each sector ELCAP, HEATCAP
  set["time_K"]=1:tsdata.K
  set["time_T"]=1:tsdata.T
  return set
end

"""
function setup_cep_opt_model_variables!(cep::CEPModel; set::Dict)
  Adding variables COST, CAP and GEN based on set
"""
function setup_cep_opt_model_variables!(cep::CEPModel;
                                     set::Dict
                                    )
  ##### Define the model #####
  ## VARIABLES ##
  # Cost
  push!(cep.info,"Variable COST[account, impact, tech]")
  @variable(cep.model, COST[account=set["account"],impact=set["impact"],tech=set["tech"]])
  # Capacity
  push!(cep.info,"Variable CAP[tech, exist, nodes] ≥ 0]")
  @variable(cep.model, CAP[tech=set["tech"],exist=set["exist"],node=set["nodes"]]>=0)
  # Generation #
  push!(cep.info,"Variable GEN[sector, tech, t, k, node]")
  @variable(cep.model, GEN[sector=set["sector"], tech=set["tech"], t=set["time_T"], k=set["time_K"], node=set["nodes"]])
  #TODO Include Slack into CEP
  #@variable(cep, SLACK[t=set["time_T"], k=set["time_K"]]>=0)
  return cep
end

"""
function setup_cep_opt_model_exist!(cep::CEPModel;nodes::DataFrame,set::Dict)
  fixing existing infrastructure to CAP[tech, 'ex', node]
"""
function setup_cep_opt_model_exist!(cep::CEPModel;
                                    nodes::DataFrame,
                                    set::Dict
                                    )
  ## ASSIGN VALUES ##
  # Assign the existing capacity from the nodes table
  push!(cep.info,"CAP[tech, 'ex', node] = existing infrastructure ∀ tech, node")
  @constraint(cep.model, [node=set["nodes"], tech=set["tech"]], cep.model[:CAP][tech,"ex",node]==findvalindf(nodes,:nodes,node,tech))
  return cep
end


"""
function setup_cep_opt_model_fossil!(cep::CEPModel; cap_costs::DataFrame, var_costs::DataFrame, fix_costs::DataFrame, ts::Dict, ts_dict::Dict, ts_weights::Array, set::Dict)
  add variable and fixed Costs and limit generation to installed capacity for fossil power plants
"""
function setup_cep_opt_model_fossil!(cep::CEPModel;
                                     cap_costs::DataFrame,
                                     var_costs::DataFrame,
                                     fix_costs::DataFrame,
                                     ts::Dict,
                                     ts_dict::Dict,
                                     ts_weights::Array,
                                     set::Dict
                                    )
  ## FOSSIL POWER PLANTS ##
    # Calculate Variable Costs
    push!(cep.info,"COST['var',impact,tech] = Δt ⋅ Σ_{t,k,node}GEN['el',t,k,node]⋅ ts_weights ⋅ var_costs[tech,impact] ∀ impact, tech_fossil")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_fossil"]], cep.model[:COST]["var",impact,tech]==sum(cep.model[:GEN]["el",tech,t,k,node]*ts_weights[k]*findvalindf(var_costs,:tech,tech,Symbol(impact)) for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
    # Calculate Fixed Costs
    push!(cep.info,"COST['cap_fix',impact,tech] = Σ_{node}CAP[tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_fossil")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_fossil"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node] for node=set["nodes"])*(findvalindf(cap_costs,:tech,tech,impact)+findvalindf(fix_costs,:tech,tech,impact)))
    # Limit the generation to the existing capacity
    push!(cep.info," 0 ≤ GEN['el',tech, t, k, node] ≤ Σ_{exist}CAP[tech,exist,node] ∀ node, tech_fossil, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_fossil"], t=set["time_T"], k=set["time_K"]], 0 <=cep.model[:GEN]["el",tech, t, k, node])
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_fossil"], t=set["time_T"], k=set["time_K"]],     cep.model[:GEN]["el",tech, t, k, node] <=sum(cep.model[:CAP][tech,exist,node] for exist=set["exist"]))
    return cep
end

"""
function setup_cep_opt_model_renewable!(cep::CEPModel; cap_costs::DataFrame, var_costs::DataFrame, fix_costs::DataFrame, ts::Dict, ts_dict::Dict, ts_weights::Array, set::Dict)
  add variable and fixed Costs and limit generation to installed capacity for renewable power plants
"""
function setup_cep_opt_model_renewable!(cep::CEPModel;
                                     cap_costs::DataFrame,
                                     var_costs::DataFrame,
                                     fix_costs::DataFrame,
                                     ts::Dict,
                                     ts_dict::Dict,
                                     ts_weights::Array,
                                     set::Dict
                                    )
  ## RENEWABLES ##

    # Calculate the variable Costs
    push!(cep.info," COST['var',impact,tech] = Δt ⋅ Σ_{t,k,node}GEN['el',t,k,node]⋅ ts_weights ⋅ var_costs[tech,impact] ∀ impact, tech_renewable")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_renewable"]], cep.model[:COST]["var",impact,tech]==sum(cep.model[:GEN]["el",tech,t,k,node]*ts_weights[k]*findvalindf(var_costs,:tech,tech,Symbol(impact)) for node=set["nodes"], t=set["time_T"], k=set["time_K"]))
    # Calculate the fixed Costs
    push!(cep.info," COST['cap_fix',impact,tech] = Σ_{node}cep[:CAP][tech,'new',node] ⋅ cap_costs[tech,impact] ∀ impact, tech_renewable")
    @constraint(cep.model, [impact=set["impact"], tech=set["tech_renewable"]], cep.model[:COST]["cap_fix",impact,tech]==sum(cep.model[:CAP][tech,"new",node] for node=set["nodes"])*(findvalindf(cap_costs,:tech,tech,impact)+findvalindf(fix_costs,:tech,tech,impact)))
    # Limit the Generation of the renewables to be positive and below the existing capacity
    push!(cep.info," 0 ≤ GEN['el',tech, t, k, node] ≤ Σ_{exist}CAP[tech,exist,node]*ts[tech-node,t,k] ∀ node, tech_renewable, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_renewable"], t=set["time_T"], k=set["time_K"]], 0 <=cep.model[:GEN]["el",tech, t, k, node])
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_renewable"], t=set["time_T"], k=set["time_K"]],     cep.model[:GEN]["el",tech,t,k,node] <=sum(cep.model[:CAP][tech,exist,node] for exist=set["exist"])*ts[ts_dict[tech]*"-"*node][t,k])
    return cep
end

"""
function setup_cep_opt_model_storage!(cep::CEPModel; set::Dict)
  missing rn
"""
function setup_cep_opt_model_storage!(cep::CEPModel;
                                     set::Dict)
  ## STORAGE ##

    # Fix Costs to 0
    push!(cep.info,"COST['var',impact,tech] = 0 ∀ impact, tech_storage")
    @constraint(cep.model, [account=set["account"], tech=set["tech_storage"], impact=set["impact"]], cep.model[:COST][account,impact,tech]==0)
    # Fix Generation to 0
    push!(cep.info,"GEN['el',tech, t, k, node] = 0 ∀ node, tech_storage, t, k")
    @constraint(cep.model, [node=set["nodes"], tech=set["tech_storage"], t=set["time_T"], k=set["time_K"]], cep.model[:GEN]["el",tech,t,k,node]==0)
    return cep
end

"""
function setup_cep_opt_model_demand!(cep::CEPModel; set::Dict, ts::Dict)
  Add demand which shall be matched by the generation (GEN)
"""
function setup_cep_opt_model_demand!(cep::CEPModel;
                                     set::Dict,
                                     ts::Dict
                                    )
  ## DEMAND ##
  # Force the demand to match the generation
  push!(cep.info,"Σ_{tech,node}GEN['el',tech,t,k,node] = Σ_{node}ts[el_demand-node,t,k] ∀ t,k")
  @constraint(cep.model, [t=set["time_T"], k=set["time_K"]], sum(cep.model[:GEN]["el",tech,t,k,node] for node=set["nodes"], tech=set["tech"]) == sum(ts["el_demand-"*node][t,k] for node=set["nodes"]))
  return cep
end

"""
function setup_cep_opt_model_emissions!(cep::CEPModel; set::Dict, co2limit ts::Dict)
  Add co2 emission constraint
"""
function setup_cep_opt_model_emissions!(cep::CEPModel;
                                        set::Dict,
                                        co2limit::Float64,
                                        ts::Dict
                                    )
  ## EMISSIONS ##
  # Limit the Emissions with co2limit if it exists
  push!(cep.info,"ΣCOST_{account}[account,'CO2',-tech-] ≤ co2limit*Σ_{node,t,k}ts[el_demand-node,t,k]")
  @constraint(cep.model, sum(cep.model[:COST][account,"CO2",tech] for account=set["account"], tech=set["tech"])<= co2limit*sum(sum(ts["el_demand-"*node]) for node=set["nodes"]))
  return cep
end

"""
function setup_cep_opt_model_objective!(cep::CEPModel; set::Dict)
  Calculate total system costs and set as objective
"""
function setup_cep_opt_model_objective!(cep::CEPModel;
                                     set::Dict
                                    )
  ## OBJECTIVE ##
  # Minimize the total €-Costs s.t. the Constraints introduced above
  push!(cep.info,"min Σ_{account,tech}COST[account,'USD',tech] st. obove")
  @objective(cep.model, Min, sum(cep.model[:COST][account,set["impact"][1],tech] for account=set["account"], tech=set["tech"]))
  return cep
end #functoin setup_cep_opt_model

"""
function solve_cep_opt_model(cep,co2limit)
solving the cep model and writing it's results and co2limit into an OptResult-Struct
"""
function solve_cep_opt_model(cep::CEPModel,
                            co2limit::Float64;
                            name::String="X"
                            )
  status=solve(cep.model)
  objective=getobjectivevalue(cep.model)
  var=Dict{String,OptVariable}()
  var["COST"]=OptVariable(getvalue(cep.model[:COST]),"operation")
  var["CAP"]=OptVariable(getvalue(cep.model[:CAP]),"decision")
  var["GEN"]=OptVariable(getvalue(cep.model[:GEN]),"decision")
  add_results=Dict()
  add_results["co2limit"]=co2limit
  currency=var["COST"].indexsets[2][1]
  @info("Solved Scenario $name:"*String(status)*" min COST[$currency]: $objective s.t. CO₂-Emissions per MWh ≤ $co2limit")
  return OptResult(status,objective,var,add_results), cep.info
end
"""
function run_cep_opt(tsdata::ClustInputData,cepdata::CEPData)

capacity expansion optimization problem: sets up the problem and runs the problem.
"""
function run_cep_opt(tsdata::ClustInputData,
                    cepdata::CEPData;
                    solver=CbcSolver(),
                    co2limit=Inf,
                    existing_infrastructure=false,
                    name::String="X"
                    )
  #@info("Setting Up CEP 🔌 ⛅")
  ##### Extract and prepare data #####
  #nodes: nodes x installed capacity of different tech
  #cap_costs   tech x impact[USD, CO2]
  #var_costs   tech x impact[USD, CO2]
  #techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
  nodes=cepdata.nodes
  cap_costs=cepdata.cap_costs
  var_costs=cepdata.var_costs
  fix_costs=cepdata.fix_costs
  techs=cepdata.techs
  ts=tsdata.data
  ts_dict=Dict{String,String}("wind"=>"wind","pv"=>"solar")
  ts_weights=tsdata.weights
  set=setup_cep_opt_sets(tsdata, cepdata; existing_infrastructure=existing_infrastructure)
  cep=CEPModel(Model(solver=solver),[name])
  cep=setup_cep_opt_model_variables!(cep;set=set)
  if existing_infrastructure
      cep=setup_cep_opt_model_exist!(cep;nodes=nodes,set=set)
  end
  if "tech_fossil" in keys(set)
    cep=setup_cep_opt_model_fossil!(cep; cap_costs=cap_costs, var_costs=var_costs, fix_costs=fix_costs, ts=ts, ts_dict=ts_dict, ts_weights=ts_weights, set=set)
  end
  if "tech_renewable" in keys(set)
    cep=setup_cep_opt_model_renewable!(cep; cap_costs=cap_costs, var_costs=var_costs, fix_costs=fix_costs, ts=ts, ts_dict=ts_dict, ts_weights=ts_weights, set=set)
  end
  if "tech_storage" in keys(set)
    cep=setup_cep_opt_model_storage!(cep; set=set)
  end
  if co2limit!=Inf
    cep=setup_cep_opt_model_emissions!(cep; set=set, co2limit=co2limit, ts=ts)
  end
  cep=setup_cep_opt_model_demand!(cep; set=set, ts=ts)
  cep=setup_cep_opt_model_objective!(cep;set=set)
  return solve_cep_opt_model(cep, co2limit; name=name)
end
"""
function run_battery_opt(data::ClustInputData)

operational battery storage optimization problem
runs every day seperately and adds results in the end
"""
function run_battery_opt(data::ClustInputData)
  prnt=false
  num_periods = data.K # number of periods, 1day, one week, etc.
  num_hours = data.T # hours per period (24 per day, 48 per 2days)
  el_price = data.data["el_price-$(data.region)"]
  weight = data.weights
  # time steps
  del_t = 1; # hour

  # example battery Southern California Edison
  P_battery = 100; # MW
  E_battery = 400; # MWh
  eff_Storage_in = 0.95;
  eff_Storage_out = 0.95;
  #Stor_init = 0.5;

  # optimization
  # Sets
  # time
  t_max = num_hours;

  E_in_arr = zeros(num_hours,num_periods)
  E_out_arr = zeros(num_hours,num_periods)
  stor = zeros(num_hours +1,num_periods)

  obj = zeros(num_periods);
  m= Model(solver=ClpSolver() )

  # hourly energy output
  @variable(m, E_out[t=1:t_max] >= 0) # kWh
  # hourly energy input
  @variable(m, E_in[t=1:t_max] >=# optimization problems
   0) # kWh
  # storage level
  @variable(m, Stor_lev[t=1:t_max+1] >= 0) # kWh

  @variable(m,0 <= Stor_init <= 1) # this as a variable ensures

  # maximum battery power
  for t=1:t_max
    @constraint(m, E_out[t] <= P_battery*del_t)
    @constraint(m, E_in[t] <= P_battery*del_t)
  end

  # maximum storage level
  for t=1:t_max+1
    @constraint(m, Stor_lev[t] <= E_battery)
  end

  # battery energy balance
  for t=1:t_max
    @constraint(m,Stor_lev[t+1] == Stor_lev[t] + eff_Storage_in*del_t*E_in[t]-(1/eff_Storage_out)*del_t*E_out[t])
  end

  # initial storage level
  @constraint(m,Stor_lev[1] == Stor_init*E_battery)
  @constraint(m,Stor_lev[t_max+1] >= Stor_lev[1])
  s=:Optimal
  for i =1:num_periods
    #objective
    @objective(m, Max, sum((E_out[t] - E_in[t])*el_price[t,i] for t=1:t_max) )
    status = solve(m)
    if status != :Optimal
      s=:NotSolved
    end
    if weight ==1
      obj[i] = getobjectivevalue(m)
    else
      obj[i] = getobjectivevalue(m) * weight[i]
    end
    E_in_arr[:,i] = getvalue(E_in)
    E_out_arr[:,i] = getvalue(E_out)
    stor[:,i] = getvalue(Stor_lev)
  end
  vars= Dict()
  vars["E_out"] = OptVariable(E_out_arr,"operation")
  vars["E_in"] = OptVariable(E_in_arr,"operation")
  vars["Stor_level"] = OptVariable(stor,"operation")
  res = OptResult(s,sum(obj),vars,Dict())
  return res
end # run_battery_opt()

 ###

"""
function run_gas_opt(data::ClustInputData)

operational gas turbine optimization problem
runs every day seperately and adds results in the end
"""
function run_gas_opt(data::ClustInputData)


  prnt=false
  num_periods = data.K # number of periods, 1day, one week, etc.
  num_hours = data.T # hours per period (24 per day, 48 per 2days)
  el_price = data.data["el_price"]
  weight = data.weights
  # time steps
  del_t = 1; # hour


  # example gas turbine
  P_gt = 100; # MW
  eta_t = 0.6; # 40 % efficiency
  if data.region == "GER"
    gas_price = 24.65  # EUR/MWh    7.6$/GJ = 27.36 $/MWh=24.65EUR/MWh with 2015 conversion rate
  elseif data.region == "CA"
    gas_price  = 14.40   # $/MWh        4$/GJ = 14.4 $/MWh
  end

  # optimization
  # Sets
  # time,
  t_max = num_hours;

  E_out_arr = zeros(num_hours,num_periods)

  obj = zeros(num_periods);
  m= Model(solver=ClpSolver() )

  # hourly energy output
  @variable(m, 0 <= E_out[t=1:t_max] <= P_gt) # MWh

  s=:Optimal
  for i =1:num_periods
    #objective
    @objective(m, Max, sum(E_out[t]*el_price[t,i] - 1/eta_t*E_out[t]*gas_price for t=1:t_max) )
    status = solve(m)
    if status != :Optimal
      s=:NotSolved
    end

    if weight ==1
      obj[i] = getobjectivevalue(m)
    else
      obj[i] = getobjectivevalue(m) * weight[i]
    end
    E_out_arr[:,i] = getvalue(E_out)
  end

  op_vars= Dict()
  op_vars["E_out"] = E_out_arr
  res = OptResult(s,sum(obj),Dict(),op_vars,Dict())
  return res
end # run_gas_opt()


"""
function run_opt(problem_type,el_price,weight=1,country="",prnt=false)

Wrapper function for type of optimization problem
"""
function run_opt(problem_type::String,
                 tsdata::ClustInputData;
                 first_stage_vars::Dict=Dict(),
                 kwargs...)
  if findall(problem_type.==["battery","gas","cep"])==[]
    @error("optimization problem_type ",problem_type," does not exist")
  else
    fun_name = Symbol("run_"*problem_type*"_opt")
    @eval $fun_name($tsdata;$kwargs...)
  end
end # run_opt
