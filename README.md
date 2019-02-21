![ClustForOpt](docs/src/assets/clust_for_opt_text.svg)
===
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://holgerteichgraeber.github.io/ClustForOpt.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://holgerteichgraeber.github.io/ClustForOpt.jl/dev)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE)
[![Build Status](https://travis-ci.com/holgerteichgraeber/ClustForOpt.jl.svg?token=HRFemjSxM1NBCsbHGNDG&branch=master)](https://travis-ci.com/holgerteichgraeber/ClustForOpt.jl)

ClustForOpt is a [julia](www.juliaopt.com) implementation of clustering methods for finding representative periods for the optimization of energy systems. The package furthermore provides a multi-node capacity expansion model.

The package has three main purposes: 1) Provide a simple process of clustering time-series input data, with clustered data output in a generalized type system 2) provide an interface between clustered data and optimization problem 3) provide a generalizable capacity expansion problem formulation and data to test clustering on this problem.

The package follows the clustering framework presented in [Teichgraeber and Brandt, 2019](https://doi.org/10.1016/j.apenergy.2019.02.012).
The package is actively developed, and new features are continuously added. For a reproducible version of the methods and data of the original paper by [Teichgraeber and Brandt, 2019](https://doi.org/10.1016/j.apenergy.2019.02.012), please refer to release [v0.1](https://github.com/holgerteichgraeber/ClustForOpt.jl/tree/v0.1).

This package is developed by Holger Teichgraeber [@holgerteichgraeber](https://github.com/holgerteichgraeber) and Elias Kuepper [@YoungFaithful](https://github.com/youngfaithful).

If you find ClustForOpt useful in your work, we kindly request that you cite the following paper ([link](https://doi.org/10.1016/j.apenergy.2019.02.012)):

```
  @article{Teichgraeber2019,
  author = {Holger Teichgraeber and Adam Brandt},
  title = {Clustering methods to find representative periods for the optimization of energy systems: An initial framework and comparison},
  journal = {Applied Energy},
  volume = {239},
  pages = {1283–1293},
  year = {2019},
  doi = {https://doi.org/10.1016/j.apenergy.2019.02.012},
  }
```

## Installation
This package runs under julia v1.0 and higher.
Install using:

```julia
]
add https://github.com/holgerteichgraeber/ClustForOpt.jl.git
```
where `]` opens the julia package manager.

## Documentation
[Stable](https://holgerteichgraeber.github.io/ClustForOpt.jl/stable)

[Development](https://holgerteichgraeber.github.io/ClustForOpt.jl/dev)

## Workflow

Generally, the workflow requires three steps:
- load data
- clustering
- optimization

```julia
using ClustForOpt

# load data (electricity price day ahead market)
ts_input_data, = load_timeseries_data("DAM", "GER";K=365, T=24) #DAM

# run standard kmeans clustering algorithm to cluster into 5 representative periods, with 1000 initial starting points
clust_res = run_clust(ts_input_data;method="kmeans",representation="centroid",n_clust=5,n_init=1000)

# battery operations optimization on the clustered data
opt_res = run_opt(clust_res)
```

### Load data
`load_timeseries_data()` loads the data for a given `application` and `region`.
Possible applications are
- `DAM`: Day ahead market price data
- `CEP`: Capacity Expansion Problem data

Possible regions are:
- `GER`: Germany
- `CA`: California
- `TX`: Texas

The optional input parameters to `load_timeseries_data()` are the number of periods `K` and the number of time steps per period `T`. By default, they are chosen such that they result in daily time slices.


### Clustering
`run_clust()` takes the full `data` and gives a struct with the clustered data as the output.   

The input parameter `n_clust` determines the number of clusters,i.e., representative periods.

#### Supported clustering methods

The following combinations of clustering method and representations are supported by [run\_clust()](src/clustering/run_clust.jl):

Name | method | representation
---- | --------------- | -----------------------
k-means clustering | `<kmeans>` | `<centroid>`
k-means clustering with medoid representation | `<kmeans>` | `<medoid>`
k-medoids clustering (partitional) | `<kmedoids>` | `<medoid>`
k-medoids clustering (exact) [requires Gurobi] | `<kmedoids_exact>` | `<medoid>`
hierarchical clustering with centroid representation | `<hierarchical>` | `<centroid>`
hierarchical clustering with medoid representation | `<hierarchical>` | `<medoid>`

For use of DTW barycenter averaging (DBA) and k-shape clustering on single-attribute data (e.g. electricity prices), please use branch `v0.1-appl_energy-framework-comp`.



### Optimization
The function `run_opt()` runs the optimization problem and gives as an output a struct that contains optimal objective function value, decision variables, and additional info. The `run_opt()` function infers the optimization problem type from the input data. See the examples folder for further details.

More detailed documentation on the Capacity Expansion Problem can be found in the documentation.
