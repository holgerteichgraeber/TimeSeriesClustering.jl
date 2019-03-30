"""
    simple_extr_val_sel(data::ClustData,
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )
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
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )

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

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
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

identifies a single simple extreme value from the data and returns column index of extreme value

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
periods: number of periods combined to analyze
"""
function simple_extr_val_ident(data::ClustData,
                               extreme_value_descr::SimpleExtremeValueDescr)
  return simple_extr_val_ident(data, extreme_value_descr.data_type; extremum=extreme_value_descr.extremum, peak_def=extreme_value_descr.peak_def, periods=extreme_value_descr.periods)
end

"""
    simple_extr_val_ident(data::ClustData,data_type::String;extremum="max",peak_def="absolute")

identifies a single simple extreme value from the data and returns column index of extreme value

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustData,
                               data_type::String;
                               extremum::String="max",
                               peak_def::String="absolute",
                               periods::Int64=1)
  for name in keys(data.data)
    attr=split(name,"-")[1]
    if name==data_type
      return simple_extr_val_ident(data.data[data_type]; extremum=extremum, peak_def=peak_def, periods=periods)
    elseif attr==data_type
      return simple_extr_val_ident(data.data[name]; extremum=extremum, peak_def=peak_def, periods=periods)
    end
  end
  return throw(@error("the provided data type - "*data_type*" - is not contained in data"))
end

"""
    simple_extr_val_ident(data::Array{Float64};extremum="max",peak_def="absolute")
"""
function simple_extr_val_ident(data::Array{Float64};
                               extremum::String="max",
                               peak_def::String="absolute",
                               periods::Int64=1)

  # set data to be compared

  if peak_def=="absolute" && periods==1
      data_eval = data
  elseif peak_def=="integral"
    # The number of periods is substracted by one as k:k+period
    delta_period=periods-1
    data_eval=zeros(1,(size(data,2)-delta_period))
    for k in 1:(size(data,2)-delta_period)
      data_eval[1,k] = sum(data[:,k:(k+delta_period)])
    end
  else
    @error("peak_def - "*peak_def*" and periods $periods - not defined")
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
  #QUESTION What with deltas and k_ids?
  deltas_dn= data.deltas[:,index]
  k_ids_dn=deepcopy(data.k_ids)
  k_ids_dn_data=k_ids_dn[findall(data.k_ids.!=0)]
  for k in extr_val_idcs
    k_ids_dn_data[k:end].-=1
    k_ids_dn_data[k]=0
  end
  k_ids_dn[findall(data.k_ids.!=0)]=k_ids_dn_data
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
   extreme_val_output(data::ClustData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")

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
  if rep_mod_method == "feasibility"
    weights_ed = zeros(length(unique_extr_val_idcs))
  elseif rep_mod_method == "append"
    weights_ed = data.weights[unique_extr_val_idcs]
  else
    @error("rep_mod_method - "*rep_mod_method*" - does not exist")
  end
  deltas_ed=data.deltas[:,unique_extr_val_idcs]
  #QUESTION What with k_ids?
  # if original time series period isn't represented by any extreme period it has value 0
  k_ids_ed=zeros(Int64,size(data.k_ids))
  index_k_ids_data=findall(data.k_ids.!=0)
  k_ids_ed_data=k_ids_ed[index_k_ids_data]
  # each original time series period which is represented recieves the number of it's extreme period in this extreme value output
  k_ids_ed_data[unique_extr_val_idcs]=collect(1:K_ed)
  k_ids_ed[index_k_ids_data]=k_ids_ed_data
  extr_vals = ClustData(data.region,data.years,K_ed,data.T,data_ed,weights_ed,deltas_ed,k_ids_ed;mean=data.mean,sdv=data.sdv)
  return extr_vals
end

"""
   extreme_val_output(data::ClustData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")

wrapper function for a single extreme val.
Takes indices as input and returns ClustData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustData,
                            extr_val_idcs::Int;
                            rep_mod_method="feasibility")
  return extreme_val_output(data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end

"""
    representation_modification(extr_vals::ClustData,
                                     clust_data::ClustData,
                                     )

Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(extr_vals::ClustData,
                                     clust_data::ClustData,
                                     )
  K_mod = clust_data.K + extr_vals.K
  data_mod=Dict{String,Array}()
  for dt in keys(clust_data.data)
    data_mod[dt] = [clust_data.data[dt] extr_vals.data[dt]]
  end
  weights_mod = [clust_data.weights; extr_vals.weights]
  deltas_mod = [clust_data.deltas extr_vals.deltas]
  # Question what with k_ids?
  # originial time series periods are regularly represented by periods in clust_data
  k_ids_mod=deepcopy(clust_data.k_ids)
  # if this particular original time series period is though represented in the extreme values, the new period number of the extreme value (clust_data.K+old number) is assigned to this original time series period QUESTION also true for feasibility? As Cost will be assumed zero, maybe there should be an if/else of representation_modification?
  k_ids_mod[findall(extr_vals.k_ids.!=0)]=extr_vals.k_ids[findall(extr_vals.k_ids.!=0)].+clust_data.K
  return ClustData(clust_data.region,clust_data.years,K_mod,clust_data.T,data_mod,weights_mod,deltas_mod,k_ids_mod;mean=clust_data.mean,sdv=clust_data.sdv)
end

"""
function representation_modification(extr_vals::ClustData,
                                     clust_data::ClustData,
                                     )

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
    representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Array{Int,1};
                                     rep_mod_method::String="feasibility")

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
    representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")

wrapper function for a single extreme val.
Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")
  return representation_modification(full_data,clust_data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end
