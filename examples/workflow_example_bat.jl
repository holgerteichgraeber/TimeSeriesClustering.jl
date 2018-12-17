# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.

include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))
#using ClustForOpt_priv
#using Gurobi

# load data
ts_input_data, = load_timeseries_data("DAM", "GER";K=365, T=24) #DAM

 # run clustering
using Gurobi
env = Gurobi.Env()
clust_res_ar = []
for i=1:2
  push!(clust_res_ar, run_clust(ts_input_data;method="kmedoids_exact",representation="medoid",iterations=5,n_init=1,gurobi_env=env)) # default k-means
end

 # optimization

opt_res = run_opt("battery",clust_res_ar[2].best_results)
 #opt_res = run_opt("gas_turbine",clust_res.best_results[5])

 ###
 # run optimization for all k=1:9
opt_res_all = []
obj=[]
for i=1:2
  push!(opt_res_all,run_opt("battery", clust_res_ar[i].best_results))
  push!(obj,opt_res_all[i].obj)
end
 # run reference case
opt_res_full = run_opt("battery",ts_input_data)
 #using PyPlot
 # figure()
 # plot(obj/opt_res_full.obj)
