# This file exemplifies the workflow from data input to optimization result generation

using ClustForOpt
using Clp
#using ClustForOpt_priv
#using Gurobi

# load data
ts_input_data, = load_timeseries_data("CEP", "GER_18";K=365, T=24) #CEP

cep_input_data_GER=load_cep_data("GER_18")

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

# select solver
optimizer=Clp.Optimizer

# optimization
opt_res = run_opt(ts_clust_extr,cep_input_data_GER,optimizer;co2_limit=1000.0)
