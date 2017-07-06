# imports 
using DataFrames
using TimeWarp
using TimeWarp.WarpPlots
pyplot()
 #gr()

 #x = [1,2,2,3,3,4]
 #y = [1,3,4,4,5,6]
 #z = [1,2,2,4]
 #avg,result = dba([x,y])
 #println(avg)


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

seq1 = Sequence(data_orig_daily[:,1])
seq2 = Sequence(data_orig_daily[:,2])

# test dtw
D = dtw(seq1,seq2)
println("D ",D)
 
 # test dba
 #avg, result = dba(data)
 #println(avg)



if is_linux()
  show()
end
