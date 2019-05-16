ClustForOpt release notes
=========================

Version 0.4.0
-------------

Breaking changes

- The `ClustResult` struct has been renamed to `AbstractClustResult`.
- The `ClustResultBest` struct has been renamed to `ClustResult`.
- The structs `ClustResult` and `ClustResultAll` have had several field names renamed: `best_results` to `clust_data`, `best_cost` to `cost`, `clust_config` to `config`. The fields `data_type` and `best_ids` have been removed, because they are already contained explicitly (`k_ids`) or implicitly(call `data_type(data::ClustData)`) in `ClustData`. 
- The field names `centers, weights, clustids, cost, iter` in `ClustResultAll` have been renamed, all have now the ending `_all` to indicate that these are the results for all random initializations of the clustering algorithm.
