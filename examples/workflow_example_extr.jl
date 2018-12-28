# This file exemplifies the workflow from data input to optimization result generation

include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))
#using ClustForOpt_priv
using Gurobi
env = Gurobi.Env() # reusing the same gurobi environment for multiple solves
# select solver
solver=GurobiSolver(env,OutputFlag=0)

# load data
state="TX_1" # or "GER_18" or "GER_1" or "CA_1" or "TX_1"
ts_input_data, = load_timeseries_data("CEP", state;K=365, T=24) #CEP

cep_input_data_GER=load_cep_data(state)

 # define simple extreme days of interest
ev1 = SimpleExtremeValueDescr("wind-node61","max","absolute") # TODO: min?
ev2 = SimpleExtremeValueDescr("solar-node61","min","integral") 
ev3 = SimpleExtremeValueDescr("el_demand-node61","max","absolute")
# ev1 = SimpleExtremeValueDescr("wind-dena42","max","absolute")
# ev2 = SimpleExtremeValueDescr("solar-dena42","min","integral")
# ev3 = SimpleExtremeValueDescr("el_demand-dena21","max","absolute")
 ev = [ev1, ev2, ev3]
 # simple extreme day selection
 #ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev;rep_mod_method="feasibility")

 # run clustering
#ts_clust_res = run_clust(ts_input_data_mod;method="kmeans",representation="centroid",n_init=10,n_clust=5) # default k-means

# representation modification
#ts_clust_extr = representation_modification(extr_vals,ts_clust_res.best_results)

#without simple extreme days
 ts_clust_res = run_clust_extr(ts_input_data,cep_input_data_GER;rep_mod_method="feasibility",method="kmeans",representation="centroid",n_init=10,n_clust=5,solver=solver,storage="intra",extreme_event_selection_method="slack",slack_cost=1e4,print_flag=false) 
 #ts_clust_res = run_clust_extr(ts_input_data,cep_input_data_GER;rep_mod_method="feasibility",method="kmeans",representation="centroid",n_init=10,n_clust=5,solver=solver,storage="intra",extreme_event_selection_method="feasibility",print_flag=false) 

#with simple extreme days
# ts_clust_res = run_clust_extr(ts_input_data,cep_input_data_GER,ev;rep_mod_method="feasibility",method="kmeans",representation="centroid",n_init=10,n_clust=5,solver=solver,storage="intra",print_flag=false) 

# optimization
#opt_res = run_opt(ts_clust_res.best_results,cep_input_data_GER;solver=GurobiSolver(),co2_limit=1000.0)

#TODO: write functions to get generation, capacity etc.

# TODO: write plotting functions in other package


