"""
    function simple_extr_val_ident(data::ClustInputData,data_type::String;extremum="max",peak_def="absolute")

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustInputData,data_type::String;extremum::String="max",peak_def::String="absolute")
  # TODO: Possibly add option to find maximum among all series of a data_type for a certain node
  !(data_type in keys(data.data)) && @error("the provided data type - "*data_type*" - is not contained in data")
  return simple_extr_val_ident(data.data[data_type];extremum=extremum,peak_def=peak_def)
end




"""
    function simple_extr_val_ident(data::Array{Float64};extremum="max",peak_def="absolute")
"""
function simple_extr_val_ident(data::Array{Float64};extremum::String="max",peak_def::String="absolute")
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








