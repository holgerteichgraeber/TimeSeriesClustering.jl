Quick Start Guide
=================

This quick start guide introduces the main concepts of using TimeSeriesClustering. For more detail on the different functionalities that TimeSeriesClustering provides, please refer to the subsequent chapters of the documentation or the examples in the [examples](https://github.com/holgerteichgraeber/TimeSeriesClustering.jl/tree/master/examples) folder, specifically [workflow_introduction.jl](https://github.com/holgerteichgraeber/TimeSeriesClustering.jl/blob/master/examples/workflow_introduction.jl).

Generally, the workflow consists of three steps:
- load data
- find representative periods (clustering + extreme period selection)
- optimization

## Example Workflow
After TimeSeriesClustering is installed, you can use it by saying:
```@repl workflow
using TimeSeriesClustering
```

The first step is to load the data. The following example loads hourly wind, solar, and demand data for Germany (1 region) for one year.
```@repl workflow
ts_input_data = load_timeseries_data(:CEP_GER1)
```
The output `ts_input_data` is a `ClustData` data struct that contains the data and additional information about the data.
```@repl workflow
ts_input_data.data # a dictionary with the data.
ts_input_data.data["wind-germany"] # the wind data (choose solar, el_demand as other options in this example)
ts_input_data.K # number of periods
```

The second step is to cluster the data into representative periods. Here, we use k-means clustering and get 5 representative periods.
```@repl workflow
clust_res = run_clust(ts_input_data;method="kmeans",n_clust=5)
ts_clust_data = clust_res.clust_data
```
The `ts_clust_data` is a `ClustData` data struct, this time with clustered data (i.e. less representative periods).
```@repl workflow
ts_clust_data.data # the clustered data
ts_clust_data.data["wind-germany"] # the wind data. Note the dimensions compared to ts_input_data
ts_clust_data.K # number of periods
```

The clustered input data can be used as input to an optimization problem.
The optimization problem formulated in the package [CapacityExpansion](https://github.com/YoungFaithful/CapacityExpansion.jl) can be used with the data clustered in this example.
