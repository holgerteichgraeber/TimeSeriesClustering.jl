# Holger Teichgraeber, 2017

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #
 #####################
using StatsKit
using JLD2
using FileIO
using JuMP #QUESTION should this be part of ClustForOpt?





include(joinpath("utils","datastructs.jl"))
include(joinpath("utils","utils.jl"))
include(joinpath("utils","load_data.jl"))
include(joinpath("optim_problems","run_opt.jl"))
include(joinpath("clustering","run_clust.jl"))
include(joinpath("clustering","exact_kmedoids.jl"))
include(joinpath("clustering","extreme_vals.jl"))
include(joinpath("clustering","attribute_weighting.jl"))
include(joinpath("clustering","intraperiod_segmentation.jl"))
include(joinpath("clustering","other_clust.jl"))
