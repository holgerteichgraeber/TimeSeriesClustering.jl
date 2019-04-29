![ClustForOpt logo](assets/clust_for_opt_text.svg)
===
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://holgerteichgraeber.github.io/ClustForOpt.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://holgerteichgraeber.github.io/ClustForOpt.jl/dev)
[![Build Status](https://travis-ci.com/holgerteichgraeber/ClustForOpt.jl.svg?token=HRFemjSxM1NBCsbHGNDG&branch=master)](https://travis-ci.com/holgerteichgraeber/ClustForOpt.jl)

[ClustForOpt](https://github.com/holgerteichgraeber/ClustForOpt.jl) is a [julia](https://www.juliaopt.com) implementation of clustering methods for finding representative periods for optimization problems. A utilization in a scalable capacity expansion problem can be found in the package [CEP](https://github.com/YoungFaithful/CapacityExpansion.jl).

The package has two main purposes: 1) Provide a simple process of clustering time-series input data, with clustered data output in a generalized type system 2) provide an interface between clustered data and optimization problem.

The package follows the clustering framework presented in [Teichgraeber and Brandt, 2019](https://doi.org/10.1016/j.apenergy.2019.02.012).
The package is actively developed, and new features are continuously added. For a reproducible version of the methods and data of the original paper by [Teichgraeber and Brandt, 2019](https://doi.org/10.1016/j.apenergy.2019.02.012), please refer to branch `v0.1-appl_energy-framework-comp`.

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
add ClustForOpt
```
where `]` opens the julia package manager.
