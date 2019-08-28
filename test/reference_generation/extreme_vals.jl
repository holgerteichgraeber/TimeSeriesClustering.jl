# no need to run this to generate any jld2, but was used to get extreme indices

using TimeSeriesClustering

reference_results = Dict{String,Any}()

ts_input_data = load_timeseries_data(:CEP_GER18)

ev1 = SimpleExtremeValueDescr("wind-dena42","max","absolute")
ev2 = SimpleExtremeValueDescr("solar-dena42","min","integral")
ev3 = SimpleExtremeValueDescr("el_demand-dena21","max","integral")
ev4 = SimpleExtremeValueDescr("el_demand-dena21","min","absolute")
ev = [ev1, ev2, ev3]


ts_input_data_mod,extr_vals1,extr_idcs = simple_extr_val_sel(ts_input_data,ev1;rep_mod_method="feasibility")
println(extr_idcs)
ts_input_data_mod,extr_vals2,extr_idcs = simple_extr_val_sel(ts_input_data,ev2;rep_mod_method="feasibility")
println(extr_idcs)
ts_input_data_mod,extr_vals3,extr_idcs = simple_extr_val_sel(ts_input_data,ev3;rep_mod_method="feasibility")
println(extr_idcs)
ts_input_data_mod,extr_vals4,extr_idcs = simple_extr_val_sel(ts_input_data,ev4;rep_mod_method="feasibility")
println(extr_idcs)

#@save normpath(joinpath(dirname(@__FILE__),"extreme_vals.jld2")) reference_results
