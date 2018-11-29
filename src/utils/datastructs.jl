 ### Data structures ###
abstract type InputData end
abstract type TSInputData <:InputData end
abstract type ModelInputData <: InputData end
abstract type ClustResult end

"FullInputData"
struct FullInputData <: TSInputData
  region::String
  N::Int
  data::Dict{String,Array}
end

"ClustInputData \n weights: this is the absolute weight. E.g. for a year of 365 days, sum(weights)=365"
struct ClustInputData <: TSInputData
  region::String
  K::Int
  T::Int
  data::Dict{String,Array}
  weights::Array{Float64}
  mean::Dict{String,Array}
  sdv::Dict{String,Array}
end

"ClustInputDataMerged"
struct ClustInputDataMerged <: TSInputData
  region::String
  K::Int
  T::Int
  data::Array
  data_types::Array{String}
  weights::Array{Float64}
  mean::Dict{String,Array}
  sdv::Dict{String,Array}
end

"ClustResultAll"
struct ClustResultAll <: ClustResult
  best_results::ClustInputData
  best_ids::Array{Int,1}
  best_cost::Float64
  n_clust::Int
  centers::Array{Array{Float64},1}
  data_types::Array{String}
  weights::Array{Array{Float64},1}
  clustids::Array{Array{Int,1},1}
  cost::Array{Float64,1}
  iter::Array{Int,1}
end

 # TODO: not used yet, but maybe best to implement this one later for users who just want to use clustering but do not care about the locally converged solutions
struct ClustResultBest <: ClustResult
  best_results::Array{ClustInputData}
  best_cost::Array
  best_ids::Array{Tuple{Int,Int}}
end

"SimpleExtremeValueDescr"
struct SimpleExtremeValueDescr
   data_type::String
   extremum::String
   peak_def::String
   "Replace default constructor to only allow certain entries"
   function SimpleExtremeValueDescr(data_type::String, 
                                    extremum::String,
                                    peak_def::String)
       # only allow certain entries 
       if !(extremum in ["min","max"])
         @error("extremum - "*extremum*" - not defined")  
       elseif !(peak_def in ["absolute","integral"])
         @error("peak_def - "*peak_def*" - not defined")  
       end
       new(data_type,extremum,peak_def) 
   end
end


"OptResult"
struct OptResult
  status::Symbol
  obj::Float64
  op_var::Dict{String,Any}
  des_var::Dict{String,Any}
  add_results::Dict
end

"""
struct CEPData <: ModelInputData
    nodes::DataFrame        nodes x installed capacity of different tech
    fixprices::DataFrame    tech x [EUR, CO2]
    varprices::DataFrame    tech x [EUR, CO2]
    techs::DataFrame        tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
"""
struct CEPData <: ModelInputData
    region::String
    nodes::DataFrame
    fix_costs::DataFrame
    var_costs::DataFrame
    techs::DataFrame
end

"""
mutable struct Scenario
  name::String
  clust_res::ClustResultAll
  opt_res::
"""
mutable struct Scenario
  name::String
  #QUESTION How to be general but not use Any
  clust_res::Any #ClustInputData or ClustResultAll
  opt_res::Any #OptResult or Nothing
end
 #### Constructors for data structures###

 # need to come afterwards because of cyclic argument between ClustInputData and ClustInputDataMerged Constructors
 """
   function Scenario(clust_res::ClustResultAll
 Constructor for FullInputData with optional data input
 """
 function Scenario(;clust_res=clust_res::ClustResultAll
                        )
  name=""
  opt_res=nothing
  Scenario(name,clust_res,opt_res)
end
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
  isempty(dt) && @error("Need to provide at least one input data stream")
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
    isempty(dt) && @error("Need to provide at least one input data stream")
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
  isempty(data) && @error("Need to provide at least one input data stream")
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
  for (k,v) in data.mean
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
function ClustInputDataMerged(region::String,
                        K::Int,
                        T::Int,
                        data::Array,
                        data_types::Array{String},
                        weights::Array{Float64};
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
"""
function ClustInputDataMerged(region::String,
                        K::Int,
                        T::Int,
                        data::Array,
                        data_types::Array{String},
                        weights::Array{Float64};
                        mean::Dict{String,Array}=Dict{String,Array}(),
                        sdv::Dict{String,Array}=Dict{String,Array}()
                        )
  mean_sdv_provided = ( !isempty(mean) && !isempty(sdv))
  if !mean_sdv_provided
    for dt in data_types
      mean[dt]=zeros(T)
      sdv[dt]=ones(T)
    end
  end

  ClustInputDataMerged(region,K,T,data,data_types,weights,mean,sdv)
end



"""
constructor 2: convert ClustInputData into merged format

function ClustInputDataMerged(data::ClustInputData)
"""
function ClustInputDataMerged(data::ClustInputData)
  n_datasets = length(keys(data.data))
  data_merged= zeros(data.T*n_datasets,data.K)
  data_types=String[]
  i=0
  for (k,v) in data.data
    i+=1
    data_merged[(1+data.T*(i-1)):(data.T*i),:] = v
    push!(data_types,k)
  end
  ClustInputDataMerged(data.region,data.K,data.T,data_merged,data_types,data.weights,data.mean,data.sdv)
end

