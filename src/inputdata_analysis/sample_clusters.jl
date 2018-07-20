# this file generates the plots for the framework figure in Teichgraeber et al. (2018)

CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
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

 # sequence based normalization
mn1= mean(seq,1)'
sdv1 = std(seq,1)'
# convert to array of dimension 1
mn1=reshape(mn1,size(mn1)[1])
sdv1=reshape(sdv1,size(sdv1)[1])
 # element based normalization
mn2= mean(seq,2)
sdv2 = std(seq,2)

ind_sort = sortperm(mn1,rev=true)
ind_max1 = ind_sort[1]
ind_max2 = ind_sort[2]
ind_min1 = ind_sort[length(ind_sort)-1]
ind_min2 = ind_sort[length(ind_sort)-2]
ind_plot= [ind_max1,ind_max2,ind_min1,ind_min2]

sample_days = seq[:,ind_plot]
seq_norm,hourly_mean,hourly_sdv = z_normalize(seq,scope="hourly")
 #sample_days_norm,hourly_mean,hourly_sdv = z_normalize(sample_days;hourly=true,sequence=false)
sample_days_norm=seq_norm[:,ind_plot]

xkcd()
figure()
plot(sample_days,color="k")
ax = axes()
 #ax[:spines]["top"][:set_color]("none")
 #ax[:spines]["right"][:set_color]("none")
axis("off")
savefig("1.eps",format="eps")

figure()
plot(sample_days_norm,color="k")
axis("off")
savefig("2.eps",format="eps")

figure()
plot(sample_days_norm[:,1:2],color=StanfordYellow)
plot(sample_days_norm[:,3:4],color=StanfordDBlue)
axis("off")
savefig("3.eps",format="eps")


figure()
plot(sample_days[:,1:2],color=StanfordYellow)
plot(sample_days[:,3:4],color=StanfordDBlue)
plot(mean(sample_days[:,1:2],2),linestyle="--",color=StanfordYellow)
plot(mean(sample_days[:,3:4],2),linestyle="--",color=StanfordDBlue)
axis("off")
savefig("4.eps",format="eps")
