# Holger Teichgraeber, 2017

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #
 #####################

module ClustForOpt

using Reexport
using Distances
using PyPlot
using Clustering
using JLD2
using FileIO
@reexport using DataFrames

export run_opt,
       run_clust,
       get_sup_kw_args,
       get_EUR_to_USD,
       load_pricedata,
       plot_clusters,
       subplot_clusters,
       z_normalize,
       undo_z_normalize,
       sakoe_chiba_band,
       kmedoids_exact,
       plot_k_rev,
       plot_k_rev_subplot,
       plot_SSE_rev,
       sort_centers,
       cols,
       col,
       calc_SSE,
       find_medoids,
       resize_medoids

include(joinpath("utils","optim_problems.jl"))
include(joinpath("clust_algorithms","run_clust.jl"))
include(joinpath("utils",".juliarc.jl"))
include(joinpath("utils","utils.jl"))
include(joinpath("utils","utils_plots.jl"))
include(joinpath("clust_algorithms","exact_kmedoids.jl"))

end # module ClustForOpt
