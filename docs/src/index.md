![TimeSeriesClustering](docs/src/assets/clust_for_opt_text.svg)
===
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://holgerteichgraeber.github.io/TimeSeriesClustering.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://holgerteichgraeber.github.io/TimeSeriesClustering.jl/dev)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE)
[![Build Status](https://travis-ci.com/holgerteichgraeber/TimeSeriesClustering.jl.svg?token=HRFemjSxM1NBCsbHGNDG&branch=master)](https://travis-ci.com/holgerteichgraeber/TimeSeriesClustering.jl)
[![codecov](https://codecov.io/gh/holgerteichgraeber/TimeSeriesClustering.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/holgerteichgraeber/TimeSeriesClustering.jl)


[TimeSeriesClustering](https://github.com/holgerteichgraeber/TimeSeriesClustering.jl) is a [Julia](https://www.juliaopt.com) implementation of unsupervised learning methods for time series datasets. It provides functionality for clustering and aggregating, detecting motifs, and quantifying similarity between time series datasets.
The software provides a type system for temporal data, and provides an implementation of the most commonly used clustering methods and extreme value selection methods for temporal data.
It provides simple integration of multi-dimensional time-series data (e.g. multiple attributes such as wind availability, solar availability, and electricity demand) in a single aggregation process.
The software is applicable to general time series datasets and lends itself well to a multitude of application areas within the field of time series data mining.

The TimeSeriesClustering package was originally developed to perform time series aggregation for energy systems optimization problems. By reducing the number of time steps used in the optimization model, using representative periods leads to significant reductions in computational complexity of these problems.
The packages was previously known as `ClustForOpt.jl`.

The package has three main purposes:
1) Provide a simple process of finding representative periods (reducing the number of observations) for time-series input data, with implementations of the most commonly used clustering methods and extreme value selection methods.
2) Provide an interface between representative period data and application (e.g. optimization problem) by having representative period data stored in a generalized type system.
3) Provide a generalized import feature for time series, where variable names, attributes, and node names are automatically stored and can then be used later when the reduced time series is used in the application at hand (e.g. in the definition of sets of the optimization problem).

In the domain of energy systems optimization, an example problem that uses TimeSeriesClustering for its input data is the package [CapacityExpansion](https://github.com/YoungFaithful/CapacityExpansion.jl), which implements a scalable generation and transmission capacity expansion problem.

The TimeSeriesClustering package follows the clustering framework presented in [Teichgraeber and Brandt, 2019](https://doi.org/10.1016/j.apenergy.2019.02.012).
The package is actively developed, and new features are continuously added.
For a reproducible version of the methods and data of the original paper by [Teichgraeber and Brandt, 2019](https://doi.org/10.1016/j.apenergy.2019.02.012), please refer to [v0.1](https://github.com/holgerteichgraeber/TimeSeriesClustering.jl/tree/v0.1) (including shape based methods such as `k-shape` and `dynamic time warping barycenter averaging`).

This package is developed by Holger Teichgraeber [@holgerteichgraeber](https://github.com/holgerteichgraeber) and Elias Kuepper [@YoungFaithful](https://github.com/youngfaithful).

## Installation
This package runs under julia v1.0 and higher.
Install using:

```julia
import Pkg
Pkg.add("TimeSeriesClustering")
```

## Citing TimeSeriesClustering
If you find TimeSeriesClustering useful in your work, we kindly request that you cite the following paper ([link](https://doi.org/10.1016/j.apenergy.2019.02.012)):

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
