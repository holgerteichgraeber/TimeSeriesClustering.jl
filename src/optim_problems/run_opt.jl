"""
function run_opt_cep()

capacity expansion optimization problem: sets up the problem and runs the problem.
"""
function run_opt(ts_data::ClustData,
                    opt_data::OptDataCEP,
                    opt_config::Dict{String,Any};
                    solver::Any=CbcSolver()
                    )
  cep=setup_opt_cep_basic(ts_data, opt_data, opt_config, solver)
  setup_opt_cep_variables!(cep, ts_data, opt_data)
  if opt_config["existing_infrastructure"]
      setup_opt_cep_existing_infrastructure!(cep;nodes=nodes,set=set)
  end
  setup_opt_cep_generation_el!(cep, ts_data, opt_data)
  if opt_config["storage"]
    setup_opt_cep_storage!(cep, ts_data, opt_data)
  end
  if opt_config["co2_limit"]!=Inf
    setup_opt_cep_co2_limit!(cep, ts_data, opt_data; co2_limit=opt_config["co2_limit"])
  end
  setup_opt_cep_demand!(cep, ts_data, opt_data)
  setup_opt_cep_objective!(cep, ts_data, opt_data)
  return solve_opt_cep(cep, ts_data, opt_data, opt_config)
end


"""
function run_opt(problem_type,el_price,weight=1,country="",prnt=false)

Wrapper function for type of optimization problem for the CEP-Problem (NOTE: identifier is the type of opt_data - in this case OptDataCEP - so identification as CEP problem)
"""
function run_opt(ts_data::ClustData,
                 opt_data::OptDataCEP;
                 solver::Any=CbcSolver(),
                 descriptor::String="",
                 first_stage_vars::Dict{String,OptVariable}=Dict{String,OptVariable}(),
                 co2_limit::Number=Inf,
                 existing_infrastructure::Bool=false,
                 storage::Bool=false)
  #TODO first_stage_vars
  opt_config=set_opt_config_cep(opt_data; descriptor=descriptor, first_stage_vars=first_stage_vars, co2_limit=co2_limit, existing_infrastructure=existing_infrastructure, storage=storage)
  run_opt(ts_data,opt_data,opt_config;solver=solver)
end # run_opt

#TODO Rewrite battery problem
"""
function run_battery_opt(data::ClustData)

operational battery storage optimization problem
runs every day seperately and adds results in the end
"""
function run_battery_opt(data::ClustData)
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
function run_gas_opt(data::ClustData)

operational gas turbine optimization problem
runs every day seperately and adds results in the end
"""
function run_gas_opt(data::ClustData)


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
