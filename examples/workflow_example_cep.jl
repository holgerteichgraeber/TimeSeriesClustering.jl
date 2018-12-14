# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.

include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))

# load data

ts_input_data, = load_timeseries_data("CEP", "GER_1";K=365, T=24) #CEP

cep_data = load_cep_data("GER_1")

 # run clustering
ts_clust_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=1000,n_clust=20) # default k-means

ts_full_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=1,n_clust=365) # default k-means

 # optimization

design_result = run_opt(ts_clust_data.best_results,cep_data;solver=GurobiSolver(),co2_limit=1250)

operation_result = run_opt(ts_full_data.best_results,cep_data,design_result.opt_config;solver=GurobiSolver(),co2_limit=1250,prev_dc_variables=get_cep_design_variables(design_result))

plot(get_cep_variable_value(operation_result.variables["SLACK"],[1,:,:,1]),legend=false)
