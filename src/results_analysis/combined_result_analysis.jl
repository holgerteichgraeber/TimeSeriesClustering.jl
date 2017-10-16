 # imports
push!(LOAD_PATH, normpath(joinpath(pwd(),".."))) #adds the location of ClustForOpt to the LOAD_PATH
push!(LOAD_PATH, "/data/cees/hteich/clustering/src")
using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

using PyPlot
using DataFrames
plt = PyPlot

region_ = "GER"  # GER , CA
region = region_

 # opt problem
problem_type = "battery"
 
# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

 # set up some common variables
revenue = Dict{String,Array}()
revenue_best = Dict{String, Array}()

##### k-means #############

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_kmeans_",region_,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_kmeans=param[:n_kmeans][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)

 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_kmeans_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue["kmeans"] =revenue[problem_type] 

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kmeans"] = zeros(size(revenue["kmeans"],1))
for i=1:size(revenue["kmeans"],1)
    revenue_best["kmeans"][i]=revenue["kmeans"][ind_mincost[i]] 
end

 ##### k-medoids #######


 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_kmedoids_",region_,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_kmedeoids=param[:n_kmedeoids][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)

dist_type = "SqEuclidean"   # "SqEuclidean"   "Cityblock"

 # load saved JLD data - kmeans algorithm of kmedoids
saved_data_dict= load(string("outfiles/aggregated_results_kmedoids_",dist_type,"_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue["kmedoids"]=revenue[problem_type] 

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kmedoids"] = zeros(size(revenue["kmedoids"],1))
for i=1:size(revenue["kmedoids"],1)
    revenue_best["kmedoids"][i]=revenue["kmedoids"][ind_mincost[i]] 
end

 # load saved JLD data - exact algorithm of kmedoids
saved_data_dict= load(string("outfiles/aggregated_results_kmedoids_exact_",dist_type,"_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue["kmedoids_exact"]=revenue[problem_type] 

 # Find best cost index -exact - not necessary, but legacy code
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kmedoids_exact"] = zeros(size(revenue["kmedoids_exact"],1))
for i=1:size(revenue["kmedoids_exact"],1)
    revenue_best["kmedoids_exact"][i]=revenue["kmedoids_exact"][ind_mincost[i]] 
end


 ##### hierarchical clustering #######

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_hier_",region_,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_hier=param[:n_hier][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)

 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_hier_centroid_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(string(k,"_centroid"))) = $v
 end

 #set revenue to the chosen problem type
revenue["hier_centroid"]=revenue_centroid[problem_type] 

 # Find best cost index - save
ind_mincost = findmin(cost_centroid,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["hier_centroid"] = zeros(size(revenue["hier_centroid"],1))
for i=1:size(revenue["hier_centroid"],1)
    revenue_best["hier_centroid"][i]=revenue["hier_centroid"][ind_mincost[i]] 
end
 
 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_hier_medoid_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(string(k,"_medoid"))) = $v
 end

 #set revenue to the chosen problem type
revenue["hier_medoid"]=revenue_medoid[problem_type] 

 # Find best cost index - save
ind_mincost = findmin(cost_medoid,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["hier_medoid"] = zeros(size(revenue["hier_medoid"],1))
for i=1:size(revenue["hier_medoid"],1)
    revenue_best["hier_medoid"][i]=revenue["hier_medoid"][ind_mincost[i]] 
end

 #### fuzzy c-means ###########

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_cmeans_",region_,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_cmeans=param[:n_cmeans][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)

 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_cmeans_fuzzy_2.0_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue["cmeans"]=revenue[problem_type] 

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["cmeans"] = zeros(size(revenue["cmeans"],1))
for i=1:size(revenue["cmeans"],1)
    revenue_best["cmeans"][i]=revenue["cmeans"][ind_mincost[i]] 
end


 ##### Dynamic Time Warping #####
 #window =1, window =2

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_dtw_",region_,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_init=param[:n_init][1]
n_dbaclust=param[:n_dbaclust][1]
rad_sc_min=param[:rad_sc_min][1]
rad_sc_max=param[:rad_sc_max][1]
iterations=param[:iterations][1]
inner_iterations=param[:inner_iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)
rad_sc_ar = collect(rad_sc_min:rad_sc_max)


 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_dtw_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue["dtw"]=revenue[problem_type] 

 # Find best cost index - save
ind_mincost = findmin(cost,3)[2]  # along dimension 3
ind_mincost = reshape(ind_mincost,size(ind_mincost,1),size(ind_mincost,2))
revenue_best["dtw"] = zeros(size(revenue["dtw"],1),size(revenue["dtw"],2))
for i=1:size(revenue["dtw"],1)
  for j=1:size(revenue["dtw"],2)
    revenue_best["dtw"][i,j]=revenue["dtw"][ind_mincost[i,j]] 
  end
end

plot_sc_ar =[1,2] # [0,1,2,3,4]  # [0,5,10,15,20,24]
 # for plotting, check dbaclust file

 #### k-shape ###########

 # \TODO - convert data to JLD2 in similar format to the other ones


 ####### Figures ##############
figure()

plt.plot(n_clust_ar,revenue_best["kmeans"][:]/1e6,label="k-means",color="b",lw=2)
plt.plot(n_clust_ar,revenue_best["kmedoids"][:]/1e6,label="k-medoids greedy",color="g",lw=2)
plt.plot(n_clust_ar,revenue_best["kmedoids_exact"][:]/1e6,label="k-medoids exact",color="r",lw=2)
plt.plot(n_clust_ar,revenue_best["hier_centroid"][:]/1e6,label="hierarchical centroid",color="m",lw=2)
plt.plot(n_clust_ar,revenue_best["hier_medoid"][:]/1e6,label="hierarchical medoid",color="y",lw=2)
plt.plot(n_clust_ar,revenue_best["cmeans"][:]/1e6,label="fuzzy c-means",color="k",lw=2)
linestyle_ar = ["--",":"]
ii=0
for j in plot_sc_ar
  ii +=1
  plt.plot(n_clust_ar,revenue_best["dtw"][:,j+1]/1e6,lw=2,label=string("DTW skband=",j),color="k",linestyle=linestyle_ar[ii])
end
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()
plt.xlabel("k")
plt.ylabel("revenue [Mio EUR]")
plt.title(string(problem_type," ",region_))
