Representative Periods
======================

The following describes how to find representative periods out of the full time-series input data. This includes both clustering and extreme period selection.

## Clustering
The function `run_clust()` takes the `data` and gives a `ClustResult` struct with the clustered data as the output.
```@docs
run_clust(::ClustData)
```

The following examples show some use cases of `run_clust`.
```@setup clust
using ClustForOpt
ts_input_data=load_timeseries_data(:CEP_GER1)
```
```@repl clust
clust_res = run_clust(ts_input_data) # uses the default values, so this is a k-means clustering algorithm with centroid representation that finds 5 clusters.
clust_res = run_clust(ts_input_data;method="kmedoids",representation="medoid",n_clust=10) #kmedoids clustering that finds 10 clusters
clust_res = run_clust(ts_input_data;method="hierarchical",representation=medoid,n_init=1) # Hierarchical clustering with medoid representation.
```
The resulting struct contains the data, but also cost and configuration information.
```@repl clust
ts_clust_data = clust_res.clust_data
clust_cost = clust_res.cost
clust_config = clust_res.config
```
The `ts_clust_data` is a `ClustData` data struct, this time with clustered data (i.e. less representative periods).

Shape-based clustering methods are supported in an older version of ClustForOpt: For use of DTW barycenter averaging (DBA) and k-shape clustering on single-attribute data (e.g. electricity prices), please use [v0.1](https://github.com/holgerteichgraeber/ClustForOpt.jl/tree/v0.1).

## Extreme period selection
Additionally to clustering the input data, extremes of the data may be relevant to the optimization problem. Therefore, we provide methods for extreme value identification, and to include them in the set of representative periods.

The methods can be used as follows.
```@example
using ClustForOpt
ts_input_data = load_timeseries_data(:CEP_GER1)
 # define simple extreme days of interest
 ev1 = SimpleExtremeValueDescr("wind-germany","min","absolute")
 ev2 = SimpleExtremeValueDescr("solar-germany","min","integral")
 ev3 = SimpleExtremeValueDescr("el_demand-germany","max","absolute")
 ev = [ev1, ev2, ev3]
 # simple extreme day selection
 ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev;rep_mod_method="feasibility")

 # run clustering
ts_clust_res = run_clust(ts_input_data_mod;method="kmeans",representation="centroid",n_init=100,n_clust=5) # default k-means

# representation modification
ts_clust_extr = representation_modification(extr_vals,ts_clust_res.clust_data)
```
The resulting `ts_clust_extr` contains both the clustered periods and the extreme periods.

The extreme periods are first defined by their characteristics by use of `SimpleExtremeValueDescr`. The struct has the following options:
```@docs
SimpleExtremeValueDescr(::String,::String,::String)
```

Then, they are selected based on the function `simple_extr_val_sel`:
```@docs
simple_extr_val_sel(::ClustData, ::Array{SimpleExtremeValueDescr,1})
```

## ClustResult struct
The output of `run_clust` function is a `ClustResult` struct with the following fields.
```@docs
ClustResult
```

If `run_clust` is run with the option `get_all_clust_results=true`, the output is the struct `ClustResultAll`, which contains all locally converged solutions.
```@docs
ClustResultAll
```

## Example running clustering
In this example, the wind, solar, and demand data from Germany for 2016 are clustered to 5 representative periods, and the solar data is shown in the plot.
```@example
using ClustForOpt
ts_input_data = load_timeseries_data(:CEP_GER1; T=24, years=[2016])
ts_clust_data = run_clust(ts_input_data;n_clust=5).clust_data
using Plots
plot(ts_clust_data.data["solar-germany"], legend=false, linestyle=:solid, width=3, xlabel="Time [h]", ylabel="Solar availability factor [%]")
savefig("clust.svg")
```
![Plot](clust.svg)
