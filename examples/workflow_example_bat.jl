#TODO OLD rewrite This file exemplifies the workflow from data input to optimization result generation

using ClustForOpt
#using ClustForOpt_priv
#using Gurobi

# load data
ts_input_data, = load_timeseries_data("DAM", "GER";K=365, T=24) #DAM

 # run clustering
using Gurobi
clust_res_ar = []
optimizer=Gurobi.Optimizer
for i=1:2
  push!(clust_res_ar, run_clust(ts_input_data;method="kmedoids_exact",representation="medoid",iterations=5,n_init=1,gurobi_opt=optimizer)) # default k-means
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
