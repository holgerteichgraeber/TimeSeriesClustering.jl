# TODOs

Generally, TODOs are signified by TODO within the code. The following list provides some general TODOs:

* update to julia 0.7

* Performance: Loading the package takes time. Test all packages that are loaded with *using* and check needed. Test time for each with *@time*

* implement 0-1 normalization in run_clust

* save ClustResults as jld2 

* include time step length del_t in data struct? 

* make weights >1 throughout the full code. E.g. resize_medoids in util.jl

* implement hierarchical clustering based on Clustering.jl, and kshape as a .jl algorithm. -> get rid of python dependencies.

* update runfiles folder in cluster_algorithms. Put all of them in cluster_algorithms folder, get rid of runfiles folder.

* update results_analysis folder. Get rid or put into seperate package?

* ClustResults - only one k
