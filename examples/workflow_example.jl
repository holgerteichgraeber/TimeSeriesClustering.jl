# This file exemplifies the workflow from data input to optimization result generation
using ClustForOpt_priv

# load data
input_data,~ = load_input_data("DAM","GER")
  
 # run clustering 
clust_res = run_clust(input_data;n_init=10,n_clust_ar=collect(1:9)) # default k-means 

 # optimization

opt_res = run_opt("battery",clust_res.best_results[5])
 #opt_res = run_opt("gas_turbine",clust_res.best_results[5])

 ###
 # run optimization for all k=1:9
opt_res_all = []
obj=[]
for i=1:9
  push!(opt_res_all,run_opt("battery", clust_res.best_results[i]))
  push!(obj,opt_res_all[i].obj)
end
 # run reference case
opt_res_full = run_opt("battery",input_data)
 #using PyPlot
 # figure()
 # plot(obj/opt_res_full.obj)
