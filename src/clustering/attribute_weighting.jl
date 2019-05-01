"""
function attribute_weighting(data::ClustData,attribute_weights::Dict{String,Float64})

apply the different attribute weights based on the dictionary entry for each tech or exact name
"""
function attribute_weighting(data::ClustData,
                              attribute_weights::Dict{String,Float64}
                              )
  for name in keys(data.data)
    tech=split(name,"-")[1]
    if name in keys(attribute_weights)
      attribute_weight=attribute_weights[name]
      data.data[name].*=attribute_weight
      data.sdv[name]./=attribute_weight
    elseif tech in keys(attribute_weights)
      attribute_weight=attribute_weights[tech]
      data.data[name].*=attribute_weight
      data.sdv[name]./=attribute_weight
    end
  end
  return data
end
