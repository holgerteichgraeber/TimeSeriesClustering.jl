### Data structures ###
abstract type InputData end
abstract type TSData <:InputData end
abstract type OptData <: InputData end
abstract type ClustResult end

"FullInputData"
struct FullInputData <: TSData
 region::String
 N::Int
 data::Dict{String,Array}
end

"ClustData \n weights: this is the absolute weight. E.g. for a year of 365 days, sum(weights)=365"
struct ClustData <: TSData
 region::String
 K::Int
 T::Int
 data::Dict{String,Array}
 weights::Array{Float64}
 mean::Dict{String,Array}
 sdv::Dict{String,Array}
end

"ClustDataMerged"
struct ClustDataMerged <: TSData
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

"""
struct OptVariable
  data::Array - includes the optimization variable output in  form of an array
  axes::Tuple - includes the values of the different axes of the optimization variables
  type::String - defines the type of the variable being cv- Cost variable, dv - decision variable or ov - operation variable
"""
struct OptVariable
 data::Array
 axes::Tuple
 type::String
end

"""
function OptVariable(jumparray::JuMP.Array, type::String)
  Constructor for OptVariable taking JuMP Array and type (ov-operational variable or dv-decision variable)
"""
function OptVariable(jumparray::JuMP.JuMPArray,
                     type::String
                      )
  OptVariable(jumparray.innerArray,jumparray.indexsets,type)
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
 objective::Float64
 variables::Dict{String,OptVariable}
 model_set::Dict{String,Array}
 model_info::Array{String}
 opt_config::Dict{String,Any}
end

"""
struct OptDataCEP <: OptData
   region::String          name of state or region data belongs to
   nodes::DataFrame        nodes x region, infrastruct, capacity_of_different_tech...
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
   lines::DataFrame
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
  descriptor::String
  clust_res::ClustResult
  opt_res::OptResult
end
"""
struct Scenario
 descriptor::String
 clust_res::ClustResult
 opt_res::OptResult
end


#### Constructors for data structures###

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
function ClustData_individual(data::ClustData)

Takes a ClustData struct and returns an array of ClustData structs that contains each period individually.
"""
function clustData_individual(data::ClustData)
  clust_data_indiv = ClustData[]
  for kk=1:data.K
    # initialize new dict
    data_dict_indiv = Dict{String,Array}()
    # fill dict with data
    for (k,v) in data.data
      data_dict_indiv[k] = v[:,kk:kk]  # kk:kk instead of k ensures that it returns a two-dimensional array instead of a vector during array slicing with singleton dimension
    end
    push!(clust_data_indiv,ClustData(data.region,1,data.T,data_dict_indiv,[data.weights[kk]];mean=data.mean,sdv=data.sdv))    
  end
  return clust_data_indiv
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

"""
function ClustResult(clust_res::ClustResultBest,clust_data_mod::ClustData)

adjusts ClustResult best_results. To be used to modify clustered data with extreme values.
"""
function ClustResult(clust_res::ClustResultBest,clust_data_mod::ClustData)
  return ClustResultBest(clust_data_mod,clust_res.best_ids,clust_res.best_cost,clust_res.data_type,clust_res.clust_config)
end

"""
function ClustResult(clust_res::ClustResultAll,clust_data_mod::ClustData)

adjusts ClustResult best_results. To be used to modify clustered data with extreme values.
"""
function ClustResult(clust_res::ClustResultAll,clust_data_mod::ClustData)
  return ClustResultAll(clust_data_mod,clust_res.best_ids,clust_res.best_cost,clust_res.data_type,clust_res.clust_config,clust_res.centers,clust_res.weights,clust_res.clustids,clust_res.cost,clust_res.iter)
end
