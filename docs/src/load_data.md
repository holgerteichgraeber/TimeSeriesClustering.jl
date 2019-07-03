Load Data
=========
Here, we describe how to load time-series data into the `ClustData` format for use in ClustForOpt, and we describe how data is stored in `ClustData`.
Data can be loaded from example data sets provided by us, or you can load your own data.

## Load example data from ClustForOpt
The example data can be loaded using the following function.
```@docs
load_timeseries_data(::Symbol)
```
In the following example, we use the function to load the hourly wind, solar, demand data for Germany for 1 node, and the other data can be loaded similarly. Note that more years are available for the two CEP data sets. The data can be found in the [data](https://github.com/holgerteichgraeber/ClustForOpt.jl/tree/master/data) folder.
```@setup load_data
using ClustForOpt
```
```@repl load_data
ts_input_data = load_timeseries_data(:CEP_GER1)
```

## Load your own data
You can also load your own data. Use the `load_timeseries_data` function and specify the path where the data is located at (either a folder or the filename).
```@docs
load_timeseries_data(::String)
```
The data in your `.csv` file should be in the format Timestamp-Year-ColumnName as specified above. The files in [the single node system GER1](https://github.com/holgerteichgraeber/ClustForOpt.jl/tree/master/data/TS_GER_1) and [multi-node system GER18](https://github.com/holgerteichgraeber/ClustForOpt.jl/tree/master/data/TS_GER_18) give a good overview of how the data should be structured.

The path can be relative or absolute as in the following example
```@repl load_data
ts_input_data = load_timeseries_data(normpath(joinpath(@__DIR__,"..","..","data","TS_GER_1"))) # relative path from the documentation file to the data folder
ts_input_data = load_timeseries_data("/home/username/yourpathtofolder") # absolute path on Linux/Mac
ts_input_data = load_timeseries_data("C:\\Users\\Username\\yourpathtofolder") # absolute path on Windows
```

## ClustData struct
The `ClustData` struct is at the core of ClustForOpt. It contains the temporal input data, and also relevant information that can be easily used in the formulation of the optimization problem.
```@docs
ClustData
```
Note that `K` and `T` can be used to construct sets that define the temporal structure of the optimization problem, and that `weights` can be used to weight the representative periods in the objective function of the optimization problem.
`k_ids` can be used to implement seasonal storage formulations for long-term energy systems optimization problems. `delta_t` can be used to implement within-period segmentation. 

## Example data
This shows the solar data as an example.
```@example
using ClustForOpt
ts_input_data = load_timeseries_data(:CEP_GER1; T=24, years=[2016])
using Plots
plot(ts_input_data.data["solar-germany"], legend=false, linestyle=:dot, xlabel="Time [h]", ylabel="Solar availability factor [%]")
savefig("load_timeseries_data.svg")
```
![Plot](load_timeseries_data.svg)
