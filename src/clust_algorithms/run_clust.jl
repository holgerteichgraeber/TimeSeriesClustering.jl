#

# include all files from runfiles folder here
wor_dir = pwd()
cd(dirname(@__FILE__)) # change working directory to current file
include(joinpath(pwd(),"runfiles","cluster_gen_kmeans_centroid.jl"))

cd(wor_dir) # change working directory to old previous file's dir

"""
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
"""
function run_clust(
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

    check_kw_args(region,opt_problems,norm_op,norm_scope,method,representation)    
    
    # function call to the respective function (method + representation)
    fun_name = Symbol("run_clust_"*method*"_"*representation)
    @eval $fun_name($region,$opt_problems,$norm_op,$norm_scope,$n_clust_ar,$n_init,$iterations)
 #   run_clust_kmeans_centroid(region,opt_problems,norm_op,norm_scope,n_clust_ar,n_init,iterations)
end


"""
function run_clust(
    region::String,
    opt_problem::String;
    kwargs ...
    )

Wrapper function for run_clust to allow for one input argument only for the optimization problem type.
"""
function run_clust(
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
      region::String,
      opt_problems::Array{String},
      norm_op::String,
      norm_scope::String,
      method::String,
      representation::String
    )
    check_ok = true 
    error_string = "The following keyword arguments / combinations are not currently supported: \n"
    # region
    if !(region in sup_kw_args["region"])
       check_ok=false
       error_string = error_string * "region $region is not supported \n"
    end
    # opt_problems
    for o in opt_problems
        if !(o in sup_kw_args["opt_problems"])
           check_ok=false
           error_string = error_string * "optimization problem $o is not supported \n"
        end
    end
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
       info("dbaclust can be run in parallel using src/clust_algorithms/runfiles/cluster_gen_dbaclust_parallel.jl")
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


