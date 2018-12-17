# This file exemplifies the workflow from data input to optimization result generation

include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))
using Plots

## LOAD DATA ##
state="GER_1" # or "GER_18" or "CA_1" or "TX_1"
# laod ts-data
ts_input_data, = load_timeseries_data("CEP", state; K=365, T=24) #CEP
# load cep-data
cep_data = load_cep_data(state)

## CLUSTERING ##
# run aggregation with kmeans
ts_clust_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=5,n_clust=5) # default k-means make sure that n_init is high enough otherwise the results could be crap and drive you crazy
## OPTIMIZATION EXAMPLES##
# select solver
solver=GurobiSolver(OutputFlag=0)

# Create a Scenario of the clustered data and the corresponding OptResult
cep = Scenario("co2",ts_clust_data, run_opt(ts_clust_data.best_results,cep_data;solver=solver,descriptor="co2",co2_limit=1000)) #generally values between 1250 and 10 are interesting

# use the get variable set in order to get the labels: indicate the varible as "CAP" and the set-number as 1 to recieve this sets values
labels=get_cep_variable_set(cep,"CAP",1)
# use the get variable value function to recieve the values of CAP[:,:,1]
data=get_cep_variable_value(cep,"CAP",[:,:,1])
# use the data provided for a simple bar-plot without a legend
bar(data,title="Cap", xticks=(1:length(labels),labels),legend=false)
