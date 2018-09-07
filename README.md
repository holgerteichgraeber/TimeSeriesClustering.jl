# ClustForOpt 

julia implementation of using different clustering methods for finding representative perdiods for the optimization of energy systems. 

## Installation
This package is not officielly registered. Install using: 

```julia
Pkg.clone("https://github.com/holgerteichgraeber/ClustForOpt.jl.git") 
```

Seperately install [TimeWarp.jl](https://github.com/ahwillia/TimeWarp.jl) 


## Supported clustering methods

The following combinations of clustering method and representation are supported by `run_clust()`:

Name | method argument | representation argument
---- | --------------- | -----------------------
k-means clustering | `<kmeans>` | `<centroid>`
k-means clustering with medoid representation | `<kmeans>` | `<medoid>`
k-medoids clustering (partitional) | `<kmedoids>` | `<centroid>`
k-medoids clustering (exact) | `<kmedoids_exact>` | `<centroid>`
hierarchical clustering with centroid representation | `<hierarchical>` | `<centroid>`
hierarchical clustering with medoid representation | `<hierarchical>` | `<medoid>`
dynamic barycenter averaging (DBA) clustering | `<dbaclust>` | `<centroid>`
k-shape clustering | `<kshape>` | `<centroid>`

old
---

The kshape runfile uses full paths in order to run from any location on computing cluster, everything else should be in relative path for use on both windows and linux


Data:

The folders kshape_results and kshape_results_itmax do not contain the data, to be saved seperately

TODO before making this a package:
- sequence method for kmeans and all other cluster gen methods: when choosing sequence normalization, automatically add idx=clustids to undo_z_normalize
