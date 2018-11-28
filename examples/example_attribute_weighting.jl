using ClustForOpt

ts_input_data,~ = load_timeseries_data("CEP", "GER_1";K=365, T=24) #CEP

Scenarios=Dict{String,Scenario}()

attribute_weights=Dict("solar"=>1, "wind"=>2, "el_demand"=>3)

Scenarios["kmeans-4-attributed"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=4,attribute_weights=attribute_weights)) # default k-means
