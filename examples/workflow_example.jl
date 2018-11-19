# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.
using ClustForOpt_priv
using Gurobi

# load data
ts_input_data,~ = load_timeseries_data("CEP", "GER";K=365, T=24) #CEP

cep_input_data_GER=load_cep_data("GER";interest_rate=0.05,max_years_of_payment=20)

 # run clustering
ts_clust_res = run_clust(ts_input_data;n_init=10,n_clust_ar=collect(1:9)) # default k-means

 # optimization
opt_res = run_cep_opt(ts_clust_res.best_results[5],cep_input_data_GER;solver=GurobiSolver(),co2limit=1e9)
