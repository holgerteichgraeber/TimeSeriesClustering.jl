CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using Distances
using TimeWarp # has to be before ClustForOpt
using TimeWarp.WarpPlots
using PyPlot
using DataFrames
plt = PyPlot
 
 ######## DATA INPUT ##########

 # region
region = "GER"


# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence
println("data loaded")

seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,scope="sequence")

day1 = 23
day2=24
rad_sc=2

rmin,rmax = sakoe_chiba_band(rad_sc,24)
 # need distance matrix D for dtwplot - somehow get it, then plot the thing
 # adjust in dtwplot - make new branch for plotting to adjust dtwplot parameters

dist,i1,i2=dtw(Sequence(seq_norm[:,day1]),Sequence(seq_norm[:,day2]),rmin,rmax)
D = dtw_cost_matrix_nonc(Sequence(seq_norm[:,day1]),Sequence(seq_norm[:,day2]),rmin,rmax)

dtwplot(Sequence(seq_norm[:,day1]),Sequence(seq_norm[:,day2]),D,i1,i2)



