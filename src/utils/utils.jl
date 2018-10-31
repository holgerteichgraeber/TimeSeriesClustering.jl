#

 ### Data structures ###
abstract type InputData end
abstract type ClustResult end

"""
struct FullInputData <: InputData 
  region::String 
  N::Int
  el_price::Array
  el_demand::Array
  solar::Array
  wind::Array
"""
struct FullInputData <: InputData 
  region::String
  N::Int
  data::Dict{String,Array}
end

struct ClustInputData <: InputData 
  region::String
  K::Int
  T::Int
  data::Dict{String,Array}
  weights::Array{Float64}
  mean::Dict{String,Array}
  sdv::Dict{String,Array}

end

struct ClustInputDataMerged <: InputData
  region::String
  K::Int
  T::Int
  data::Array
  data_type::Array{String}
  weights::Array{Float64} 
  mean::Dict{String,Array}
  sdv::Dict{String,Array}
end

struct ClustResultAll <: ClustResult 
  best_results::Array{ClustInputData}
  best_ids::Array{Array}
  best_cost::Array
  n_clust_ar::Array
  centers::Dict{Tuple{Int,Int},Array}
  weights::Dict{Tuple{Int,Int},Array}
  clustids::Dict{Tuple{Int,Int},Array}
  cost::Array
  iter::Array
end

 # TODO: not used yet, but maybe best to implement this one later for users who just want to use clustering but do not care about the locally converged solutions
struct ClustResultBest <: ClustResult
  best_results::Array{ClustInputData}
  best_cost::Array
  best_ids::Array{Tuple{Int,Int}}
end

 #### Constructors for data structures###

 # need to come afterwards because of cyclic argument between ClustInputData and ClustInputDataMerged Constructors

"""
  function FullInputData(region::String,
                         N::Int;
                         el_price::Array=[],
                         el_demand::Array=[],
                         solar::Array=[],
                         wind::Array=[]
                         )
Constructor for FullInputData with optional data input
"""
function FullInputData(region::String,
                       N::Int;
                       el_price::Array=[],
                       el_demand::Array=[],
                       solar::Array=[],
                       wind::Array=[]
                       )
  dt = Dict{String,Array}() 
  !isempty(el_price) && (dt["el_price"]=el_price)
  !isempty(el_demand) &&  (dt["el_demand"]=el_demand)
  !isempty(wind) && (dt["wind"]=wind)
  !isempty(solar) && (dt["solar"]=solar)
  # TODO: Check dimensionality of N and supplied input data streams Nx1
  isempty(dt) && error("Need to provide at least one input data stream") 
  FullInputData(region,N,dt)
end



"""
constructor 1 for ClustInputData: provide data individually

function ClustInputData(region::String,
                          K::Int,
                          T::Int;
                          el_price::Array=[],
                          el_demand::Array=[],
                          solar::Array=[],
                          wind::Array=[],
                          mean::Dict{String,Array}=Dict{String,Array}(),
                          sdv::Dict{String,Array}=Dict{String,Array}()
                          )
"""
function ClustInputData(region::String,
                          K::Int,
                          T::Int;
                          el_price::Array=[],
                          el_demand::Array=[],
                          solar::Array=[],
                          wind::Array=[],
                          weights::Array{Float64}=ones(K),
                          mean::Dict{String,Array}=Dict{String,Array}(),
                          sdv::Dict{String,Array}=Dict{String,Array}()
                          )
    dt = Dict{String,Array}() 
    mean_sdv_provided = ( !isempty(mean) && !isempty(sdv))
    if !isempty(el_price) 
      dt["el_price"]=el_price
      if !mean_sdv_provided
        mean["el_price"]=zeros(T)
        sdv["el_price"]=ones(T)
      end
    end
    if !isempty(el_demand)
      dt["el_demand"]=el_demand
      if !mean_sdv_provided
        mean["el_demand"]=zeros(T)
        sdv["el_demand"]=ones(T)
      end
    end 
    if !isempty(wind) 
      dt["wind"]=wind
      if !mean_sdv_provided
        mean["wind"]=zeros(T)
        sdv["wind"]=ones(T)
      end
    end
    if !isempty(solar) 
      dt["solar"]=solar
      if !mean_sdv_provided
        mean["solar"]=zeros(T)
        sdv["solar"]=ones(T)
      end
    end
    isempty(dt) && error("Need to provide at least one input data stream")
    # TODO: Check dimensionality of K T and supplied input data streams KxT
    ClustInputData(region,K,T,dt,weights,mean,sdv)
end

 
"""
constructor 2 for ClustInputData: provide data as dict

function ClustInputData(region::String,
                        K::Int,
                        T::Int,
                        data::Dict{String,Array};
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
"""
function ClustInputData(region::String,
                        K::Int,
                        T::Int,
                        data::Dict{String,Array},
                        weights::Array{Float64};
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
  isempty(data) && error("Need to provide at least one input data stream")
  mean_sdv_provided = ( !isempty(mean) && !isempty(sdv))
  if !mean_sdv_provided
    for (k,v) in data
      mean[k]=zeros(T)
      sdv[k]=ones(T)
    end
  end
  # TODO check if right keywords are used
  ClustInputData(region,K,T,data,weights,mean,sdv)
end

"""
constructor 3: Convert ClustInputDataMerged to ClustInputData

function ClustInputData(data::ClustInputDataMerged)
"""
function ClustInputData(data::ClustInputDataMerged)
  data_dict=Dict{String,Array}()
  i=0
  for (k,v) in data.data
    i+=1
    data_dict[k] = data.data[(1+data.T*(i-1)):(data.T*i),:]
  end
  ClustInputData(data.region,data.K,data.T,data_dict,data.weights,data.mean,data.sdv)
end

"""
constructor 4: Convert FullInputData to ClustInputData
function ClustInputData(data::FullInputData,K,T)
"""
function ClustInputData(data::FullInputData,
                                  K::Int,
                                  T::Int)
   data_reshape = Dict{String,Array}()
   for (k,v) in data.data
      data_reshape[k] =  reshape(v,T,K)
   end
   return ClustInputData(data.region,K,T,data_reshape,ones(K))
end

"""
constructor 1: construct ClustInputDataMerged
"""
function ClustInputDataMerged(region::String,
                        K::Int,
                        T::Int,
                        data::Array,
                        data_type::Array{String},
                        weights::Array{Float64};
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
  mean_sdv_provided = ( !isempty(mean) && !isempty(sdv))
  if !mean_sdv_provided
    for dt in data_type
      mean[dt]=zeros(T)
      sdv[dt]=ones(T)
    end
  end

  ClustInputDataMerged(region,K,T,data,data_type,weights,mean,sdv)
end



"""
constructor 2: convert ClustInputData into merged format

function ClustInputDataMerged(data::ClustInputData)
"""
function ClustInputDataMerged(data::ClustInputData)
  n_datasets = length(keys(data.data))
  data_merged= zeros(data.T*n_datasets,data.K)
  data_type=String[]
  i=0
  for (k,v) in data.data
    i+=1
    data_merged[(1+data.T*(i-1)):(data.T*i),:] = v 
    push!(data_type,k)
  end
  ClustInputDataMerged(data.region,data.K,data.T,data_merged,data_type,data.weights,data.mean,data.sdv)
end


 #### Other Functions ####  
  
"""
function get_EUR_to_USD(region::String)

  convert Euro to US dollars
  introduced because the clusters generated by the python script are in EUR for GER
"""
function get_EUR_to_USD(region::String)
   if region =="GER"
     ret = 1.109729
   else
     ret =1
   end
   return ret
end

"""
function load_pricedata(region::String)

Loads price data from either GER or CA    
"""
function load_pricedata(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  if region =="CA" #\$/MWh
    region_str = ""
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.txt"))
  elseif region == "GER" #EUR/MWh
    region_str = "GER_"
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.txt"))
  else
    error("Region ",region," not defined.")
  end
  data_orig = Array(readtable(region_data, separator = '\t', header = false))
  data_full = FullInputData(region,size(data_orig)[1];el_price=data_orig)
  data_reshape =  ClustInputData(data_full,365,24)
  cd(wor_dir) # change working directory to old previous file's dir
  return data_reshape, data_full
end #load_pricedata

"""
function load_capacity_expansion_data(region::String)

outputs one dict with the following keys. They each contain a 24x365 array:
eldemand [GW]
solar availability [-]
wind availability [-]
"""
function load_capacity_expansion_data(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  
  N=nothing # initialize 
  demand=nothing
  solar=nothing
  wind=nothing  
  if region == "TX"
    # Texas system data from Merrick (Energy Economics) and Merrick (MS thesis) 
    #demand - [GW]
    demand= Array(readtable(normpath(joinpath(pwd(),"..","..","data","texas_merrick","demand.txt")),separator=' ')[:DEM]) # MW
    demand=reshape(demand,(size(demand)[1],1))
     # load growth (Merrick assumption)
    demand=1.486*demand
    demand=demand/1000 # GW
    N=size(demand)[1]
    # solar availability factor
    solar= Array(readtable(normpath(joinpath(pwd(),"..","..","data","texas_merrick","TexInsolationFactorV1.txt")),separator=' ')[:solar_61])
    solar=reshape(solar,(size(solar)[1],1))
    solar = solar/1000
   # wind availability factor
    wind= Array(readtable("/home/hteich/.julia/v0.6/ClustForOpt_priv/data/texas_merrick/windfactor2.txt",separator=' ')[:Wind_61])
    wind=reshape(wind,(size(wind)[1],1))
  else
    error("region "*region*" not implemented.")
  end # region
  
  data_full = FullInputData(region,N;el_demand=demand,solar=solar,wind=wind)
  data_reshape =  ClustInputData(data_full,365,24)
  
  cd(wor_dir) # change working directory to old previous file's dir
  return data_reshape,data_full 

 # TODO - add CA data
 # TODO - add multiple nodes data
end

"""
function load_input_data(application::String,region::String)

wrapper function to call capacity expansion data and price data

applications:
- DAM - electricity day ahead market prices
- CEP - capacity expansion problem data

potential outputs:
- elprice [electricity price]
- wind
- solar 
- eldemand [electricity demand]
  
  
"""
function load_input_data(application::String,region::String)
  ret=nothing
  if application == "DAM"
    ret=load_pricedata(region)
  elseif application == "CEP"
    ret= load_capacity_expansion_data(region)
  else
    error("application "*application*" not defined")
  end
  #check if output is of the right format
  if typeof(ret) != Tuple{ClustInputData,FullInputData}
    error("Output from load_input_data needs to be of ClustInputData,FullInputData") 
  end
  return ret
end

  """
function sort_centers(centers::Array,weights::Array)
 
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

"""
function z_normalize(data::Dict;scope="full")
"""
function z_normalize(data::ClustInputData;scope="full")
 data_norm = Dict{String,Array}()
 mean= Dict{String,Array}()
 sdv= Dict{String,Array}()
 for (k,v) in data.data
   data_norm[k],mean[k],sdv[k] = z_normalize(v,scope=scope)
 end
 return ClustInputData(data.region,data.K,data.T,data_norm,data.weights;mean=mean,sdv=sdv) 
end


"""
function z_normalize(data;scope="full")

z-normalize data with mean and sdv by hour

data: input format: (1st dimension: 24 hours, 2nd dimension: # of days)
scope: "full": one mean and sdv for the full data set; "hourly": univariate scaling: each hour is scaled seperately; "sequence": sequence based scaling
"""
function z_normalize(data::Array;scope="full")
  if scope == "sequence"
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
  elseif scope == "hourly"
    hourly_mean = zeros(size(data)[1])
    hourly_sdv = zeros(size(data)[1])
    data_norm = zeros(size(data)) 
    for i=1:size(data)[1]
      hourly_mean[i] = mean(data[i,:])
      hourly_sdv[i] = std(data[i,:])
      isnan(hourly_sdv[i]) &&  (hourly_sdv[i] =1)
      data_norm[i,:] = data[i,:] - hourly_mean[i]
      data_norm[i,:] = data_norm[i,:]/hourly_sdv[i]
    end
    return data_norm, hourly_mean, hourly_sdv
  elseif scope == "full"
    hourly_mean = mean(data)*ones(size(data)[1])
    hourly_sdv = std(data)*ones(size(data)[1])
    data_norm = (data-hourly_mean[1])/hourly_sdv[1]
    return data_norm, hourly_mean, hourly_sdv #TODO change the output here to an immutable struct with three fields - use struct - "composite type"
  else
    error("scope _ ",scope," _ not defined.")
  end
end # function z_normalize

"""
function undo_z_normalize(data_norm, mn, sdv; idx=[])

undo z-normalization data with mean and sdv by hour
normalized data: input format: (1st dimension: 24 hours, 2nd dimension: # of days)
hourly_mean ; 24 hour vector with hourly means
hourly_sdv; 24 hour vector with hourly standard deviations
"""
function undo_z_normalize(data_norm::Array, mn::Array, sdv::Array; idx=[])
  if size(data_norm,1) == size(mn,1) # hourly - even if idx is provided, doesn't matter if it is hourly
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

"""
function sakoe_chiba_band(r::Int,l::Int)

calculates the minimum and maximum allowed indices for a lxl windowed matrix
for the sakoe chiba band (see Sakoe Chiba, 1978).
Input: radius r, such that |i(k)-j(k)| <= r
length l: dimension 2 of the matrix
"""
function sakoe_chiba_band(r::Int,l::Int)
  i2min = Int[]
  i2max = Int[]
  for i=1:l
    push!(i2min,max(1,i-r))
    push!(i2max,min(l,i+r))
  end
  return i2min, i2max
end

"""
function calc_SSE(data::Array,centers::Array,assignments::Array)

calculates Sum of Squared Errors between cluster representations and the data
"""
function calc_SSE(data::Array,centers::Array,assignments::Array)
  k=size(centers,2) # number of clusters
  n_periods =size(data,2)  
  SSE_sum = zeros(k)
  for i=1:n_periods
    SSE_sum[assignments[i]] += sqeuclidean(data[:,i],centers[:,assignments[i]])
  end 
  return sum(SSE_sum)
end # calc_SSE 

"""
function find_medoids(data::Array,centers::Array,assignments::Array)

Given the data and cluster centroids and their respective assignments, this function finds
the medoids that are closest to the cluster center. 
"""
function find_medoids(data::Array,centers::Array,assignments::Array)
  k=size(centers,2) #number of clusters
  n_periods =size(data,2)  
  SSE=Float64[]
  for i=1:k
    push!(SSE,Inf)
  end
  medoids=zeros(centers)
  for i=1:n_periods
    d = sqeuclidean(data[:,i],centers[:,assignments[i]])
    if d < SSE[assignments[i]]
      medoids[:,assignments[i]] = data[:,i]
    end
  end
  return medoids
end

"""
function resize_medoids(data::Array,centers::Array,weights::Array,assignments::Array)

Takes in centers (typically medoids) and normalizes them such that for all clusters the average of the cluster is the same as the average of the respective original data that belongs to that cluster.

In order to use this method of the resize function, add assignments to the function call (e.g. clustids[5,1]).  
"""
function resize_medoids(data::Array,centers::Array,weights::Array,assignments::Array)
    new_centers = zeros(centers)
    for k=1:size(centers)[2] # number of clusters
       is_in_k = assignments.==k
       n = sum(is_in_k)
       new_centers[:,k]=resize_medoids(reshape(data[:,is_in_k],:,n),reshape(centers[:,k] , : ,1),[1.0])# reshape is used for the side case with only one vector, so that resulting vector is 24x1 instead of 24-element 
    end
    return new_centers
end


"""
function resize_medoids(data::Array,centers::Array,weights::Array)

Takes in centers (typically medoids) and normalizes them such that the yearly average of the clustered data is the same as the yearly average of the original data.
"""
function resize_medoids(data::Array,centers::Array,weights::Array)
    mu_data = sum(data)
    mu_clust = 0
    for k=1:size(centers)[2]
      mu_clust += weights[k]*sum(centers[:,k]) # 0<=weights<=1
    end
    mu_clust *= size(data)[2]
    mu_data_mu_clust = mu_data/mu_clust
    new_centers = centers* mu_data_mu_clust 
    #println(mu_data_mu_clust)
    return new_centers 
end

