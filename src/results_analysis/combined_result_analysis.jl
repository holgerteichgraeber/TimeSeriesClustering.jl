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
revenue_dict = Dict{String,Array}()
revenue_best = Dict{String, Array}()
cost_dict = Dict{String,Array}()
cost_best = Dict{String,Array}()

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
revenue_dict["kmeans"] =revenue[problem_type] 
cost_dict["kmeans"] = cost

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kmeans"] = zeros(size(revenue_dict["kmeans"],1))
cost_best["kmeans"] = zeros(size(cost_dict["kmeans"],1))
for i=1:size(revenue_dict["kmeans"],1)
    revenue_best["kmeans"][i]=revenue_dict["kmeans"][ind_mincost[i]] 
    cost_best["kmeans"][i]=cost_dict["kmeans"][ind_mincost[i]] 
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
revenue_dict["kmedoids"]=revenue[problem_type] 
cost_dict["kmedoids"] = cost

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kmedoids"] = zeros(size(revenue_dict["kmedoids"],1))
for i=1:size(revenue_dict["kmedoids"],1)
    revenue_best["kmedoids"][i]=revenue_dict["kmedoids"][ind_mincost[i]] 
end

 # load saved JLD data - exact algorithm of kmedoids
saved_data_dict= load(string("outfiles/aggregated_results_kmedoids_exact_",dist_type,"_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue_dict["kmedoids_exact"]=revenue[problem_type] 
cost_dict["kmedoids_exact"] = cost

 # Find best cost index -exact - not necessary, but legacy code
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kmedoids_exact"] = zeros(size(revenue_dict["kmedoids_exact"],1))
for i=1:size(revenue_dict["kmedoids_exact"],1)
    revenue_best["kmedoids_exact"][i]=revenue_dict["kmedoids_exact"][ind_mincost[i]] 
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
revenue_dict["hier_centroid"]=revenue_centroid[problem_type] 
cost_dict["hier_centroid"] = cost_centroid

 # Find best cost index - save
ind_mincost = findmin(cost_centroid,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["hier_centroid"] = zeros(size(revenue_dict["hier_centroid"],1))
for i=1:size(revenue_dict["hier_centroid"],1)
    revenue_best["hier_centroid"][i]=revenue_dict["hier_centroid"][ind_mincost[i]] 
end
 
 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_hier_medoid_",region_,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(string(k,"_medoid"))) = $v
 end

 #set revenue to the chosen problem type
revenue_dict["hier_medoid"]=revenue_medoid[problem_type] 
cost_dict["hier_medoid"] = cost

 # Find best cost index - save
ind_mincost = findmin(cost_medoid,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["hier_medoid"] = zeros(size(revenue_dict["hier_medoid"],1))
for i=1:size(revenue_dict["hier_medoid"],1)
    revenue_best["hier_medoid"][i]=revenue_dict["hier_medoid"][ind_mincost[i]] 
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
revenue_dict["cmeans"]=revenue[problem_type] 
cost_dict["cmeans"]=cost

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["cmeans"] = zeros(size(revenue_dict["cmeans"],1))
for i=1:size(revenue_dict["cmeans"],1)
    revenue_best["cmeans"][i]=revenue_dict["cmeans"][ind_mincost[i]] 
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
revenue_dict["dtw"]=revenue[problem_type] 
cost_dict["dtw"] = cost

 # Find best cost index - save
ind_mincost = findmin(cost,3)[2]  # along dimension 3
ind_mincost = reshape(ind_mincost,size(ind_mincost,1),size(ind_mincost,2))
revenue_best["dtw"] = zeros(size(revenue_dict["dtw"],1),size(revenue_dict["dtw"],2))
for i=1:size(revenue_dict["dtw"],1)
  for j=1:size(revenue_dict["dtw"],2)
    revenue_best["dtw"][i,j]=revenue_dict["dtw"][ind_mincost[i,j]] 
  end
end

plot_sc_ar =[1,2] # [0,1,2,3,4]  # [0,5,10,15,20,24]
 # for plotting, check dbaclust file

 #### k-shape ###########

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_kshape_",region,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_kshape=param[:n_kshape][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)

 # load saved JLD data
saved_data_dict= load(string("outfiles/aggregated_results_kshape_",region,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue_dict["kshape"]=revenue[problem_type] 
cost_dict["kshape"] = cost

 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best["kshape"] = zeros(size(revenue_dict["kshape"],1))
for i=1:size(revenue_dict["kshape"],1)
    revenue_best["kshape"][i]=revenue_dict["kshape"][ind_mincost[i]] 
end


 ####### Figures ##############

 # revenue vs. k
clust_methods = Array{Dict,1}()

push!(clust_methods,Dict("name"=>"full representation", "rev"=> revenue_orig_daily*ones(length(n_clust_ar)),"color"=>"c","linestyle"=>"--","width"=>3))
plot_k_rev(n_clust_ar,clust_methods,string("plots/fulldata_",region,".png"))
push!(clust_methods,Dict("name"=>"k-means", "rev"=> revenue_best["kmeans"][:],"color"=>"b","linestyle"=>"-","width"=>2))
plot_k_rev(n_clust_ar,clust_methods,string("plots/kmeans_",region,".png"))
push!(clust_methods,Dict("name"=>"k-medoids", "rev"=> revenue_best["kmedoids_exact"][:],"color"=>"g","linestyle"=>"-","width"=>2))
plot_k_rev(n_clust_ar,clust_methods,string("plots/kmedoids_",region,".png"))
push!(clust_methods,Dict("name"=>"DTW skband = 1", "rev"=> revenue_best["dtw"][:,2],"color"=>"k","linestyle"=>"--","width"=>2))
plot_k_rev(n_clust_ar,clust_methods,string("plots/dtw1_",region,".png"))
push!(clust_methods,Dict("name"=>"DTW skband = 2", "rev"=> revenue_best["dtw"][:,3],"color"=>"k","linestyle"=>":","width"=>2))
plot_k_rev(n_clust_ar,clust_methods,string("plots/dtw2_",region,".png"))
push!(clust_methods,Dict("name"=>"hierarchical centroid", "rev"=> revenue_best["hier_centroid"][:],"color"=>"m","linestyle"=>"-","width"=>2))
plot_k_rev(n_clust_ar,clust_methods,string("plots/hiercen_",region,".png"))
push!(clust_methods,Dict("name"=>"hierarchical medoid", "rev"=> revenue_best["hier_medoid"][:],"color"=>"y","linestyle"=>"-","width"=>2))
plot_k_rev(n_clust_ar,clust_methods,string("plots/hiermed_",region,".png"))

 # revenue vs. SSE
 # averaging

cost_rev_clouds = Dict()
cost_rev_points = Array{Dict,1}()
descr=string("plots/cloud_kmeans_",region,".png")

cost_rev_clouds["cost"]=cost_dict["kmeans"]
cost_rev_clouds["rev"] = revenue_dict["kmeans"]

 #push!(cost_rev_points,Dict("label"=>"Hierarchical centroid","cost"=>cost_dict["hier_centroid"],"rev"=>revenue_dict["hier_centroid"],"mec"=>"k","mew"=>2.0,"marker"=>"." ))
 # \TODO   --> add best kmeans
push!(cost_rev_points,Dict("label"=>"kmeans best","cost"=>cost_best["kmeans"],"rev"=>revenue_best["kmeans"],"mec"=>"k","mew"=>2.0,"marker"=>"s" ))

plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily)
 

# Medoid
 # k-medoids
cost_rev_clouds = Dict()
cost_rev_points = Array{Dict,1}()
descr=string("plots/cloud_kmedoids_",region,".png")

cost_rev_clouds["cost"]=cost_dict["kmedoids"]
cost_rev_clouds["rev"] = revenue_dict["kmedoids"]

 # k-medoids exact
push!(cost_rev_points,Dict("label"=>"k-medoids exact","cost"=>cost_dict["kmedoids_exact"],"rev"=>revenue_dict["kmedoids_exact"],"mec"=>"k","mew"=>2.0,"marker"=>"s" ))

 # hier medoid
push!(cost_rev_points,Dict("label"=>"Hierarchical medoid","cost"=>cost_dict["hier_medoid"],"rev"=>revenue_dict["hier_medoid"],"mec"=>"k","mew"=>3.0,"marker"=>"x" ))

plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily;n_col=3)
  
"""
figure()
linestyle_ar = ["--",":"]
plt.plot(n_clust_ar,revenue_best["kmeans"][:]/1e6,label="k-means",color="b",lw=2)
plt.plot(n_clust_ar,revenue_best["kmedoids"][:]/1e6,label="k-medoids greedy",color="g",lw=2)
plt.plot(n_clust_ar,revenue_best["kmedoids_exact"][:]/1e6,label="k-medoids exact",color="r",lw=2)
plt.plot(n_clust_ar,revenue_best["hier_centroid"][:]/1e6,label="hierarchical centroid",color="m",lw=2,linestyle=linestyle_ar[1])
plt.plot(n_clust_ar,revenue_best["hier_medoid"][:]/1e6,label="hierarchical medoid",color="m",lw=2,linestyle=linestyle_ar[2])
plt.plot(n_clust_ar,revenue_best["kshape"][:]/1e6,label="k-shape",color="y",lw=2)
plt.plot(n_clust_ar,revenue_best["cmeans"][:]/1e6,label="fuzzy c-means",color="k",lw=2)
ii=0
for j in plot_sc_ar
  ii +=1
  plt.plot(n_clust_ar,revenue_best["dtw"][:,j+1]/1e6,lw=2,label=string("DTW skband=",j),color="k",linestyle=linestyle_ar[ii])
end
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()
plt.xlabel("k")
plt.ylabel("revenue [Mio EUR/USD]")
plt.title(string(problem_type," ",region_))
"""


