### Data structures ###
abstract type InputData end
abstract type TSData <:InputData end
abstract type OptData <: InputData end
abstract type ClustResult end

"FullInputData"
struct FullInputData <: TSData
 region::String
 years::Array{Int64}
 N::Int
 data::Dict{String,Array}
end

"""
      ClustData{region::String,K::Int,T::Int,data::Dict{String,Array},weights::Array{Float64},mean::Dict{String,Array},sdv::Dict{String,Array}} <: TSData
- region: optional information to specify the region data belongs to
- K: number of periods
- T: time steps per period
- data: Dictionary with an entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 2-dimensional `time-steps T x periods K`-Array holding the actual value
- weights: 1-dimensional `periods K`-Array with the absolute weight for each period. E.g. for a year of 365 days, sum(weights)=365
- mean: Dictionary with a entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 1-dimensional `periods K`-Array holding the shift of the mean
- sdv:  Dictionary with an entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 1-dimensional `periods K`-Array holding the standard deviation
- delta_t: 2-dimensional `time-steps T x periods K`-Array with the temporal duration Δt for each timestep in [h]
- k_ids: 1-dimensional `original periods I`-Array with the information, which original period is represented by which period K. If an original period is not represented by any period within this ClustData the entry will be `0`.
"""
struct ClustData <: TSData
 region::String
 years::Array{Int64}
 K::Int
 T::Int
 data::Dict{String,Array}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
 delta_t::Array{Float64,2}
 k_ids::Array{Int64}
end

"ClustDataMerged"
struct ClustDataMerged <: TSData
 region::String
 years::Array{Int64}
 K::Int
 T::Int
 data::Array
 data_type::Array{String}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
 delta_t::Array{Float64,2}
 k_ids::Array{Int64}
end

"ClustResultAll"
struct ClustResultAll <: ClustResult
 best_results::ClustData
 best_ids::Array{Int,1}
 best_cost::Float64
 data_type::Array{String}
 clust_config::Dict{String,Any}
 centers::Array{Array{Float64},1}
 weights::Array{Array{Float64},1}
 clustids::Array{Array{Int,1},1}
 cost::Array{Float64,1}
 iter::Array{Int,1}
end

# TODO: not used yet, but maybe best to implement this one later for users who just want to use clustering but do not care about the locally converged solutions
"ClustResultBest"
struct ClustResultBest <: ClustResult
 best_results::ClustData
 best_ids::Array{Int,1}
 best_cost::Float64
 data_type::Array{String}
 clust_config::Dict{String,Any}
end

"ClustResultSimple"
struct ClustResultSimple <: ClustResult
 best_results::ClustData
 #TODO: clust_data::ClustData
 clust_config::Dict{String,Any}
end

"SimpleExtremeValueDescr"
struct SimpleExtremeValueDescr
   data_type::String
   extremum::String
   peak_def::String
   consecutive_periods::Int64
   "Replace default constructor to only allow certain entries"
   function SimpleExtremeValueDescr(data_type::String,
                                    extremum::String,
                                    peak_def::String,
                                    consecutive_periods::Int64)
       # only allow certain entries
       if !(extremum in ["min","max"])
         @error("extremum - "*extremum*" - not defined")
       elseif !(peak_def in ["absolute","integral"])
         @error("peak_def - "*peak_def*" - not defined")
       end
       new(data_type,extremum,peak_def,consecutive_periods)
   end
end

function SimpleExtremeValueDescr(data_type::String,
                                 extremum::String,
                                 peak_def::String)
   return SimpleExtremeValueDescr(data_type, extremum, peak_def, 1)
end


#### Constructors for data structures###

"""
    FullInputData(region::String,
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
 isempty(dt) && @error("Need to provide at least one input data stream")
 FullInputData(region,N,dt)
end

"""
  ClustData(region::String,
                         years::Array{Int64,1},
                         K::Int,
                         T::Int;
                         el_price::Array=[],
                         el_demand::Array=[],
                         solar::Array=[],
                         wind::Array=[],
                         weights::Array{Float64}=ones(K),
                         mean::Dict{String,Array}=Dict{String,Array}(),
                         sdv::Dict{String,Array}=Dict{String,Array}(),
                         delta_t::Array{Float64,2}=ones(T,K),
                         k_ids::Array{Int64,1}=collect(1:K)
                         )
constructor 1 for ClustData: provide data individually
"""
function ClustData(region::String,
                         years::Array{Int64,1},
                         K::Int,
                         T::Int;
                         el_price::Array=[],
                         el_demand::Array=[],
                         solar::Array=[],
                         wind::Array=[],
                         weights::Array{Float64}=ones(K),
                         mean::Dict{String,Array}=Dict{String,Array}(),
                         sdv::Dict{String,Array}=Dict{String,Array}(),
                         delta_t::Array{Float64,2}=ones(T,K),
                         k_ids::Array{Int64,1}=collect(1:K)
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
   isempty(dt) && @error("Need to provide at least one input data stream")
   # TODO: Check dimensionality of K T and supplied input data streams KxT
   ClustData(region,years,K,T,dt,weights,mean,sdv,delta_t,k_ids)
end

"""
    ClustData(region::String,
                      years::Array{Int64,1},
                      K::Int,
                      T::Int,
                      data::Dict{String,Array},
                      weights::Array{Float64},
                      delta_t::Array{Float64,2},
                      k_ids::Array{Int64,1};
                      mean::Dict{String,Array}=Dict{String,Array}(),
                      sdv::Dict{String,Array}=Dict{String,Array}()
                      )
constructor 2 for ClustData: provide data as dict
"""
function ClustData(region::String,
                       years::Array{Int64,1},
                       K::Int,
                       T::Int,
                       data::Dict{String,Array},
                       weights::Array{Float64},
                       delta_t::Array{Float64,2},
                       k_ids::Array{Int64,1};
                       mean::Dict{String,Array}=Dict{String,Array}(),
                       sdv::Dict{String,Array}=Dict{String,Array}()
                       )
 isempty(data) && @error("Need to provide at least one input data stream")
 mean_sdv_provided = ( !isempty(mean) && !isempty(sdv))
 if !mean_sdv_provided
   for (k,v) in data
     mean[k]=zeros(T)
     sdv[k]=ones(T)
   end
 end
 # TODO check if right keywords are used
 ClustData(region,years,K,T,data,weights,mean,sdv,delta_t,k_ids)
end

"""
    ClustData(data::ClustDataMerged)
constructor 3: Convert ClustDataMerged to ClustData
"""
function ClustData(data::ClustDataMerged)
 data_dict=Dict{String,Array}()
 i=0
 for k in data.data_type
   i+=1
   data_dict[k] = data.data[(1+data.T*(i-1)):(data.T*i),:]
 end
 ClustData(data.region,data.years,data.K,data.T,data_dict,data.weights,data.mean,data.sdv,data.delta_t,data.k_ids)
end

"""
    ClustData(data::FullInputData,K,T)
constructor 4: Convert FullInputData to ClustData
"""
function ClustData(data::FullInputData,
                                 K::Int,
                                 T::Int)
  data_reshape = Dict{String,Array}()
  for (k,v) in data.data
     data_reshape[k] =  reshape(v,T,K)
  end
  return ClustData(data.region,data.years,K,T,data_reshape,ones(K),ones(T,K),collect(1:K))
end

"""
    ClustDataMerged(region::String,
                        years::Array{Int64,1},
                        K::Int,
                        T::Int,
                        data::Array,
                        data_type::Array{String},
                        weights::Array{Float64},
                        k_ids::Array{Int64,1};
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
constructor 1: construct ClustDataMerged
"""
function ClustDataMerged(region::String,
                       years::Array{Int64,1},
                       K::Int,
                       T::Int,
                       data::Array,
                       data_type::Array{String},
                       weights::Array{Float64},
                       k_ids::Array{Int64,1};
                       delta_t::Array{Float64}=ones(T,K),
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
 ClustDataMerged(region,years,K,T,data,data_type,weights,mean,sdv,delta_t,k_ids)
end

"""
    ClustDataMerged(data::ClustData)
constructor 2: convert ClustData into merged format
"""
function ClustDataMerged(data::ClustData)
 n_datasets = length(keys(data.data))
 data_merged= zeros(data.T*n_datasets,data.K)
 data_type=String[]
 i=0
 for (k,v) in data.data
   i+=1
   data_merged[(1+data.T*(i-1)):(data.T*i),:] = v
   push!(data_type,k)
 end
 if maximum(data.delta_t)!=1
   throw(@error "You cannot recluster data with different Δt")
 end
 ClustDataMerged(data.region,data.years,data.K,data.T,data_merged,data_type,data.weights,data.mean,data.sdv,data.delta_t,data.k_ids)
end
