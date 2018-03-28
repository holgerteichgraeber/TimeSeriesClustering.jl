# Holger Teichgraeber, 2017

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #
 # A .juliarc.jl file is provided in ./utils/ . It should be loaded with julia prior to using the plotting capabilities of this package
 #####################

module ClustForOpt

using Reexport
using PyPlot
@reexport using DataFrames

export run_opt,
       get_EUR_to_USD,
       load_pricedata,
       plot_clusters,
       z_normalize,
       undo_z_normalize,
       sakoe_chiba_band,
       kmedoids_exact,
       plot_k_rev,
       plot_k_rev_subplot,
       plot_SSE_rev,
       sort_centers,
       cols,
       col

include("utils/.juliarc.jl")
include("utils/optim_problems.jl")
include("utils/utils.jl")
include("clust_algorithms/exact_kmedoids.jl")

end # module ClustForOpt
