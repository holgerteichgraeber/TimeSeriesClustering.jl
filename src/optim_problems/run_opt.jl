#TODO Rewrite battery problem / update to modern JuMP, give optimizer as additional argument
"""
    run_battery_opt(data::ClustData; optimizer=nothing)

operational battery storage optimization problem
runs every day seperately and adds results in the end

Requires a linear optimizer (e.g., `using Clp; run_battery_opt(data; optimizer=Clp.Optimizer)`).
"""
function run_battery_opt(data::ClustData; optimizer=nothing)
  optimizer === nothing && error("Please provide an optimizer, e.g. Clp.Optimizer")
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

  # optimization
  # Sets
  # time
  t_max = num_hours;

  E_in_arr = zeros(num_hours,num_periods)
  E_out_arr = zeros(num_hours,num_periods)
  stor = zeros(num_hours +1,num_periods)

  obj = zeros(num_periods);
  m = Model(optimizer)

  # hourly energy output
  @variable(m, E_out[t=1:t_max] >= 0) # kWh
  # hourly energy input
  @variable(m, E_in[t=1:t_max] >= 0) # kWh
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
    JuMP.optimize!(m)
    status = termination_status(m)
    if status != MOI.OPTIMAL
      s=:NotSolved
    end
    if weight ==1
      obj[i] = JuMP.objective_value(m)
    else
      obj[i] = JuMP.objective_value(m) * weight[i]
    end
    E_in_arr[:,i] = JuMP.value.(E_in)
    E_out_arr[:,i] = JuMP.value.(E_out)
    stor[:,i] = JuMP.value.(Stor_lev)
  end
  results = Dict{String,Any}()
  results["status"] = s
  results["objective"] = sum(obj)
  results["E_out"] = E_out_arr
  results["E_in"] = E_in_arr
  results["Stor_level"] = stor
  return results
end # run_battery_opt()

 ###

#TODO update gas turbine problem, update to modern JuMP
"""
    run_gas_opt(data::ClustData; optimizer=nothing)

operational gas turbine optimization problem
runs every day seperately and adds results in the end

Requires a linear optimizer (e.g., `using Clp; run_gas_opt(data; optimizer=Clp.Optimizer)`).
"""
function run_gas_opt(data::ClustData; optimizer=nothing)
  optimizer === nothing && error("Please provide an optimizer, e.g. Clp.Optimizer")

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
  m = Model(optimizer)

  # hourly energy output
  @variable(m, 0 <= E_out[t=1:t_max] <= P_gt) # MWh

  s=:Optimal
  for i =1:num_periods
    #objective
    @objective(m, Max, sum(E_out[t]*el_price[t,i] - 1/eta_t*E_out[t]*gas_price for t=1:t_max) )
    JuMP.optimize!(m)
    status = termination_status(m)
    if status != MOI.OPTIMAL
      s=:NotSolved
    end

    if weight ==1
      obj[i] = JuMP.objective_value(m)
    else
      obj[i] = JuMP.objective_value(m) * weight[i]
    end
    E_out_arr[:,i] = JuMP.value.(E_out)
  end

  results = Dict{String,Any}()
  results["status"] = s
  results["objective"] = sum(obj)
  results["E_out"] = E_out_arr
  return results
end # run_gas_opt()
