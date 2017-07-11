# Holger Teichgraeber, 2017

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #####################

module ClustForOpt
 
using PyCall

export run_battery_opt,
       run_gas_opt,
       get_EUR_to_USD,
       plot_clusters,
       load_clusters

include("utils/optim_problems.jl")
include("utils/utils.jl")

util_path = normpath(joinpath(pwd(),"..","utils"))
unshift!(PyVector(pyimport("sys")["path"]), util_path) # add util path to search path ### unshift!(PyVector(pyimport("sys")["path"]), "") # add current path to search path
@pyimport load_clusters

end # module ClustForOpt
