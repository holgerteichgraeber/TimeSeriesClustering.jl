### Data structures ###
abstract type InputData end
abstract type TSData <:InputData end
abstract type OptData <: InputData end
abstract type AbstractClustResult end

struct FullInputData <: TSData
 region::String
 years::Array{Int,1}
 N::Int
 data::Dict{String,Array}
end

"""
      ClustData <: TSData

Contains time series data by attribute (e.g. wind, solar, electricity demand) and respective information.

Fields:
- region::String: optional information to specify the region data belongs to
- K::Int: number of periods
- T::Int: time steps per period
- data::Dict{String,Array}: Dictionary with an entry for each attribute `[file name (attribute: e.g technology)]-[column name (node: e.g. location)]`, Each entry of the dictionary is a 2-dimensional `time-steps T x periods K`-Array holding the data
- weights::Array{Float64,2}: 1-dimensional `periods K`-Array with the absolute weight for each period. The weight of a period corresponds to the number of days it representes. E.g. for a year of 365 days, sum(weights)=365
- mean::Dict{String,Array}: Dictionary with a entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 1-dimensional `periods K`-Array holding the shift of the mean. This is used internally for normalization.
- sdv::Dict{String,Array}:  Dictionary with an entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 1-dimensional `periods K`-Array holding the standard deviation. This is used internally for normalization.
- delta_t::Array{Float64,2}: 2-dimensional `time-steps T x periods K`-Array with the temporal duration Δt for each timestep. The default is that all timesteps have the same length.
- k_ids::Array{Int}: 1-dimensional `original periods I`-Array with the information, which original period is represented by which period K. E.g. if the data is a year of 365 periods, the array has length 365. If an original period is not represented by any period within this ClustData the entry will be `0`.
"""
struct ClustData <: TSData
 region::String
 years::Array{Int}
 K::Int
 T::Int
 data::Dict{String,Array}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
 delta_t::Array{Float64,2}
 k_ids::Array{Int}
end

"""
      ClustDataMerged <: TSData

Contains time series data by attribute (e.g. wind, solar, electricity demand) and respective information.

Fields:
- region::String: optional information to specify the region data belongs to
- K::Int: number of periods
- T::Int: time steps per period
- data::Array: Array of the dimension `(time-steps T * length(data_types)  x periods K`. The first T rows are data_type 1, the second T rows are data_type 2, ...
- data_type::Array{String}: The data types (attributes) of the data.
- weights::Array{Float64,2}: 1-dimensional `periods K`-Array with the absolute weight for each period. E.g. for a year of 365 days, sum(weights)=365
- mean::Dict{String,Array}: Dictionary with a entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 1-dimensional `periods K`-Array holding the shift of the mean
- sdv::Dict{String,Array}:  Dictionary with an entry for each attribute `[file name (e.g technology)]-[column name (e.g. location)]`, Each entry of the dictionary is a 1-dimensional `periods K`-Array holding the standard deviation
- delta_t::Array{Float64,2}: 2-dimensional `time-steps T x periods K`-Array with the temporal duration Δt for each timestep in [h]
- k_ids::Array{Int}: 1-dimensional `original periods I`-Array with the information, which original period is represented by which period K. If an original period is not represented by any period within this ClustData the entry will be `0`.
"""
struct ClustDataMerged <: TSData
 region::String
 years::Array{Int}
 K::Int
 T::Int
 data::Array
 data_type::Array{String}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
 delta_t::Array{Float64,2}
 k_ids::Array{Int}
end

"""
    ClustResult <: AbstractClustResult
Contains the results from a clustering run: The data, the cost in terms of the clustering algorithm, and a config file describing the clustering method used.

Fields:
- clust_data::ClustData
- cost::Float64: Cost of the clustering algorithm
- config::Dict{String,Any}: Details on the clustering method used
"""
struct ClustResult <: AbstractClustResult
 clust_data::ClustData
 cost::Float64
 config::Dict{String,Any}
end

"""
    ClustResultAll <: AbstractClustResult
Contains the results from a clustering run for all locally converged solutions

Fields:
- clust_data::ClustData: The best centers, weights, clustids in terms of cost of the clustering algorithm
- cost::Float64: Cost of the clustering algorithm
- config::Dict{String,Any}: Details on the clustering method used
- centers_all::Array{Array{Float64},1}
- weights_all::Array{Array{Float64},1}
- clustids_all::Array{Array{Int,1},1}
- cost_all::Array{Float64,1}
- iter_all::Array{Int,1}
"""
struct ClustResultAll <: AbstractClustResult
 clust_data::ClustData
 cost::Float64
 config::Dict{String,Any}
 centers_all::Array{Array{Float64},1}
 weights_all::Array{Array{Float64},1}
 clustids_all::Array{Array{Int,1},1}
 cost_all::Array{Float64,1}
 iter_all::Array{Int,1}
end

"""
    SimpleExtremeValueDescr

Defines a simple extreme day by its characteristics

Fields:

- data_type::String : Choose one of the attributes from the data you have loaded into ClustData
- extremum::String : `min`,`max`
- peak_def::String : `absolute`,`integral`
- consecutive_periods::Int: For a single extreme day, set as 1
"""
struct SimpleExtremeValueDescr
  # TODO: make this one constructor, with consecutive_periods as optional argument
   data_type::String
   extremum::String
   peak_def::String
   consecutive_periods::Int
   "Replace default constructor to only allow certain entries"
   function SimpleExtremeValueDescr(data_type::String,
                                    extremum::String,
                                    peak_def::String,
                                    consecutive_periods::Int)
       # only allow certain entries
       if !(extremum in ["min","max"])
         error("extremum - "*extremum*" - not defined")
       elseif !(peak_def in ["absolute","integral"])
         error("peak_def - "*peak_def*" - not defined")
       end
       new(data_type,extremum,peak_def,consecutive_periods)
   end
end

"""
    SimpleExtremeValueDescr(data_type::String,
                                 extremum::String,
                                 peak_def::String)

Defines a simple extreme day by its characteristics

Input options:
- data_type::String : Choose one of the attributes from the data you have loaded into ClustData
- extremum::String : `min`,`max`
- peak_def::String : `absolute`,`integral`
"""
function SimpleExtremeValueDescr(data_type::String,
                                 extremum::String,
                                 peak_def::String)
   return SimpleExtremeValueDescr(data_type, extremum, peak_def, 1)
end


#### Constructors for data structures###

"""
    ClustData(region::String,
                      years::Array{Int,1},
                      K::Int,
                      T::Int,
                      data::Dict{String,Array},
                      weights::Array{Float64},
                      delta_t::Array{Float64,2},
                      k_ids::Array{Int,1};
                      mean::Dict{String,Array}=Dict{String,Array}(),
                      sdv::Dict{String,Array}=Dict{String,Array}()
                      )
constructor 1 for ClustData: provide data as dict
"""
function ClustData(region::String,
                       years::Array{Int,1},
                       K::Int,
                       T::Int,
                       data::Dict{String,Array},
                       weights::Array{Float64},
                       k_ids::Array{Int,1};
                       delta_t::Array{Float64,2}=ones(T,K),
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
 ClustData(region,years,K,T,data,weights,mean,sdv,delta_t,k_ids)
end

"""
    ClustData(data::ClustDataMerged)
constructor 2: Convert ClustDataMerged to ClustData
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
constructor 3: Convert FullInputData to ClustData
"""
function ClustData(data::FullInputData,
                                 K::Int,
                                 T::Int)
  data_reshape = Dict{String,Array}()
  for (k,v) in data.data
     data_reshape[k] =  reshape(v,T,K)
  end
  return ClustData(data.region,data.years,K,T,data_reshape,ones(K),collect(1:K))
end

"""
    ClustDataMerged(region::String,
                        years::Array{Int,1},
                        K::Int,
                        T::Int,
                        data::Array,
                        data_type::Array{String},
                        weights::Array{Float64},
                        k_ids::Array{Int,1};
                        delta_t::Array{Float64,2}=ones(T,K),
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
constructor 1: construct ClustDataMerged
"""
function ClustDataMerged(region::String,
                       years::Array{Int,1},
                       K::Int,
                       T::Int,
                       data::Array,
                       data_type::Array{String},
                       weights::Array{Float64},
                       k_ids::Array{Int,1};
                       delta_t::Array{Float64,2}=ones(T,K),
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
   error("You cannot recluster data with different Δt")
 end
 ClustDataMerged(data.region,data.years,data.K,data.T,data_merged,data_type,data.weights,data.mean,data.sdv,data.delta_t,data.k_ids)
end
