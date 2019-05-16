# Holger Teichgraeber, Elias Kuepper, 2019

 ######################
 # ClustForOpt
 # Analyzing clustering techniques as input for energy systems optimization
 #
 #####################
module ClustForOpt
  using Reexport
  using LinearAlgebra
  using CSV
  using Clustering
  using DataFrames
  using Distances
  using StatsBase
  @reexport using FileIO
  using JuMP

   #TODO how to make PyPlot, PyCall, and TimeWarp optional? -> only import when needed

   export InputData,
          FullInputData,
          ClustData,
          ClustDataMerged,
          AbstractClustResult,
          ClustResultAll,
          ClustResult,
          SimpleExtremeValueDescr,
          load_timeseries_data,
          combine_timeseries_weather_data,
          extreme_val_output,
          simple_extr_val_sel,
          representation_modification,
          get_sup_kw_args,
          run_clust,
          run_opt,
          data_type,
          get_EUR_to_USD, #TODO Check which of the following should really be exported
          z_normalize,
          undo_z_normalize,
          sakoe_chiba_band,
          kmedoids_exact,
          sort_centers,
          calc_SSE,
          find_medoids,
          resize_medoids

  include(joinpath("utils","datastructs.jl"))
  include(joinpath("utils","utils.jl"))
  include(joinpath("utils","load_data.jl"))
  include(joinpath("optim_problems","run_opt.jl"))
  include(joinpath("clustering","run_clust.jl"))
  include(joinpath("clustering","exact_kmedoids.jl"))
  include(joinpath("clustering","extreme_vals.jl"))
  include(joinpath("clustering","attribute_weighting.jl"))
  include(joinpath("clustering","intraperiod_segmentation.jl"))
end # module ClustForOpt
