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
-mean: For normalized data: The shift of the mean as a dictionary for each attribute
-sdv: For normalized data: Standard deviation as a dictionary for each attribute

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
# put your data into your homedirectory into a folder called tutorial
# The data should have the following structure: see data folder of our own data
load_your_own_data=false
if load_your_own_data
# Single file at the path e.g. homedir/tutorial/solar.csv
# It will automatically call the data 'solar' within the datastruct
  my_path=joinpath(homedir(),"tutorial","solar.csv")
  your_data_1=load_timeseries_data(my_path; region="GER_18", K=365, T=24)
# Multiple files in the folder e.g. homedir/tutorial/
# Within the data struct, it will automatically call the data the names of the csv filenames 
  my_path=joinpath(homedir(),"tutorial")
  your_data_2=load_timeseries_data(my_path; region="GER_18", K=365, T=24)
end



#############
# Clustering
#############
# Quick example and investigation of the best result:
ts_clust_result = run_clust(ts_input_data; method="kmeans", representation="centroid", n_init=5, n_clust=5) # note that you should use n_init=1000 at least for kmeans.
print(ts_clust_result)
ts_clust_data = ts_clust_result.best_results
# And some plotting:
plot_comb_solar=plot!(plot_input_solar, ts_clust_data.data["solar-germany"], linestyle=:solid, width=3)
plot_clust_soar=plot(ts_clust_data.data["solar-germany"], legend=false, linestyle=:solid, width=3, xlabel="Time [h]", ylabel="Solar availability factor [%]")

#= Clustering options:
`run_clust()` takes the full `data` and gives a struct with the clustered data as the output.


## Supported clustering methods
The following combinations of clustering method and representations are supported by `run_clust`:

Name                                                | method            | representation
----------------------------------------------------|-------------------|----------------
k-means clustering                                  | `<kmeans>`        | `<centroid>`
k-means clustering with medoid representation       | `<kmeans>`        | `<medoid>`
k-medoids clustering (partitional)                  | `<kmedoids>`      | `<medoid>`
k-medoids clustering (exact) [requires Gurobi]      | `<kmedoids_exact>`| `<medoid>`
hierarchical clustering with centroid representation| `<hierarchical>`  | `<centroid>`
hierarchical clustering with medoid representation  | `<hierarchical>`  | `<medoid>`      

## Other input parameters

The input parameter `n_clust` determines the number of clusters,i.e., representative periods.

`n_init` determines the number of random starting points. As a rule of thumb, use:
`n_init` should be chosen 1000 or 10000 if you use k-means or k-medoids
`n_init` should be chosen 1 if you use k-medoids_exact or hierarchical clustering

`iterations` is defaulted to 300, which is a good value for kmeans and kmedoids in our experience. The parameter iterations does not matter when you use k-medoids exact or hierarchical clustering.

=#

# A clustering run with different options chosen as an example
ts_clust_result_2 = run_clust(ts_input_data; method="kmedoids", representation="medoid", n_init=100, n_clust=4,iterations=500)



######
# CEP
######
# Using a Solver called Clp (if not installed run `using Pkg; Pkg.add("Clp")`):
using Clp
solver=ClpSolver()
# Some extra data for nodes, costs and so on:
cep_data = load_cep_data(ts_clust_data.region)
# Running a simple CEP with a co2-limit of 1000 kg/MWh
co2_result = run_opt(ts_clust_data,cep_data;solver=solver,descriptor="co2",co2_limit=1000)
