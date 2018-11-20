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

