# Holger Teichgraeber, 2017

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #
 #####################
 #TODO other way of including module
#module ClustForOpt_priv

using Distances
using Clustering
using JLD2
using FileIO
#TODO Update TimeWarp
#using TimeWarp
using Statistics
using LinearAlgebra
using CSV
using JuMP
using Clp
#TODO make Gurobi optional
using Gurobi
using DataFrames





include(joinpath("utils","datastructs.jl"))
include(joinpath("utils","utils.jl"))
include(joinpath("utils","load_data.jl"))
include(joinpath("optim_problems","run_opt.jl"))
include(joinpath("optim_problems","opt_cep.jl"))
include(joinpath("clustering","run_clust.jl"))
include(joinpath("clustering","exact_kmedoids.jl"))
include(joinpath("clustering","extreme_vals.jl"))
include(joinpath("clustering","attribute_weighting.jl"))
include(joinpath("clustering","intraperiod_segmentation.jl"))
