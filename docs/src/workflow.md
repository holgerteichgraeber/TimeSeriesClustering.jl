## Workflow

Generally, the workflow requires three steps:
- load data
- clustering
- optimization

## Example Workflow
```julia
using ClustForOpt

# load data (electricity price day ahead market)
ts_input_data, = load_timeseries_data("DAM", "GER";K=365, T=24) #DAM

# run standard kmeans clustering algorithm to cluster into 5 representative periods, with 1000 initial starting points
clust_res = run_clust(ts_input_data;method="kmeans",representation="centroid",n_clust=5,n_init=1000)

# battery operations optimization on the clustered data
opt_res = run_opt(clust_res)
```
