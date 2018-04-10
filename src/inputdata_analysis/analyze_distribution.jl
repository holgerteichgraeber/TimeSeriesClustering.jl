push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

using PyPlot
using DataFrames
plt = PyPlot

region = "GER"

 # read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

nbins = 30
 ##### plot histogram of mean and sdv sequence based mean(seq,1) 
mn1= mean(seq,1)'
sdv1 = std(seq,1)'
figure()
plt.plt[:hist](mn1,nbins)
plt.title("mean 365")
figure()
plt.plt[:hist](sdv1,nbins)
plt.title("sdv 365")
 ### plot histogram of mean and sdv elementwise (mean(seq,2))

mn2= mean(seq,2)
sdv2 = std(seq,2)

"""
 ### plot histogram of 1-24
nbins=30
for i=1:24
  figure()
  plt.plt[:hist](seq[i,:]',nbins)
  plt.title(string(i))
end
"""


