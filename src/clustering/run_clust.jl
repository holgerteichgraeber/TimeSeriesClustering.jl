# This file provides the wrapper function run_clust for all clustering methods in the folder runfiles
# include all files from runfiles folder here
wor_dir = pwd()
cd(dirname(@__FILE__)) # change working directory to current file
include(joinpath(pwd(),"runfiles","cluster_gen_kmeans_centroid.jl"))
include(joinpath(pwd(),"runfiles","cluster_gen_kmeans_medoid.jl"))
include(joinpath(pwd(),"runfiles","cluster_gen_kmedoids_medoid.jl"))
include(joinpath(pwd(),"runfiles","cluster_gen_kmedoids_exact_medoid.jl"))
#TODO: Include Hierarchical
#include(joinpath(pwd(),"runfiles","cluster_gen_hierarchical_centroid.jl"))
#include(joinpath(pwd(),"runfiles","cluster_gen_hierarchical_medoid.jl"))
include(joinpath(pwd(),"runfiles","cluster_gen_dbaclust_centroid.jl"))

cd(wor_dir) # change working directory to old previous file's dir


"""
function run_clust(
      data::ClustInputData;
      norm_op::String="zscore",
      norm_scope::String="full",
      method::String="kmeans",
      representation::String="centroid",
      n_clust_ar::Array=collect(1:9),
      n_init::Int=100,
      iterations::Int=300,
      save::String="",
      kwargs...
    )

norm_op: "zscore", "01"(not implemented yet)
norm_scope: "full","sequence","hourly"
method: "kmeans",...
representation: "centroid","medoid"
"""
function run_clust(
      data::ClustInputData;
      norm_op::String="zscore",
      norm_scope::String="full",
      method::String="kmeans",
      representation::String="centroid",
      n_clust_ar::Array=collect(1:9),
      n_init::Int=100,
      iterations::Int=300,
      save::String="",
      attribute_weights::Dict=Dict{String,Any}(),
      kwargs...
    )
    check_kw_args(norm_op,norm_scope,method,representation)
    # TODO: implement other methods with generic method call in for loops
    if method!="kmeans" || representation !="centroid"
       @error("Any method other than kmeans centroid not implemented yet. TODO")
    end
    # normalize
    # TODO: implement 0-1 normalization and add as a choice to runclust
    data_norm = z_normalize(data;scope=norm_scope)
    data_norm_att = attribute_weigh(data_norm,attribute_weights)
    data_norm_merged = ClustInputDataMerged(data_norm_att)

     # initialize dictionaries of the loaded data (key: number of clusters, n_init)
    centers = Dict{Tuple{Int,Int},Array}()
    clustids = Dict{Tuple{Int,Int},Array}()
    cost = zeros(length(n_clust_ar),n_init)
    iter =  zeros(length(n_clust_ar),n_init)
    weights = Dict{Tuple{Int,Int},Array}()

    # clustering

    for n_clust_it=1:length(n_clust_ar)
      n_clust = n_clust_ar[n_clust_it] # use for indexing Dicts; n_clust_it is used for indexing Arrays
        for i = 1:n_init
 # TODO: implement other clustering methods
           centers[n_clust,i],weights[n_clust,i],clustids[n_clust,i],cost[n_clust_it,i],iter[n_clust_it,i] =
              run_clust_kmeans_centroid(data_norm_merged,n_clust,iterations)
        end
    end

    # find best
 # TODO: write as function
    ind_mincost = findmin(cost,dims=2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    cost_best = zeros(size(cost,1))
    ind_mincost_2 = zeros(size(cost,1))
    for i=1:size(cost,1)
        cost_best[i]=cost[ind_mincost[i]]
        # linear to cartesian indice (get column value [2] in order to get the initial starting point of interest. i is the row value already.)
        ind_mincost_2[i]=CartesianIndices(cost)[ind_mincost[i]][2]
    end

    # save best results as ClustInputData
      # an array that contains 9 ClustInputData, one for each k
    best_results = ClustInputData[]
    best_weights = Array[]
    best_ids = Array[]
    for i=1:length(n_clust_ar)
        n_clust = n_clust_ar[i] # use for indexing Dicts
        i_mincost = ind_mincost_2[i] # minimum cost index at cluster numbered i
        # save in merged format as array
        b_merged = ClustInputDataMerged(data_norm_merged.region,n_clust_ar[i],data_norm_merged.T,centers[n_clust,i_mincost],data_norm_merged.data_type,weights[n_clust,i_mincost])
        # transfer into ClustInputData format
        b = ClustInputData(b_merged)
        push!(best_results,b)
        # save best clust ids
        push!(best_ids,clustids[n_clust,i_mincost])
    end
    # save all locally converged solutions and the best into a struct
    clust_result = ClustResultAll(best_results,best_ids,cost_best,n_clust_ar,centers,data_norm_merged.data_type,weights,clustids,cost,iter)
    # TODO save in save file

    return clust_result
end

#QUESTION Shall we rename already to a,b as it is not sdv after division?
"""
function attribute_weigh(data::ClustInputData,attribute_weights)
scope: "full", "sequence", "hourly"
"""
function attribute_weigh(data::ClustInputData,attribute_weights::Dict)
  for name in keys(data.data)
    #The first element before - defines the tech -> for time being weighting techs and Dict(tech -> weight)
    tech=split(name,"-")[1]
    if findall(tech.==keys(attribute_weights))!=[]
      attribute_weight=attribute_weights[tech]
      data.data[name].*=attribute_weight
      data.sdv[name]./=attribute_weight
    end
  end
  return data
end
"""
OLD
TODO: Get rid of this one
function run_clust(
      region::String,
      opt_problem::Array{String};
      norm_op::String="zscore",
      norm_scope::String="full",
      method::String="kmeans",
      representation::String="centroid",
      n_clust_ar::Array=collect(1:9),
      n_init::Int=100,
      iterations::Int=300
    )

Wrapper function that calls the specific clustering methods. Saves results as jld2 file in a newly created folder outfiles, and also returns results from clustering.
"""
function run_clust_old(
      region::String,
      opt_problems::Array{String};
      norm_op::String="zscore",
      norm_scope::String="full",
      method::String="kmeans",
      representation::String="centroid",
      n_clust_ar::Array=collect(1:9),
      n_init::Int=100,
      iterations::Int=300,
      kwargs...
    )

    check_kw_args(norm_op,norm_scope,method,representation)

    # function call to the respective function (method + representation)
    fun_name = Symbol("run_clust_"*method*"_"*representation)
    return @eval $fun_name($region,$opt_problems,$norm_op,$norm_scope,$n_clust_ar,$n_init,$iterations;$kwargs...)
end


"""
TODO: GET RID OF THIS ONE
function run_clust(
    region::String,
    opt_problem::String;
    kwargs ...
    )

Wrapper function for run_clust to allow for one input argument only for the optimization problem type.
"""
function run_clust_old(
      region::String,
      opt_problem::String;
      kwargs ...
    )
    return run_clust(region,[opt_problem];kwargs...)
end

 # supported keyword arguments
sup_kw_args =Dict{String,Array{String}}()
sup_kw_args["region"]=["GER","CA"]
sup_kw_args["opt_problems"]=["battery","gas_turbine"]
sup_kw_args["norm_op"]=["zscore"]
sup_kw_args["norm_scope"]=["full","hourly","sequence"]
sup_kw_args["method+representation"]=["kmeans+centroid","kmeans+medoid","kmedoids+medoid","kmedoids_exact+medoid","hierarchical+centroid","hierarchical+medoid","dbaclust+centroid","kshape+centroid"]


"""
Returns supported keyword arguments for clustering function run_clust()
"""
function get_sup_kw_args()
    return sup_kw_args
end



"""
check_kw_args(region,opt_problems,norm_op,norm_scope,method,representation)
checks if the arguments supplied for run_clust are supported
"""
function check_kw_args(
      norm_op::String,
      norm_scope::String,
      method::String,
      representation::String
    )
    check_ok = true
    error_string = "The following keyword arguments / combinations are not currently supported: \n"
    # norm_op
    if !(norm_op in sup_kw_args["norm_op"])
       check_ok=false
       error_string = error_string * "normalization operation $norm_op is not supported \n"
    end
    # norm_scope
    if !(norm_scope in sup_kw_args["norm_scope"])
       check_ok=false
       error_string = error_string * "normalization scope $norm_scope is not supported \n"
    end
    # method +  representation
    if !(method*"+"*representation in sup_kw_args["method+representation"])
       check_ok=false
       error_string = error_string * "the combination of method $method and representation $representation is not supported \n"
    elseif method == "dbaclust"
       @info("dbaclust can be run in parallel using src/clust_algorithms/runfiles/cluster_gen_dbaclust_parallel.jl")
    elseif method =="kshape"
       check_ok=false
       error_string = error_string * "kshape is implemented in python and should be run individually: src/clust_algorithms/runfiles/cluster_gen_kshape.py \n"
    end
    error_string = error_string * "get_sup_kw_args() provides a list of supported keyword arguments."

    if check_ok
       return true
    else
       error(error_string)
    end
end
