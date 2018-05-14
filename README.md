ClustForOpt 
==============

Usage 
-----
Installation: add environment variable CLUST\_FOR\_OPT = "path/to/ClustForOpt" to your systems environment variables



old
---

The kshape runfile uses full paths in order to run from any location on computing cluster, everything else should be in relative path for use on both windows and linux


Data:

The folders kshape_results and kshape_results_itmax do not contain the data, to be saved seperately

TODO before making this a package:
- sequence method for kmeans and all other cluster gen methods: when choosing sequence normalization, automatically add idx=clustids to undo_z_normalize
