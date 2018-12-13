# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.

include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))

# load data

ts_input_data, = load_timeseries_data("CEP", "GER_18";K=365, T=24) #CEP

cep_data=load_cep_data("GER_18")

 # run clustering
ts_clust_res = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=1,n_clust=3) # default k-means

 # optimization

model = run_opt(ts_clust_res.best_results,cep_data;solver=GurobiSolver(), intrastorage=true, transmission=true, co2_limit=250)
