#


# convert Euro to US dollars
# introduced because the clusters generated by the python script are in EUR for GER
function get_EUR_to_USD(region::String)
   if region =="GER"
     ret = 1.109729
   else
     ret =1
   end
   return ret
end

function load_pricedata(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  if region =="CA"
    region_str = ""
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.txt"))
  elseif region == "GER"
    region_str = "GER_"
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.txt"))
  else
    error("Region ",region," not defined.")
  end
  data_orig = Array(readtable(region_data, separator = '\t', header = false))
  data_orig_daily = reshape(data_orig,24,365)
  cd(wor_dir) # change working directory to old previous file's dir
  return data_orig_daily
end #load_pricedata

# plot cluster centroids for verification
 # \TODO add more comments or delete this function
function plot_clusters(k_plot,kshape_centroids,n_k,n_init)

  for k=1:n_k

    # plot centroids for verification
    if k==k_plot
      figure()
      for i=1:n_init
        plot(kshape_centroids[k][:,:,i]',color="0.75")
      end
      #data = Array(readtable(normpath(joinpath(pwd(),"..","..","data",data_folder,string(region_str, "Elec_Price_kmeans_","kshape","_","cluster", "_", k,".txt"))), separator = '\t', header = false))/get_EUR_to_USD(region);
      #plot(data',color="red")
      best = kshape_centroids[k][:,:,ind_best_dist[k]]
      plot(best',color="blue")
    end
  end
  if is_linux()
    plt.show()
  end
end # plot_clusters()


  """
  function plot_clusters2()
  centers: hours x days e.g.[24x9] 

  """
function plot_clusters2(centers::Array,weights::Array;sorting::Bool=true,descr::String="")
   if sorting
     centers,weights = sort_centers(centers,weights) 
   end 
   figure()
   for i=1:size(centers,2) # number of clusters
     plot(centers[:,i],label=string("w=",round(weights[i]*100,2),"\%") )
   end
   ylim(-20,60)
   xlabel("hour")
   ylabel("EUR/MWh")
   title(descr)
   legend()
end #function

  """
  function sort_centers()
  centers: hours x days e.g.[24x9] 
  weights: days [e.g. 9], unsorted 
   sorts the centers by weights
  """
function sort_centers(centers::Array,weights::Array)
  i_w = sortperm(-weights)   # large to small (-)
  weights_sorted = weights[i_w]
  centers_sorted = centers[:,i_w]
  return centers_sorted, weights_sorted
end # function

##
# z-normalize data with mean and sdv by hour
# data: input format: (1st dimension: 24 hours, 2nd dimension: # of days)
# sequence: sequence based scaling - hourly is disregarded
#  hourly: true means univariate scaling: each hour is scaled seperately. False means one mean and standard deviation for the full data set.

function z_normalize(data;hourly=true,sequence=false)
  if sequence
    seq_mean = zeros(size(data)[2])
    seq_sdv = zeros(size(data)[2])
    data_norm = zeros(size(data)) 
    for i=1:size(data)[2]
      seq_mean[i] = mean(data[:,i])
      seq_sdv[i] = std(data[:,i])
      isnan(seq_sdv[i]) &&  (seq_sdv[i] =1)
      data_norm[:,i] = data[:,i] - seq_mean[i]
      data_norm[:,i] = data_norm[:,i]/seq_sdv[i]
    end
    return data_norm,seq_mean,seq_sdv
  else #no sequence
    hourly_mean = zeros(size(data)[1])
    hourly_sdv = zeros(size(data)[1])
    data_norm = zeros(size(data)) 
    if hourly # alternatively, use mean_and_std() and zscore() from StatsBase.jl
      for i=1:size(data)[1]
        hourly_mean[i] = mean(data[i,:])
        hourly_sdv[i] = std(data[i,:])
        isnan(hourly_sdv[i]) &&  (hourly_sdv[i] =1)
        data_norm[i,:] = data[i,:] - hourly_mean[i]
        data_norm[i,:] = data_norm[i,:]/hourly_sdv[i]
      end
    else # hourly = false
      hourly_mean = mean(data)*ones(size(data)[1])
      hourly_sdv = std(data)*ones(size(data)[1])
      data_norm = (data-hourly_mean[1])/hourly_sdv[1]
    end
    return data_norm, hourly_mean, hourly_sdv
  end
end # function z_normalize

##
# undo z-normalization data with mean and sdv by hour
# normalized data: input format: (1st dimension: 24 hours, 2nd dimension: # of days)
# hourly_mean ; 24 hour vector with hourly means
# hourly_sdv; 24 hour vector with hourly standard deviations

function undo_z_normalize(data_norm, mn, sdv; idx=[])
  if size(data_norm,1) == size(mn,1) # hourly
    data = data_norm .* sdv + mn * ones(size(data_norm)[2])'
    return data
  elseif !isempty(idx) && size(data_norm,2) == maximum(idx) # sequence based
    # we obtain mean and sdv for each day, but need mean and sdv for each centroid - take average mean and sdv for each cluster
    summed_mean = zeros(size(data_norm,2)) 
    summed_sdv = zeros(size(data_norm,2))
    for k=1:size(data_norm,2)
      mn_temp = mn[idx.==k]
      sdv_temp = sdv[idx.==k]
      summed_mean[k] = sum(mn_temp)/length(mn_temp) 
      summed_sdv[k] = sum(sdv_temp)/length(sdv_temp)
    end
    data = data_norm * Diagonal(summed_sdv) +  ones(size(data_norm,1)) * summed_mean'
    return data
  elseif isempty(idx)
    error("no idx provided in undo_z_normalize")
  end
end

# calculates the minimum and maximum allowed indices for a lxl windowed matrix
# for the sakoe chiba band (see Sakoe Chiba, 1978).
# Input: radius r, such that |i(k)-j(k)| <= r
# length l: dimension 2 of the matrix

function sakoe_chiba_band(r::Int,l::Int)
  i2min = Int[]
  i2max = Int[]
  for i=1:l
    push!(i2min,max(1,i-r))
    push!(i2max,min(l,i+r))
  end
  return i2min, i2max
end

 ### Plotting results ####
  """
  plot_k_rev(range_k::Array,rev::Array{Dict,1},region::String)
  The array rev contains Dicts with:  
    key: name of feature
    features:
      name ( of method)
      rev
      color
      linestyle
      width

  """
function plot_k_rev(range_k::Array,methods::Array{Dict,1},descr::String; save::Bool=true)
  figure()
  fsize_ref = 16
  for m in methods
    plot(range_k,m["rev"]/methods[1]["rev"][1],label=m["name"],color=m["color"],linestyle=m["linestyle"],lw=m["width"])
  end
  xlabel("Number of clusters",fontsize=fsize_ref)
  ylabel("Objective function value",fontsize=fsize_ref)
  legend(loc="lower right",fontsize=fsize_ref-4,ncol=2)
  ax = axes()
  ax[:tick_params]("both",labelsize=fsize_ref-1)
  xticks(range_k,range_k)
  tight_layout()
  ylim((0.5,1.05)) # 1.05
  save && savefig(descr,format="png",dpi=300)
end #plot_k_rev


function plot_SSE_rev(range_k::Array,cost_rev_clouds::Dict,cost_rev_points::Array{Dict,1},descr::String,rev_365::Float64;n_col::Int=2, save::Bool=true)
  figure()
  fsize_ref = 16
  for i=1:length(range_k)
    ii= length(range_k)-i+1
    if typeof(cost_rev_clouds["rev"]) == Array{Array{Float64,1},1} # exceptional case for kshape
      plot(cost_rev_clouds["cost"][ii],cost_rev_clouds["rev"][ii]/rev_365,".",label=string("k=",range_k[ii]),alpha=0.2)
    else # normal case 
      plot(cost_rev_clouds["cost"][ii,:],cost_rev_clouds["rev"][ii,:]/rev_365,".",label=string("k=",range_k[ii]),alpha=0.2)
    end
  end
  for i=1:length(cost_rev_points)
    for j=1:length(range_k)
      if j==1
        plot(cost_rev_points[i]["cost"][j,:],cost_rev_points[i]["rev"][j,:]/rev_365,mec=cost_rev_points[i]["mec"],marker=cost_rev_points[i]["marker"],mew=cost_rev_points[i]["mew"],markerfacecolor="none",linestyle="none",label=cost_rev_points[i]["label"])
      else 
        plot(cost_rev_points[i]["cost"][j,:],cost_rev_points[i]["rev"][j,:]/rev_365,mec=cost_rev_points[i]["mec"],marker=cost_rev_points[i]["marker"],mew=cost_rev_points[i]["mew"],markerfacecolor="none",linestyle="none",label=nothing)  # nothing instead of None # mew: markeredgewidth
      end # if
    end
  end
  plot(0.0,1.0,marker="*",ms=10,linestyle="none",color="c",label="Full representation")
  legend(fontsize=fsize_ref-4,ncol=n_col)
  xlabel("Clustering measure (SSE)",fontsize=fsize_ref)
  ylabel("Objective function value",fontsize=fsize_ref)
  ax = axes()
  ax[:tick_params]("both",labelsize=fsize_ref-1)
  tight_layout()
  xlim((9500,-120))
  ylim((0.5,1.05))
  save && savefig(descr,format="png",dpi=300)
end # plot_SSE_rev

