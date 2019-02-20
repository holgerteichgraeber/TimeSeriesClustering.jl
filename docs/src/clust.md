# Clustering

`run_clust()` takes the full `data` and gives a struct with the clustered data as the output.   

The input parameter `n_clust` determines the number of clusters,i.e., representative periods.

## Supported clustering methods

The following combinations of clustering method and representations are supported by `run_clust`:

Name | method | representation
---- | --------------- | -----------------------
k-means clustering | `<kmeans>` | `<centroid>`
k-means clustering with medoid representation | `<kmeans>` | `<medoid>`
k-medoids clustering (partitional) | `<kmedoids>` | `<centroid>`
k-medoids clustering (exact) [requires Gurobi] | `<kmedoids_exact>` | `<centroid>`
hierarchical clustering with centroid representation | `<hierarchical>` | `<centroid>`
hierarchical clustering with medoid representation | `<hierarchical>` | `<medoid>`

For use of DTW barycenter averaging (DBA) and k-shape clustering on single-attribute data (e.g. electricity prices), please use branch `v0.1-appl_energy-framework-comp`.

```@docs
run_clust
```

### Example running clustering
```@example
using ClustForOpt
state="GER_1"
# laod ts-input-data
ts_input_data, = load_timeseries_data("CEP", state; K=365, T=24)
ts_clust_data = run_clust(ts_input_data).best_results

using Plots
plot(ts_clust_data.data["solar-germany"], legend=false, linestyle=:solid, width=3, xlabel="Time [h]", ylabel="Solar availability factor [%]")
savefig("plot.svg")
Markdown.parse("![Plot](plot.svg)")
```
