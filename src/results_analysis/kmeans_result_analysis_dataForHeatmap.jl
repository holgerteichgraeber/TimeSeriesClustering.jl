using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO
using CSV

using PyPlot
using DataFrames
plt = PyPlot

using Clustering

region = "GER" # GER,CA

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string(string("parameters_kmeans_",region,".txt"))))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_init=param[:n_init][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)
 
# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

 # opt problem
problem_type = "battery"


 # load saved JLD data
saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kmeans_"),region,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue=revenue[problem_type] 

 # initialize dictionaries of the loaded data (key: number of clusters)
 #centers = Dict{Tuple{Int,Int,Int},Array}()
 #clustids = Dict{Tuple{Int,Int,Int},Array}()
 #cost = zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)
 #iter =  zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)
 #weights = Dict{Tuple{Int,Int,Int},Array}()
 #revenue = zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2 # gives one index to index the 2d array
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best = zeros(size(revenue,1))
cost_best = zeros(size(cost,1))
for i=1:size(revenue,1)
    revenue_best[i]=revenue[ind_mincost[i]] 
    cost_best[i]=cost[ind_mincost[i]] 
end



# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));


kk_ar = [1,4,9]


clust_data = zeros(length(seq),length(kk_ar))
i=0
for kk in kk_ar
  i+=1
  i_costmin = findmin(cost[kk,:])[2] # this is for tuples, where we need two indices, this gives the second index
  for d=1:length(clustids[kk,i_costmin])
    clust_data[((d-1)*24+1):(d*24),i] = centers[kk,i_costmin][:,clustids[kk,i_costmin][d]]
 #seq[:,clustids[kk,i_costmin][d]]
  end
end


for i=1:size(clust_data,2)
  # save as csv with header
  df=DataFrame()
  df[Symbol("k=",kk_ar[i])]=clust_data[:,i]
  CSV.write(string("GER_data_clust_k_",kk_ar[i],".csv"),df,header=true)
end

