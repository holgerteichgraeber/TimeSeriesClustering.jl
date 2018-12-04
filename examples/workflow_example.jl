# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.

include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))
#using ClustForOpt_priv
#using Gurobi

# load data
ts_input_data,~ = load_timeseries_data("CEP", "GER_1";K=365, T=24) #CEP

cep_input_data_GER=load_cep_data("GER_1")

 # run clustering
ts_clust_res = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=10000,n_clust=100) # default k-means

 # optimization
opt_res = run_cep_opt(ts_clust_res.best_results,cep_input_data_GER;solver=GurobiSolver(),co2limit=750.0)
