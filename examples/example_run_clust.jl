# Some example runs of the clustering methods and optimization problems
 # TODO:OLD Update this file. This is the old ClustForOpt
 # saves results as jld2 file, which can be imported and analyzed by subsequent functions

using ClustForOpt
using Gurobi
env = Gurobi.Env()

 # default kmeans + centroid run
run_clust("GER","battery";n_init=3)

 #  kmeans + medoid run
run_clust("GER","battery";representation="medoid",n_init=3)

 #  kmedoids + medoid run (partitional)
run_clust("GER","battery";method="kmedoids",representation="medoid",n_init=3)

 # kmedoids + medoid run (exact)
 #QUESTION Shall we force the usage of Gurobi
run_clust("GER","battery";method="kmedoids_exact",representation="medoid",n_init=3,gurobi_env=env)

 #  hierarchical + centroid run
run_clust("GER","battery";method="hierarchical",representation="centroid",n_init=1)

 #  hierarchical + medoid run
run_clust("GER","battery";method="hierarchical",representation="medoid",n_init=1)

 # dbaclust + centroid run
 #iterations=100
 #inner_iterations=30
 #rad_sc_min=0
 #rad_sc_max=5

 #  dbaclust + centroid run (single core, for parallel runs, use parallel version)
run_clust("GER","battery";method="dbaclust",representation="centroid",n_init=3,iterations=50,rad_sc_min=0,rad_sc_max=1,inner_iterations=30)
