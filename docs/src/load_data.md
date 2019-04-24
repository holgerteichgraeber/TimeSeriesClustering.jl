# Load Data
## Load Timeseries Data
`load_timeseries_data()` loads the data for a given `application` and `region`.
Possible applications are
- `DAM`: Day ahead market price data

Possible regions are:
- `GER`: Germany
- `CA`: California

The optional input parameters to `load_timeseries_data()` are the number of periods `K` and the number of time steps per period `T`. By default, they are chosen such that they result in daily time slices.

```@docs
load_timeseries_data
```
### Example loading timeseries data
```@example
using ClustForOpt
# laod ts-input-data
ts_input_data = load_timeseries_data(normpath(joinpath(@__DIR__,"..","..","data","TS_GER_1")); T=24, years=[2016])
using Plots
plot(ts_input_data.data["solar-germany"], legend=false, linestyle=:dot, xlabel="Time [h]", ylabel="Solar availability factor [%]")
savefig("load_timeseries_data.svg")
```
![Plot](load_timeseries_data.svg)
