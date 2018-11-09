CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using TimeWarp
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

println("data loaded")

seq1 = data_orig_daily[:,1]
seq2 = data_orig_daily[:,2]
seq = data_orig_daily[:,1:365]  # do not load as sequence

# test dtw
D = dtw(seq1,seq2) # dtw can be fed with normal array/vector or Sequence
println("D ",D)
E = fastdtw(seq1,seq2,24) # fastdtw can only be fed with array/vector
println("E ",E)

#dtwplot(Sequence(seq1),Sequence(seq2))  # dtwplot has to be fed with sequence, somehow does not work currently, shows empty plot
#show()

#avg, result = dba(seq,ClassicDTW(),iterations=15) #always include DTWMethod. Put initial one in example or actual code
#println(avg)

##
n_seq=10
tic()
mean_dtw,result = dba(seq[:,1:n_seq],ClassicDTW(),iterations=15,rtol=1e-5,show_progress=true)
toc()

mean_euc = mean(seq[:,1:n_seq],2)

figure()
plt.plot(seq[:,1:n_seq],color="0.75")
plt.plot(mean_dtw,label="dtw",color="red")
plt.plot(mean_euc,label="euclidean",color="blue")
plt.legend()

##########################
# normalized clustering hourly

seq_norm, hourly_mean, hourly_sdv = z_normalize(data_orig_daily[:,1:n_seq],hourly=true)
tic()
mean_dtw_norm,result_norm = dba(seq_norm[:,1:n_seq],ClassicDTW(),iterations=15,rtol=1e-5,show_progress=true)
toc()

mean_euc_norm = mean(seq_norm[:,1:n_seq],2)

mean_dtw = undo_z_normalize(reshape(mean_dtw_norm,size(mean_dtw_norm)[1],1),hourly_mean,hourly_sdv)
mean_euc = undo_z_normalize(mean_euc_norm,hourly_mean,hourly_sdv)

figure()
plt.plot(seq[:,1:n_seq],color="0.75")
plt.plot(mean_dtw,label="dtw",color="red")
plt.plot(mean_euc,label="euclidean",color="blue")
plt.title("normalized")
plt.legend()

#######################
# normalized and include warping window
rad_sc = 2 # sakoe chiba band radius
rmin,rmax = sakoe_chiba_band(rad_sc,24)

seq_norm, hourly_mean, hourly_sdv = z_normalize(data_orig_daily[:,1:n_seq],hourly=true)
tic()
mean_dtw_norm,result_norm = dba(seq_norm[:,1:n_seq],ClassicDTW(),iterations=15,rtol=1e-5,show_progress=true,i2min=rmin,i2max=rmax)
toc()

mean_euc_norm = mean(seq_norm[:,1:n_seq],2)

mean_dtw = undo_z_normalize(reshape(mean_dtw_norm,size(mean_dtw_norm)[1],1),hourly_mean,hourly_sdv)
mean_euc = undo_z_normalize(mean_euc_norm,hourly_mean,hourly_sdv)

figure()
plt.plot(seq[:,1:n_seq],color="0.75")
plt.plot(mean_dtw,label="dtw",color="red")
plt.plot(mean_euc,label="euclidean",color="blue")
plt.title("normalized")
plt.legend()





show()
