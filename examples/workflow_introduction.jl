# To use this package
using ClustForOpt

#########################
#= Load Time Series Data
#########################
How to load data provided with the package:
The data is for a Capacity Expansion Problem "CEP"
and for the single node representation of Germany "GER_1"
The original timeseries has 8760 entries (one for each hour of the year)
It should be cut into K=365 periods (365 days) with T=24 timesteps per period (24h per day) =#
ts_input_data, = load_timeseries_data("CEP", "GER_1"; K=365, T=24)

#= ClustData
How the struct is setup:
    ClustData{region::String,K::Int,T::Int,data::Dict{String,Array},weights::Array{Float64},mean::Dict{String,Array},sdv::Dict{String,Array}} <: TSData
-region: specifies region data belongs to
-K: number of periods
-T: time steps per period
-data: Data in form of a dictionary for each attribute `"[file name]-[column name]"`
-weights: this is the absolute weight. E.g. for a year of 365 days, sum(weights)=365
-mean: The shift of the mean as a dictionary for each attribute
-sdv: Standard deviation as a dictionary for each attribute

How to access a struct:
    [object].[fieldname]                                                      =#
number_of_periods=ts_input_data.K
# How to access a dictionary:
data_solar_germany=ts_input_data.data["solar-germany"]
# How to plot data
using Plots
# plot(Array of our data, no legend, dotted lines, label on the x-Axis, label on the y-Axis)
plot_input_solar=plot(ts_input_data.data["solar-germany"], legend=false, linestyle=:dot, xlabel="Time [h]", ylabel="Solar availability factor [%]")

# How to load your own data:
# Single file at the path e.g. homedir/tutorial/solar.csv
my_path=joinpath(homedir(),"tutorial","solar.csv")
load_timeseries_data(my_path; region="GER_18", K=365, T=24)
# Multiple files in the folder e.g. homedir/tutorial/
my_path=joinpath(homedir(),"tutorial")
load_timeseries_data(my_path; region="GER_18", K=365, T=24)

#############
# Clustering
#############
# Quick example and investigation of the best result:
ts_clust_data = run_clust(ts_input_data; method="kmeans", representation="centroid", n_init=5, n_clust=5).best_results
# And some plotting:
plot_comb_solar=plot!(plot_input_solar, ts_clust_data.data["solar-germany"], linestyle=:solid, width=3)
plot_clust_soar=plot(ts_clust_data.data["solar-germany"], legend=false, linestyle=:solid, width=3, xlabel="Time [h]", ylabel="Solar availability factor [%]")

#= Clustering options:
`run_clust()` takes the full `data` and gives a struct with the clustered data as the output.

The input parameter `n_clust` determines the number of clusters,i.e., representative periods.

## Supported clustering methods

The following combinations of clustering method and representations are supported by `run_clust`:

Name                                                | method            | representation
----------------------------------------------------|-------------------|----------------
k-means clustering                                  | `<kmeans>`        | `<centroid>`
k-means clustering with medoid representation       | `<kmeans>`        | `<medoid>`
k-medoids clustering (partitional)                  | `<kmedoids>`      | `<medoid>`
k-medoids clustering (exact) [requires Gurobi]      | `<kmedoids_exact>`| `<medoid>`
hierarchical clustering with centroid representation| `<hierarchical>`  | `<centroid>`
hierarchical clustering with medoid representation  | `<hierarchical>`  | `<medoid>`      =#

######
# CEP
######
# Using a Solver called Clp (if not intstalled run `using Pkg; Pkg.add("Clp")`):
using Clp
solver=ClpSolver()
# Some extra data for nodes, costs and so on:
cep_data = load_cep_data(ts_clust_data.region)
# Running a simple CEP with a co2-limit of 1000 kg/MWh
co2_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="co2",co2_limit=1000)
