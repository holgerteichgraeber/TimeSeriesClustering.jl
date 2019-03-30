using ClustForOpt

ts_input_data = load_timeseries_data(normpath(joinpath(dirname(@__FILE__),"TS_GER_1")); T=24, years=[2016])

attribute_weights=Dict("solar"=>1.0, "wind"=>2.0, "el_demand"=>3.0)

clust_res=run_clust(ts_input_data;n_init=10,n_clust=4,attribute_weights=attribute_weights) # default k-means
