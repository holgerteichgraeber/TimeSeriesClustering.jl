"""
function simple_extr_val_sel(data::ClustInputData,
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )

Selects simple extreme values and returns modified data, extreme values, and the corresponding indices.
"""
function simple_extr_val_sel(data::ClustInputData,
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )
  idcs = simple_extr_val_ident(data,extreme_value_descr_ar)
  extr_vals = extreme_val_output(data,extr_val_idcs;rep_mod_method=rep_mod_method)
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
function simple_extr_val_sel(data::ClustInputData,
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )

Wrapper function for only one simple extreme value.
Selects simple extreme values and returns modified data, extreme values, and the corresponding indices.
"""
function simple_extr_val_sel(data::ClustInputData,
                             extreme_value_descr::SimpleExtremeValueDescr;
                             rep_mod_method::String="feasibility"
                             )
  return simple_extr_val_sel(data,[extreme_value_descr];rep_mod_method=rep_mod_method)
end

"""
    function simple_extr_val_ident(data::ClustInputData,extreme_value_descr::Array{SimpleExtremeValueDescr,1})

identifies multiple simple extreme values from the data and returns array of column indices of extreme value within data

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustInputData,
                               extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1})
  idcs = Array{Int,1}()
  # for each desired extreme value description, finds index of that extreme value within data
  for i=1:length(extreme_value_descr_ar)
    push!(idcs,simple_extr_val_ident(data,extreme_value_descr_ar[i])) 
  end
  return idcs
end

"""
    function simple_extr_val_ident(data::ClustInputData,extreme_value_descr::SimpleExtremeValueDescr)

identifies a single simple extreme value from the data and returns column index of extreme value

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustInputData,
                               extreme_value_descr::SimpleExtremeValueDescr)
  return simple_extr_val_ident(data, extreme_value_descr.data_type; extremum=extreme_value_descr.extremum, peak_def=extreme_value_descr.peak_def)
end

"""
    function simple_extr_val_ident(data::ClustInputData,data_type::String;extremum="max",peak_def="absolute")

identifies a single simple extreme value from the data and returns column index of extreme value

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustInputData, 
                               data_type::String;
                               extremum::String="max", 
                               peak_def::String="absolute")
  # TODO: Possibly add option to find maximum among all series of a data_type for a certain node
  !(data_type in keys(data.data)) && @error("the provided data type - "*data_type*" - is not contained in data")
  return simple_extr_val_ident(data.data[data_type]; extremum=extremum, peak_def=peak_def)
end

"""
    function simple_extr_val_ident(data::Array{Float64};extremum="max",peak_def="absolute")
"""
function simple_extr_val_ident(data::Array{Float64};
                               extremum::String="max",
                               peak_def::String="absolute")
  # set data to be compared 
  if peak_def=="absolute"
    data_eval = data
  elseif peak_def=="integral"
    data_eval = sum(data,dims=1)
  else
    @error("peak_def - "*peak_def*" - not defined")  
  end
  # find minimum or maximum index. Second argument returns cartesian indices, second argument of that is the column (period) index
  if extremum=="max"
    idx = findmax(data_eval)[2][2]
  elseif extremum=="min"
    idx = findmin(data_eval)[2][2]
  else
    @error("extremum - "*extremum*" - not defined")  
  end
  return idx
end

"""
    function input_data_modification(data::ClustInputData,extr_val_idcs::Array{Int,1})

returns ClustInputData structs with extreme vals and with remaining input data [data-extreme_vals].
Gives extreme vals the weight that they had in data. 
This function is needed for the append method for representation modification
"""
function input_data_modification(data::ClustInputData,extr_val_idcs::Array{Int,1})
  K_dn = data.K- length(extr_val_idcs) 
  data_dn=Dict{String,Array}()
  for dt in keys(data.data)
    data_dn[dt] = data.data[dt][:,setdiff(1:size(data.data[dt],2),extr_val_idcs)] #take all columns but the ones that are extreme vals
  end
  weights_dn = data.weights[setdiff(1:size(data.weights,2),extr_val_idcs)]
  data_modified = ClustInputData(data.region,K_dn,data.T,data_dn,weights_dn;mean=data.mean,sdv=data.sdv) 
  return data_modified
end

"""
    function input_data_modification(data::ClustInputData,extr_val_idcs::Int)

wrapper function for a single extreme val. 
returns ClustInputData structs with extreme vals and with remaining input data [data-extreme_vals].
Gives extreme vals the weight that they had in data. 
"""
function input_data_modification(data::ClustInputData,extr_val_idcs::Int)
  return input_data_modification(data,[extr_val_idcs])
end

"""
   function extreme_val_output(data::ClustInputData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")

Takes indices as input and returns ClustInputData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustInputData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")
  K_ed = length(extr_val_idcs)
  data_ed=Dict{String,Array}()
  for dt in keys(data.data)
    data_ed[dt] = data.data[dt][:,extr_val_idcs]
  end
  weights_ed=[]
  if rep_mod_method == "feasibility"
    weights_ed = zeros(length(extr_val_idcs)) 
  elseif rep_mod_method == "append"
    weights_ed = data.weights[extr_val_idcs]
  else
    @error("rep_mod_method - "*rep_mod_method*" - does not exist")
  end
  extr_vals = ClustInputData(data.region,K_ed,data.T,data_ed,weights_ed;mean=data.mean,sdv=data.sdv)
  return extr_vals
end

"""
   function extreme_val_output(data::ClustInputData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")

wrapper function for a single extreme val. 
Takes indices as input and returns ClustInputData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustInputData,
                            extr_val_idcs::Int;
                            rep_mod_method="feasibility")
  return extreme_val_output(data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end

"""
function representation_modification(extr_vals::ClustInputData,
                                     clust_data::ClustInputData,
                                     )

Merges the clustered data and extreme vals into one ClustInputData struct. Weights are chosen according to the rep_mod_method 
"""
function representation_modification(extr_vals::ClustInputData,
                                     clust_data::ClustInputData,
                                     )
  K_mod = clust_data.K + extr_vals.K
  data_mod=Dict{String,Array}()
  for dt in keys(clust_data.data)
    data_mod[dt] = [clust_data.data[dt] extr_vals.data[dt]]
  end
  weights_mod = deepcopy(clust_data.weights)
  for w in extr_vals.weights 
    push!(weights_mod,w) 
  end
  return ClustInputData(clust_data.region,K_mod,clust_data.T,data_mod,weights_mod;mean=clust_data.mean,sdv=clust_data.sdv)
end

"""
    function representation_modification(full_data::ClustInputData,
                                     clust_data::ClustInputData,
                                     extr_val_idcs::Array{Int,1};
                                     rep_mod_method::String="feasibility")

Merges the clustered data and extreme vals into one ClustInputData struct. Weights are chosen according to the rep_mod_method 
"""
function representation_modification(full_data::ClustInputData,
                                     clust_data::ClustInputData,
                                     extr_val_idcs::Array{Int,1};
                                     rep_mod_method::String="feasibility")
  extr_vals = extreme_val_output(full_data,extr_val_idcs;rep_mod_method=rep_mod_method) 
  return representation_modification(extr_vals,clust_data;rep_mod_method=rep_mod_method)
end

"""
    function representation_modification(full_data::ClustInputData,
                                     clust_data::ClustInputData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")

wrapper function for a single extreme val. 
Merges the clustered data and extreme vals into one ClustInputData struct. Weights are chosen according to the rep_mod_method 
"""
function representation_modification(full_data::ClustInputData,
                                     clust_data::ClustInputData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")
  return representation_modification(full_data,clust_data,[extr_val_idcs];rep_mod_method=rep_mod_method) 
end



