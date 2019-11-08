using TimeSeriesClustering

ts_input_data = load_timeseries_data(:CEP_GER1)

# when using kmedoids-exact, one needs to supply the optimizer. Make sure the optimizer is added through Pkg.add()

using Gurobi
optimizer = Gurobi.Optimizer
out = run_clust(ts_input_data;method="poncelet",n_init=5,ponc_optimizer=optimizer)
