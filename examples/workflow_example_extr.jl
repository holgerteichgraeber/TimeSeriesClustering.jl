# This file exemplifies the workflow from data input to optimization result generation

using ClustForOpt

# load data
data_path=normpath(joinpath(dirname(@__FILE__),"..","data","TS_GER_18"))
ts_input_data = load_timeseries_data(data_path; T=24, years=[2015])

 # define simple extreme days of interest
 ev1 = SimpleExtremeValueDescr("wind-dena42","max","absolute")
 ev2 = SimpleExtremeValueDescr("solar-dena42","min","integral")
 ev3 = SimpleExtremeValueDescr("el_demand-dena21","max","absolute")
 ev = [ev1, ev2, ev3]
 # simple extreme day selection
 ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev;rep_mod_method="feasibility")

 # run clustering
ts_clust_res = run_clust(ts_input_data_mod;method="kmeans",representation="centroid",n_init=10,n_clust=5) # default k-means

# representation modification
ts_clust_extr = representation_modification(extr_vals,ts_clust_res.best_results)
