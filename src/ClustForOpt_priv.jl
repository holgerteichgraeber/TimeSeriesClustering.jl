# Holger Teichgraeber, 2017

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #
 #####################
module ClustForOpt_priv


#TODO less packages
using Reexport
using Distances
using PyPlot
using Clustering
using JLD2
using FileIO
using PyCall
#TODO Update TimeWarp
#using TimeWarp
using JuMP
using Clp
using CSV
using Statistics
using LinearAlgebra
@reexport using DataFrames
 #TODO how to make PyPlot, PyCall, and TimeWarp optional? -> only import when needed


export run_opt,
       run_clust,
       get_sup_kw_args,
       InputData,
       FullInputData,
       ClustInputData,
       ClustInputDataMerged,
       get_EUR_to_USD,
       load_input_data,
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
       #TODO Move to private Git
       cols,
       col,
       calc_SSE,
       find_medoids,
       resize_medoids

include(joinpath("utils","datastructs.jl"))
include(joinpath("utils","utils.jl"))
include(joinpath("utils","load_data.jl"))
include(joinpath("utils",".juliarc.jl"))
include(joinpath("utils","utils_plots.jl"))
include(joinpath("optim_problems","run_opt.jl"))
include(joinpath("clustering","run_clust.jl"))
include(joinpath("clustering","exact_kmedoids.jl"))

end # module ClustForOpt
