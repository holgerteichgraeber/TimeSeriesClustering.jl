"""
    simple_extr_val_sel(data::ClustData,
                        extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                        rep_mod_method::String="feasibility")
Selects simple extreme values and returns modified data, extreme values, and the corresponding indices.
"""
function simple_extr_val_sel(data::ClustData,
                             extr_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )
  idcs = simple_extr_val_ident(data,extr_value_descr_ar)
  extr_vals = extreme_val_output(data,idcs;rep_mod_method=rep_mod_method)
  # for append method: modify data to be clustered to only contain the values that are not extreme values
  if rep_mod_method=="feasibility"
    data_mod = data
  elseif rep_mod_method=="append"
    data_mod = input_data_modification(data,idcs)
  else
    @error("rep_mod_method - "*rep_mod_method*" - does not exist")
  end
  return data_mod,extr_vals,idcs
end

"""
    simple_extr_val_sel(data::ClustData,
                        extreme_value_descr_ar::SimpleExtremeValueDescr;
                        rep_mod_method::String="feasibility")
Wrapper function for only one simple extreme value.
Selects simple extreme values and returns modified data, extreme values, and the corresponding indices.
"""
function simple_extr_val_sel(data::ClustData,
                             extr_value_descr::SimpleExtremeValueDescr;
                             rep_mod_method::String="feasibility"
                             )
  return simple_extr_val_sel(data,[extr_value_descr];rep_mod_method=rep_mod_method)
end

"""
    simple_extr_val_ident(data::ClustData,extreme_value_descr::Array{SimpleExtremeValueDescr,1})
identifies multiple simple extreme values from the data and returns array of column indices of extreme value within data
- data_type: any attribute from the attributes contained within *data*
- extremum: "min" or "max"
- peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustData,
                               extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1})
  idcs = Array{Int,1}()
  # for each desired extreme value description, finds index of that extreme value within data
  for i=1:length(extreme_value_descr_ar)
    append!(idcs,simple_extr_val_ident(data,extreme_value_descr_ar[i]))
  end
  return idcs
end

"""
    simple_extr_val_ident(data::ClustData,extreme_value_descr::SimpleExtremeValueDescr)
Wrapper function for only one simple extreme value:
identifies a single simple extreme value from the data and returns column index of extreme value
- `data_type`: any attribute from the attributes contained within *data*
- `extremum`: "min" or "max"
- `peak_def`: "absolute" or "integral"
- `consecutive_periods`: number of consecutive_periods combined to analyze
"""
function simple_extr_val_ident(data::ClustData,
                               extreme_value_descr::SimpleExtremeValueDescr)
  return simple_extr_val_ident(data, extreme_value_descr.data_type; extremum=extreme_value_descr.extremum, peak_def=extreme_value_descr.peak_def, consecutive_periods=extreme_value_descr.consecutive_periods)
end

"""
    simple_extr_val_ident(data::Array{Float64};extremum="max",peak_def="absolute")
identifies a single simple extreme period from the data and returns column index of extreme period
- `data_type`: any attribute from the attributes contained within *data*
- `extremum`: "min" or "max"
- `peak_def`: "absolute" or "integral"
- `consecutive_periods`: The number of consecutive periods that are summed to identify a maximum or minimum. A rolling approach is used: E.g. for a value of `consecutive_periods`=2: 1) 1st & 2nd periods summed, 2) 2nd & 3rd period summed, 3) 3rd & 4th ... The min/max of the 1), 2), 3)... is determined and the two periods indices, where the  min/max were identified, are returned
"""
function simple_extr_val_ident(clust_data::ClustData,
                               data_type::String;
                               extremum::String="max",
                               peak_def::String="absolute",
                               consecutive_periods::Int64=1)
  data=clust_data.data[data_type]
  delta_period=consecutive_periods-1
  # set data to be compared
  if peak_def=="absolute" && consecutive_periods==1
      data_eval = data
  elseif peak_def=="integral"
    # The number of consecutive_periods is substracted by one as k:k+period
    data_eval=zeros(1,(size(data,2)-delta_period))
    for k in 1:(size(data,2)-delta_period)
      data_eval[1,k] = sum(data[:,k:(k+delta_period)])
    end
  else
    @error("peak_def - "*peak_def*" and consecutive_periods $consecutive_periods - not defined")
  end
  # find minimum or maximum index. Second argument returns cartesian indices, second argument of that is the column (period) index
  if extremum=="max"
    idx_k = findmax(data_eval)[2][2]
  elseif extremum=="min"
    idx_k = findmin(data_eval)[2][2]
  else
    @error("extremum - "*extremum*" - not defined")
  end
  idx=collect(idx_k:(idx_k+delta_period))
  return idx
end

"""
    input_data_modification(data::ClustData,extr_val_idcs::Array{Int,1})
returns ClustData structs with extreme vals and with remaining input data [data-extreme_vals].
Gives extreme vals the weight that they had in data.
This function is needed for the append method for representation modification
! the k-ids have to be monoton increasing - don't modify clustered data !
"""
function input_data_modification(data::ClustData,extr_val_idcs::Array{Int,1})
  unique_extr_val_idcs = unique(extr_val_idcs)
  K_dn = data.K- length(unique_extr_val_idcs)
  data_dn=Dict{String,Array}()
  index=setdiff(1:data.K,extr_val_idcs)
  for dt in keys(data.data)
    data_dn[dt] = data.data[dt][:,index] #take all columns but the ones that are extreme vals. If index occurs multiple times, setdiff only treats it as one.
  end
  weights_dn = data.weights[index]
  #take all columns but the ones that are extreme vals
  deltas_dn= data.delta_t[:,index]
  #deepcopy to change k_ids
  k_ids_dn=deepcopy(data.k_ids)
  #check for uniqueness and right sorting (however just those one representing)
  k_ids_check=k_ids_dn[findall(k_ids_dn.!=0)]
  allunique(k_ids_check) || @error "the provided clust_data.k_ids are not unique - The clust_data is probably the result of a clustering already."
  sort(k_ids_check)==k_ids_check || @error "the provided clust_data.k_ids are not monoton increasing - The clust_data is probably the result of a clustering already."
  #get all k-ids that are represented within this clust-data
  k_ids_dn_data=k_ids_dn[findall(data.k_ids.!=0)]
  for k in sort(extr_val_idcs)
    #reduce the following k_ids by one for all of the following k-ids (the deleted column will reduce the following column-indices by one for each deleted column)
    k_ids_dn_data[k:end].-=1
    #set this k_id to zero, as it corresponding column is being removed from the data
    k_ids_dn_data[k]=0
  end
  #just modify the k_ids that are also represented within this clust-data (don't reduce 0 to -1...)
  k_ids_dn[findall(data.k_ids.!=0)]=k_ids_dn_data
  #return the new Clust Data
  return ClustData(data.region,data.years,K_dn,data.T,data_dn,weights_dn,deltas_dn,k_ids_dn;mean=data.mean,sdv=data.sdv)
end

"""
    input_data_modification(data::ClustData,extr_val_idcs::Int)
wrapper function for a single extreme val.
returns ClustData structs with extreme vals and with remaining input data [data-extreme_vals].
Gives extreme vals the weight that they had in data.
"""
function input_data_modification(data::ClustData,extr_val_idcs::Int)
  return input_data_modification(data,[extr_val_idcs])
end

"""
   extreme_val_output(data::ClustData,extr_val_idcs::Array{Int,1};rep_mod_method="feasibility")
Takes indices as input and returns ClustData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")
  unique_extr_val_idcs = unique(extr_val_idcs)
  K_ed = length(unique_extr_val_idcs)
  data_ed=Dict{String,Array}()
  for dt in keys(data.data)
    data_ed[dt] = data.data[dt][:,unique_extr_val_idcs]
  end
  weights_ed=[]
  #initiate new k-ids-ed that don't represent any original time-period
  k_ids_ed=zeros(Int64,size(data.k_ids))
  if rep_mod_method == "feasibility"
    weights_ed = zeros(length(unique_extr_val_idcs))
    #no representation is done of the original time-period, it's just for feasibility
  elseif rep_mod_method == "append"
    weights_ed = data.weights[unique_extr_val_idcs]
    # if original time series period isn't represented by any extreme period it has value 0
    # get all the indices that acutally represent original time-series
    index_k_ids_data=findall(data.k_ids.!=0)
    # each original time series period which is represented recieves the number of it's extreme period in this extreme value output
    k_ids_ed_data=zeros(size(index_k_ids_data))
    k_ids_ed_data[unique_extr_val_idcs]=collect(1:K_ed)
    # assign it to the full original time-series
    k_ids_ed[index_k_ids_data]=k_ids_ed_data
  else
    @error("rep_mod_method - "*rep_mod_method*" - does not exist")
  end
  delta_t_ed=data.delta_t[:,unique_extr_val_idcs]
  extr_vals = ClustData(data.region,data.years,K_ed,data.T,data_ed,weights_ed,delta_t_ed,k_ids_ed;mean=data.mean,sdv=data.sdv)
  return extr_vals
end

"""
   extreme_val_output(data::ClustData,extr_val_idcs::Array{Int,1};rep_mod_method="feasibility")
wrapper function for a single extreme val.
Takes indices as input and returns ClustData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustData,
                            extr_val_idcs::Int;
                            rep_mod_method="feasibility")
  return extreme_val_output(data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end

"""
    representation_modification(extr_vals::ClustData,clust_data::ClustData)
Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(extr_vals::ClustData,
                                     clust_data::ClustData)
  K_mod = clust_data.K + extr_vals.K
  data_mod=Dict{String,Array}()
  for dt in keys(clust_data.data)
    data_mod[dt] = [clust_data.data[dt] extr_vals.data[dt]]
  end
  weights_mod = [clust_data.weights; extr_vals.weights]
  # Add extra columns to delta_t
  delta_t_mod = [clust_data.delta_t extr_vals.delta_t]
  # originial time series periods are represented by periods in clust_data
  k_ids_mod=deepcopy(clust_data.k_ids)
  # if this particular original time series period is though represented in the extreme values, the new period number of the extreme value (clust_data.K+old number) is assigned to this original time series period - in case of feasibility they are all zero and nothing is changed
  k_ids_mod[findall(extr_vals.k_ids.!=0)]=extr_vals.k_ids[findall(extr_vals.k_ids.!=0)].+clust_data.K
  return ClustData(clust_data.region,clust_data.years,K_mod,clust_data.T,data_mod,weights_mod,delta_t_mod,k_ids_mod;mean=clust_data.mean,sdv=clust_data.sdv)
end

"""
    representation_modification(extr_vals::ClustData,clust_data::ClustData)
Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(extr_vals_array::Array{ClustData,1},
                                     clust_data::ClustData,
                                     )
    for extr_vals in extr_vals_array
      clust_data=representation_modification(extr_vals,clust_data)
    end
    return clust_data
end

"""
    representation_modification(full_data::ClustData,clust_data::ClustData,extr_val_idcs::Array{Int,1};rep_mod_method::String="feasibility")
Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Array{Int,1};
                                     rep_mod_method::String="feasibility")
  extr_vals = extreme_val_output(full_data,extr_val_idcs;rep_mod_method=rep_mod_method)
  return representation_modification(extr_vals,clust_data;rep_mod_method=rep_mod_method)
end

"""
    representation_modification(full_data::ClustData,clust_data::ClustData,extr_val_idcs::Int;rep_mod_method::String="feasibility")
wrapper function for a single extreme val.
Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")
  return representation_modification(full_data,clust_data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end
