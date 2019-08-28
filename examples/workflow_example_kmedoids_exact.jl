using TimeSeriesClustering

ts_input_data = load_timeseries_data(:CEP_GER1)

# when using kmedoids-exact, one needs to supply the optimizer. Make sure the optimizer is added through Pkg.add()

using Cbc
optimizer = Cbc.Optimizer
out = run_clust(ts_input_data;method="kmedoids_exact",representation="medoid",n_clust=ts_input_data.5,n_init=1,kmexact_optimizer=optimizer)


using Gurobi
optimizer = Gurobi.Optimizer
out = run_clust(ts_input_data;method="kmedoids_exact",representation="medoid",n_init=1,kmexact_optimizer=optimizer)
