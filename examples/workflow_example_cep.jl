# This file exemplifies the workflow from data input to optimization result generation
using ClustForOpt
using Clp
## LOAD DATA ##
state="GER_1" # or "GER_18" or "CA_1" or "TX_1"
years=[2015, 2016] #2016 works for GER_1 and CA_1, GER_1 can also be used with 2006 to 2016 and, GER_18 is 2015 TX_1 is 2008
# laod ts-data
ts_input_data = load_timeseries_data("CEP", state; T=24, years=years) #CEP
# load cep-data
cep_data = load_cep_data_provided(state)

## CLUSTERING ##
# run aggregation with kmeans
ts_clust_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=100,n_clust=5) # default k-means make sure that n_init is high enough otherwise the results could be crap and drive you crazy

# run aggregation with kmeans and have periods segmented
ts_seg_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=1000,n_clust=5, n_seg=4) # default k-means make sure that n_init is high enough otherwise the results could be crap and drive you crazy

# run no aggregation just get ts_full_data
ts_full_data = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=1,n_clust=365) # default k-means
