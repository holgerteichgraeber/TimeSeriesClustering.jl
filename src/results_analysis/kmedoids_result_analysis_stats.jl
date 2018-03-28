 # imports
push!(LOAD_PATH, normpath(joinpath(pwd(),".."))) #adds the location of ClustForOpt to the LOAD_PATH
push!(LOAD_PATH, "/data/cees/hteich/clustering/src")
using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

using Clustering

using PyPlot
using DataFrames
plt = PyPlot

region = "GER" # GER CA

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_kmedoids_",region,".txt")))
catch
  error("No input file parameters.txt exists in folder outfiles.")
end

n_clust_min=param[:n_clust_min][1]
n_clust_max=param[:n_clust_max][1]
n_kmedeoids=param[:n_kmedeoids][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)
 
# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

 # opt problem
problem_type = "battery"

dist_type = "SqEuclidean"   # "SqEuclidean"   "Cityblock"

 # load saved JLD data - kmeans algorithm of kmedoids
saved_data_dict= load(string("outfiles/aggregated_results_kmedoids_",dist_type,"_",region,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue=revenue[problem_type] 


 # load saved JLD data - exact algorithm of kmedoids
saved_data_dict_exact= load(string("outfiles/aggregated_results_kmedoids_exact_",dist_type,"_",region,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict_exact
   @eval $(Symbol(string(k,"_exact"))) = $v
 end

 #set revenue to the chosen problem type
revenue_exact=revenue_exact[problem_type] 


 # initialize dictionaries of the loaded data (key: number of clusters)
 #centers = Dict{Tuple{Int,Int,Int},Array}()
 #clustids = Dict{Tuple{Int,Int,Int},Array}()
 #cost = zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)
 #iter =  zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)
 #weights = Dict{Tuple{Int,Int,Int},Array}()
 #revenue = zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)






 # TODO 
 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best = zeros(size(revenue,1))
cost_best = zeros(size(cost,1))
for i=1:size(revenue,1)
    revenue_best[i]=revenue[ind_mincost[i]] 
    cost_best[i]=cost[ind_mincost[i]] 
end

 # Find best cost index -exact - not necessary, but legacy code
ind_mincost = findmin(cost_exact,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_exact_best = zeros(size(revenue_exact,1))
cost_exact_best = zeros(size(cost_exact,1))
for i=1:size(revenue_exact,1)
    revenue_exact_best[i]=revenue_exact[ind_mincost[i]] 
    cost_exact_best[i]=cost_exact[ind_mincost[i]] 
end


# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

 ###### post-clustering ###

 # Sum of weighted within-day variances
function post_clust(ind,k_km,rev_365)
  SSstd = zeros(revenue)
  for k=1:size(revenue,1)
    for i=1:size(revenue,2)
      for kk=1:k
        SSstd[k,i]+=weights[k,i][kk] * std(centers[k,i][:,kk])^2
      end
    end
  end

  col_ar = ["C0","C1","C2","C3","C4","C5","C6","C7","C8","C9"]
   #ind = 9
   #k_km=3
 r = kmeans(reshape(SSstd[ind,:],1,size(revenue,2)),k_km)
 figure()
 for i=1:size(revenue,2)
    plot(cost[ind,i],revenue[ind,i]/rev_365,".",color=col_ar[r.assignments[i]],alpha=0.2)
 end
 return SSstd
end#function

ind=8
k_km=3 # cluster the locally converged solutions into k_km clusters
SSstd = post_clust(ind,k_km,revenue_orig_daily)
i_s = sortperm(SSstd[ind,:]) # doesnt matter for scatter plot
figure()
plot(SSstd[ind,:],revenue[ind,:],".",alpha=0.2)


kk=9

i_costmin = findmin(cost[kk,:])[2]
i_revmax = findmax(revenue[kk,:])[2]
i_revmin = findmin(revenue[kk,:])[2]

plot_clusters(centers[kk,i_costmin],weights[kk,i_costmin]; descr="CostMin")
plot_clusters(centers[kk,i_revmin],weights[kk,i_revmin]; descr="RevMin")
plot_clusters(centers[kk,i_revmax],weights[kk,i_revmax]; descr="RevMax")

 #### Figures #######


clust_methods = Array{Dict,1}()

 # revenue vs. k
push!(clust_methods,Dict("name"=>"full representation", "rev"=> revenue_orig_daily*ones(length(n_clust_ar)),"color"=>"c","linestyle"=>"--","width"=>3))
push!(clust_methods,Dict("name"=>"k-medoids", "rev"=> revenue_best[:],"color"=>"b","linestyle"=>"-","width"=>2))  
 #plot_k_rev(n_clust_ar,clust_methods,string("plots/kmedoids_",region,".png"))


 # revenue vs. SSE
 # averaging
cost_rev_clouds = Dict()
cost_rev_points = Array{Dict,1}()
descr=string("plots/cloud_kmedoids_",region,".png")

cost_rev_clouds["cost"]=cost
cost_rev_clouds["rev"] = revenue

push!(cost_rev_points,Dict("label"=>"kmedoids best","cost"=>cost_best,"rev"=>revenue_best,"mec"=>"k","mew"=>2.0,"marker"=>"s" ))

 #plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily)



plt.show()
