### Data structures ###
abstract type ModelConfig end
abstract type InputData end
abstract type TSInputData <:InputData end
abstract type OptData <: InputData end
abstract type ClustResult end

"FullInputData"
struct FullInputData <: TSInputData
 region::String
 N::Int
 data::Dict{String,Array}
end

"ClustData \n weights: this is the absolute weight. E.g. for a year of 365 days, sum(weights)=365"
struct ClustData <: TSInputData
 region::String
 K::Int
 T::Int
 data::Dict{String,Array}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
end

"ClustDataMerged"
struct ClustDataMerged <: TSInputData
 region::String
 K::Int
 T::Int
 data::Array
 data_type::Array{String}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
end

"ClustResultAll"
struct ClustResultAll <: ClustResult
 best_results::ClustData
 best_ids::Array{Int,1}
 best_cost::Float64
 n_clust::Int
 data_type::Array{String}
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
  n_clust::Int
  data_type::Array{String}
end

"OptVariable"
struct OptVariable
 data::Array
 axes::Tuple{String,Array}
 type::String
end

"OptResult"
struct OptResult
 status::Symbol
 objective::Float64
 variables::Dict{String,OptVariable}
 model_set::Dict{String,Array}
 model_info::Array{String}
 opt_config::Dict{String,Any}
end

"""
struct OptDataCEP <: OptData
   region::String          name of state or region data belongs to
   nodes::DataFrame        nodes x installed capacity of different tech
   var_costs::DataFrame    tech x [USD, CO2]
   fix_costs::DataFrame    tech x [USD, CO2]
   cap_costs::DataFrame    tech x [USD, CO2]
   techs::DataFrame        tech x [categ,sector,lifetime,effic,fuel,annuityfactor]
   instead of USD you can also use your favorite currency like EUR
"""
struct OptDataCEP <: OptData
   region::String
   nodes::DataFrame
   var_costs::DataFrame
   fix_costs::DataFrame
   cap_costs::DataFrame
   techs::DataFrame
end

"""
struct OptModelCEP
  model::JuMP.Model
  info::Array{String}
  set::Dict{String,Array}
"""
struct OptModelCEP
  model::JuMP.Model
  info::Array{String}
  set::Dict{String,Array}
end


"""
struct Scenario
  name::String
  clust_res::ClustResult
  opt_res::OptResult
end
"""
struct Scenario
 name::String
 clust_res::ClustResult
 opt_res::OptResult
end


#### Constructors for data structures###
"""
function OptVariable(jumparray::JuMP.Array, type::String)
  Constructor for OptVariable taking JuMP Array and type (ov-operational variable or dv-decision variable)
"""
function OptVariable(jumparray::JuMP.Array,
                     type::String
                      )
OptVariable(jumparray.innerArray,jumparray.indexsets,type)
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
constructor 1 for ClustData: provide data individually

function ClustData(region::String,
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
function ClustData(region::String,
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
   ClustData(region,K,T,dt,weights,mean,sdv)
end

"""
constructor 2 for ClustData: provide data as dict

function ClustData(region::String,
                       K::Int,
                       T::Int,
                       data::Dict{String,Array};
                       mean::Dict{String,Array}=Dict{String,Array}(),
                       sdv::Dict{String,Array}=Dict{String,Array}()
                       )
"""
function ClustData(region::String,
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
 ClustData(region,K,T,data,weights,mean,sdv)
end

"""
constructor 3: Convert ClustDataMerged to ClustData

function ClustData(data::ClustDataMerged)
"""
function ClustData(data::ClustDataMerged)
 data_dict=Dict{String,Array}()
 i=0
 for (k,v) in data.mean
   i+=1
   data_dict[k] = data.data[(1+data.T*(i-1)):(data.T*i),:]
 end
 ClustData(data.region,data.K,data.T,data_dict,data.weights,data.mean,data.sdv)
end

"""
constructor 4: Convert FullInputData to ClustData
function ClustData(data::FullInputData,K,T)
"""
function ClustData(data::FullInputData,
                                 K::Int,
                                 T::Int)
  data_reshape = Dict{String,Array}()
  for (k,v) in data.data
     data_reshape[k] =  reshape(v,T,K)
  end
  return ClustData(data.region,K,T,data_reshape,ones(K))
end

"""
constructor 1: construct ClustDataMerged
function ClustDataMerged(region::String,
                       K::Int,
                       T::Int,
                       data::Array,
                       data_type::Array{String},
                       weights::Array{Float64};
                       mean::Dict{String,Array}=Dict{String,Array}(),
                       sdv::Dict{String,Array}=Dict{String,Array}()
                       )
"""
function ClustDataMerged(region::String,
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
 ClustDataMerged(region,K,T,data,data_type,weights,mean,sdv)
end

"""
constructor 2: convert ClustData into merged format

function ClustDataMerged(data::ClustData)
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
 ClustDataMerged(data.region,data.K,data.T,data_merged,data_type,data.weights,data.mean,data.sdv)
end
