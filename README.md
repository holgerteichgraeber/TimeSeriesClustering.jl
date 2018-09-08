# ClustForOpt 

julia implementation of using different clustering methods for finding representative perdiods for the optimization of energy systems. 

## Installation
This package runs under julia v0.6.
This package is not officielly registered. Install using: 

```julia
Pkg.clone("https://github.com/holgerteichgraeber/ClustForOpt.jl.git") 
```

Then, seperately install [TimeWarp.jl](https://github.com/ahwillia/TimeWarp.jl) 


## Supported clustering methods

The following combinations of clustering method and representation are supported by `run_clust()`:

Name | method argument | representation argument
---- | --------------- | -----------------------
k-means clustering | `<kmeans>` | `<centroid>`
k-means clustering with medoid representation | `<kmeans>` | `<medoid>`
k-medoids clustering (partitional) | `<kmedoids>` | `<centroid>`
k-medoids clustering (exact) [requires Gurobi] | `<kmedoids_exact>` | `<centroid>`
hierarchical clustering with centroid representation | `<hierarchical>` | `<centroid>`
hierarchical clustering with medoid representation | `<hierarchical>` | `<medoid>`
DTW barycenter averaging (DBA) clustering | `<dbaclust>` | `<centroid>`
k-shape clustering | `<kshape>` | `<centroid>`

## Example use of `run_clust()`
```julia
using ClustForOpt

 # default kmeans + centroid
run_clust("GER","battery";n_init=3)

 #  kmeans + medoid
run_clust("GER","battery";representation="medoid",n_init=3)
 
 #  kmedoids + medoid (partitional)
run_clust("GER","battery";method="kmedoids",representation="medoid",n_init=3) 

 # kmedoids + medoid (exact)
using Gurobi
env = Gurobi.Env()
run_clust("GER","battery";method="kmedoids_exact",representation="medoid",n_init=3,gurobi_env=env) 

 #  hierarchical + centroid 
run_clust("GER","battery";method="hierarchical",representation="centroid",n_init=1) 

 #  hierarchical + medoid 
run_clust("GER","battery";method="hierarchical",representation="medoid",n_init=1) 

 #  dbaclust + centroid (single core, for parallel runs, use parallel version)
run_clust("GER","battery";method="dbaclust",representation="centroid",n_init=3,iterations=50,rad_sc_min=0,rad_sc_max=1,inner_iterations=30)

```

## General workflow

Run clustering method with the respective optimization problem first: `run_clust()`. 
This will generate a jld2 file with resulting clusters, cluster assignments, and optimization problem outcomes. 
Then, use result analysis files to analyze and interpret clustering and optimization results from folder `src/results_analysis`.

### Parallel implementation of DBA clustering
run the file `src/clustering_algorithms/runfiles/cluster_gen_dbaclust_parallel.jl` on multiple cores (julia currently only allows parallelization through pmap on one node). Then use `src/results_analysis/dbaclust_res_to_jld2.jl` to generate jld2 file. Then proceed with result analysis similar to the general workflow.


### k-shape
run the file `src/clustering_algorithms/runfiles/cluster_gen_kshape.py` on multiple cores. Then use `src/results_analysis/kshape_res_to_jld2.jl` to generate jld2 file. Then proceed with result analysis similar to the general workflow.



