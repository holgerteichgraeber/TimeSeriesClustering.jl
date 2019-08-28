Optimization
============
The main purpose of this package is to provide a process and type system (structs) that can be easily integrated with optimization problems. TimeSeriesClustering allows for the data to be processed in one single type, regardless of the dimensionality of the input data. This allows to quickly evaluate different temporal resolutions on a given optimization model.

The most important fields of the data struct are
```@setup opt
using TimeSeriesClustering
ts_input_data = load_timeseries_data(:CEP_GER1)
```
```@repl opt
ts_clust_data.data # the clustered data
ts_clust_data.K # number of periods
ts_clust_data.T # number of time steps per period
```
`K` and `T` can be directly integrated in the creation of the sets that define the temporal resolution of the formulation of the optimization problem.

The package [CapacityExpansion](https://github.com/YoungFaithful/CapacityExpansion.jl) provides a generation and transmission capacity expansion problem that can utilize the wind, solar, and demand data from the `:CEP_GER1` and `:CEP_GER18` examples and uses the data types introduced in TimeSeriesClustering. Please refer to the documentation of the CapacityExpansion package for how to use it.
