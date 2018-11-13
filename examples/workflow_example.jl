# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.
include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv.jl")))

# load data
input_data,~ = load_timeseries_data("DAM", "GER")

input_data,~ = load_timeseries_data("CEP", "GER";K=365, T=24)
GER=load_cep_data("GER")

 # run clustering
clust_res = run_clust(input_data;n_init=10,n_clust_ar=collect(1:9)) # default k-means

 # optimization

opt_res = run_opt("battery",clust_res.best_results[5])
opt_res = run_opt("cep",clust_res.best_results[5])
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
