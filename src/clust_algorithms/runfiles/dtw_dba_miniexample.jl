# imports
using DataFrames
using TimeWarp
#using TimeWarp.WarpPlots
#pyplot()
 #gr()
 using PyPlot
 plt = PyPlot

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
show()

# normalized clustering



if is_linux()
  show()
end
