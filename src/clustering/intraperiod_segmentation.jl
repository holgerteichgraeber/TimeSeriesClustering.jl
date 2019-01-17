
function intraperiod_segmentation(data_merged::ClustDataMerged;
                n_seg::Int=24,
                iterations::Int=300,
                norm_scope::String="full")
  #For easy access
  K=data_merged.K
  T=data_merged.T
  data=data_merged.data
  #Prepare matrices
  data_seg=zeros(n_seg*length(data_merged.data_type),K)
  deltas_seg=zeros(n_seg,K)
  #Loop over each period
  for k in 1:K
    #Take single period and reshape it to have t (1:T) as columns and types (solar-germany, wind-germany...) as rows
    period=permutedims(reshape(data[:,k],(T,length(data_merged.data_type))))
    #Run hierarchical clustering
    centers,weights,clustids,cost,iter=run_clust_segmentation(period;n_seg=n_seg,iterations=iterations,norm_scope=norm_scope)
    #Assign values back to matrices to match types*n_seg x K
    data_seg[:,k]=reshape(permutedims(centers),(size(data_seg,1),1))
    #Assign values back to matrices to match n_seg x K
    deltas_seg[:,k]=weights
  end
  return ClustDataMerged(data_merged.region,K,n_seg,data_seg,data_merged.data_type,data_merged.weights,deltas_seg)
end

function run_clust_segmentation(period::Array{Float64,2};
                n_seg::Int=24,
                iterations::Int=300,
                norm_scope::String="full")
  norm_period, typely_mean, typely_sdv=z_normalize(period;scope=norm_scope)
  x,weights,clustids,x,iter= run_clust_hierarchical(norm_period,n_seg,iterations)
  centers_norm = calc_centroids(norm_period,clustids)
  cost = calc_SSE(norm_period,centers_norm,clustids)
  centers = undo_z_normalize(centers_norm,typely_mean,typely_sdv;idx=clustids)
  return centers,weights,clustids,cost,iter
end
