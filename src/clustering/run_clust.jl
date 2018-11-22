
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
      kwargs...
    )
    
    # When adding new methods: add combination of clust+rep to sup_kw_args
    check_kw_args(norm_op,norm_scope,method,representation)
    
    # normalize
    # TODO: implement 0-1 normalization and add as a choice to runclust
    data_norm = z_normalize(data;scope=norm_scope)
    data_norm_merged = ClustInputDataMerged(data_norm)

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
 # TODO: implement shape based clustering methods
           # function call to the respective function (method + representation)
           fun_name = Symbol("run_clust_"*method*"_"*representation)
           centers[n_clust,i],weights[n_clust,i],clustids[n_clust,i],cost[n_clust_it,i],iter[n_clust_it,i] =
           @eval $fun_name($data_norm_merged,$n_clust,$iterations;$kwargs...)
    
           # recalculate centers if medoids is used. Recalculate because medoid is not integrally preserving
          if representation=="medoid"
            centers[n_clust,i] = resize_medoids(data,centers[n_clust,i],weights[n_clust,i])
          end
       end
    end

    # find best
 # TODO: write as function
    ind_mincost = findmin(cost,dims=2)[2]  # along dimension 2, only store indices
    cost_best = zeros(size(cost,1))
    ind_mincost_2 = zeros(size(cost,1))
    for i=1:size(cost,1)
        cost_best[i]=cost[ind_mincost[i]]
        # linear to cartesian indice (get column value [2] in order to get the initial starting point of interest. i is the row value already.) 
        ind_mincost_2[i]=ind_mincost[i][2]
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
    # save in save file
    #TODO

    return clust_result
end

 # supported keyword arguments
sup_kw_args =Dict{String,Array{String}}()
sup_kw_args["region"]=["GER","CA"]
sup_kw_args["opt_problems"]=["battery","gas_turbine"]
sup_kw_args["norm_op"]=["zscore"]
sup_kw_args["norm_scope"]=["full","hourly","sequence"]
sup_kw_args["method+representation"]=["kmeans+centroid","kmeans+medoid","kmedoids+medoid","kmedoids_exact+medoid","hierarchical+centroid","hierarchical+medoid"]#["dbaclust+centroid","kshape+centroid"]


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

"""
function run_clust_kmeans_centroid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int
    )
"""
function run_clust_kmeans_centroid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int
    )
    centers,weights,clustids,cost,iter =[],[],[],0,0
    # if only one cluster
    if n_clust ==1
        centers_norm = mean(data_norm.data,dims=2) # should be 0 due to normalization
        clustids = ones(Int,size(data_norm.data,2))
        centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids) # need to provide idx in case that sequence-based normalization is used
        cost = sum(pairwise(SqEuclidean(),centers_norm,data_norm.data)) #same as sum((seq_norm-repmat(mean(seq_norm,2),1,size(seq,2))).^2)
        iter = 1
    # kmeans() in Clustering.jl is implemented for k>=2
    else
        results = kmeans(data_norm.data,n_clust;maxiter=iterations)

        # save clustering results
        clustids = results.assignments
        centers_norm = results.centers
        centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)
        cost = results.totalcost
        iter = results.iterations
    end

    weights = calc_weights(clustids,n_clust)

    return centers,weights,clustids,cost,iter

end

"""
function run_clust_kmeans_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int
    )
"""
function run_clust_kmeans_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int
    )
    centers,weights,clustids,cost,iter =[],[],[],0,0
    # if only one cluster
    if n_clust ==1
        clustids = ones(Int,size(data_norm.data,2))
        centers_norm = calc_medoids(data_norm.data,clustids)
        centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids) # need to provide idx in case that sequence-based normalization is used
        cost = sum(pairwise(SqEuclidean(),centers_norm,data_norm.data)) #same as sum((seq_norm-repmat(mean(seq_norm,2),1,size(seq,2))).^2)
        iter = 1
    # kmeans() in Clustering.jl is implemented for k>=2
    else
        results = kmeans(data_norm.data,n_clust;maxiter=iterations)

        # save clustering results
        clustids = results.assignments
        centers_norm = calc_medoids(data_norm.data,clustids)
        centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)
        cost = calc_SSE(data_norm.data,centers_norm,clustids)
        iter = results.iterations
    end

    weights = calc_weights(clustids,n_clust)

    return centers,weights,clustids,cost,iter

end

"""
function run_clust_kmedoids_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int
    )
"""
function run_clust_kmedoids_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int
    )
    
    # TODO: optional in future: pass distance metric as kwargs
    dist = SqEuclidean()
    d_mat=pairwise(dist,data_norm.data)
    results = kmedoids(d_mat,n_clust;tol=1e-6,maxiter=iterations)
    clustids = results.assignments
    centers_norm = data_norm.data[:,results.medoids]
    centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)
    cost = results.totalcost
    iter = results.iterations

    weights = calc_weights(clustids,n_clust)
    
    return centers,weights,clustids,cost,iter
end

"""
function run_clust_kmedoids_exact_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    gurobi_env=0
    )
"""
function run_clust_kmedoids_exact_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    gurobi_env=0
    )
   
    (typeof(gurobi_env)==Int) && @error("Please provide a gurobi_env (Gurobi Environment). See test file for example")
    
    # TODO: optional in future: pass distance metric as kwargs
    dist = SqEuclidean()
    results = kmedoids_exact(data_norm.data,n_clust,gurobi_env;_dist=dist)#;distance_type_ar[dist])
    clustids = results.assignments
    centers_norm = results.medoids
    centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)
    cost = results.totalcost
    iter = 1

    weights = calc_weights(clustids,n_clust)
    
    return centers,weights,clustids,cost,iter
end

"""
function run_clust_hierarchical(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    _dist::SemiMetric = SqEuclidean()
    )

Helper function to run run_clust_hierarchical_centroids and run_clust_hierarchical_medoid
"""
function run_clust_hierarchical(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    _dist::SemiMetric = SqEuclidean()
    )

    d_mat=pairwise(_dist,data_norm.data)
    r=hclust(d_mat,linkage=:ward_presquared)
    clustids = cutree(r,k=n_clust)
    weights = calc_weights(clustids,n_clust)

    return [],weights,clustids,[],1
end

"""
function run_clust_hierarchical_centroid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    _dist::SemiMetric = SqEuclidean()
    )
"""
function run_clust_hierarchical_centroid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    _dist::SemiMetric = SqEuclidean()
    )
    ~,weights,clustids,~,iter= run_clust_hierarchical(data_norm,n_clust,iterations;_dist=_dist)
    centers_norm = calc_centroids(data_norm.data,clustids) 
    cost = calc_SSE(data_norm.data,centers_norm,clustids)
    centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)

    return centers,weights,clustids,cost,iter
end

"""
function run_clust_hierarchical_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    _dist::SemiMetric = SqEuclidean()
    )
"""
function run_clust_hierarchical_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    _dist::SemiMetric = SqEuclidean()
    )
    ~,weights,clustids,~,iter= run_clust_hierarchical(data_norm,n_clust,iterations;_dist=_dist)
    centers_norm = calc_medoids(data_norm.data,clustids) 
    cost = calc_SSE(data_norm.data,centers_norm,clustids)
    centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)

    return centers,weights,clustids,cost,iter
end

