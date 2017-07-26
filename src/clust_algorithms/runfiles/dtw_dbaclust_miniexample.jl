# imports


push!(LOAD_PATH, normpath(joinpath(pwd(),"..",".."))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using DataFrames
using TimeWarp # has to be before ClustForOpt
using Colors
 using PyPlot
 plt = PyPlot
plt.close()
# example not working, somehow input is not in correct format
# x = [1,2,2,3,3,4]
# y = [1,3,4]
# z = [1,2,2,4]
# avg,result = dba([x,y,z],ClassicDTW(),iterations=15)  # make sure to put in ClassicDTW()
# println(avg)


 ######## DATA INPUT ##########

 # region
region = "GER"


# read in original data
if region =="CA"
  region_str = ""
  region_data = normpath(joinpath(pwd(),"..","..","..","data","el_prices","ca_2015_orig.txt"))
else
  region_str = "GER_"
  region_data = normpath(joinpath(pwd(),"..","..","..","data","el_prices","GER_2015_elPrice.txt"))
end
data_orig = Array(readtable(region_data, separator = '\t', header = false))
data_orig_daily = reshape(data_orig,24,365)
seq = data_orig_daily[:,1:365]  # do not load as sequence

println("data loaded")

## Manual data input
n_seq=365
n_clust = 4
n_init=2

##########################
# normalized clustering hourly

#init_centers = TimeWarp.dbaclust_initial_centers(data_orig_daily[:,1:n_seq], n_clust, ClassicDTW())

seq_norm, hourly_mean, hourly_sdv = z_normalize(data_orig_daily[:,1:n_seq],hourly=true)
tic()
centers_norm, clustids, result_norm = dbaclust(seq_norm[:,1:n_seq],n_clust,n_init,ClassicDTW();iterations=4,inner_iterations=15,rtol=1e-5,show_progress=false,store_trace=false)
toc()


centers = undo_z_normalize(seq_to_array(centers_norm),hourly_mean,hourly_sdv)

col = plt.get_cmap("Dark2")

figure()
for i=1:n_clust
  plt.plot(seq[:,clustids.==i],color=col((i-1)/(n_clust-1)),alpha=0.15)
end
for i=1:n_clust
  plt.plot(centers[:,i],label=string("clust:",i),color=col((i-1)/(n_clust-1)),linewidth=2.0)
end
#plt.plot(mean_euc,label="euclidean",color="blue")
plt.title("normalized")
plt.legend()


show()
