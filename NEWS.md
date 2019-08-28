TimeSeriesClustering release notes
=========================

Version 0.5.0
-------------

Breaking changes

- The package has been renamed to `TimeSeriesClustering.jl` (`ClustForOpt.jl` -> `TimeSeriesClustering.jl`). Besides the name change, the functionality stays the same.
- First, update your package registry `] up`.
- Remove the old package with `] rm ClustForOpt` or `Pkg.rm("ClustForOpt")`
- Add the package with `] add TimeSeriesClustering` or `Pkg.add("TimeSeriesClustering")`, and 
- Use the package with `using TimeSeriesClustering`.

Version 0.4.0
-------------

Breaking changes

- The `ClustResult` struct has been renamed to `AbstractClustResult`.
- The `ClustResultBest` struct has been renamed to `ClustResult`.
- The structs `ClustResult` and `ClustResultAll` have had several field names renamed: `best_results` to `clust_data`, `best_cost` to `cost`, `clust_config` to `config`. The fields `data_type` and `best_ids` have been removed, because they are already contained explicitly (`k_ids`) or implicitly(call `data_type(data::ClustData)`) in `ClustData`.
- The field names `centers, weights, clustids, cost, iter` in `ClustResultAll` have been renamed, all have now the ending `_all` to indicate that these are the results for all random initializations of the clustering algorithm.
