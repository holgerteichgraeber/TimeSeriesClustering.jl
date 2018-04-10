CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using TimeWarp # has to be before ClustForOpt
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
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

println("data loaded")

## Manual data input
n_seq=365
n_clust = 3
n_init=50

##########################
# normalized clustering hourly

# optional warping window
rad_sc = 5 # sakoe chiba band radius
rmin,rmax = sakoe_chiba_band(rad_sc,24)
#rmin=[];rmax=[]

seq_norm, hourly_mean, hourly_sdv = z_normalize(data_orig_daily[:,1:n_seq],hourly=true)
tic()
results = dbaclust(seq_norm[:,1:n_seq],n_clust,n_init,ClassicDTW();iterations=100,inner_iterations=15,rtol=1e-5,show_progress=false,store_trace=false,i2min=rmin,i2max=rmax)
toc()
centers_norm = results.centers
clustids = results.clustids

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
