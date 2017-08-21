## Before running this file, dbaclust_res_to_jld.jl has to be run once
 
 # imports
push!(LOAD_PATH, normpath(joinpath(pwd(),".."))) #adds the location of ClustForOpt to the LOAD_PATH
push!(LOAD_PATH, "/data/cees/hteich/clustering/src")
using ClustForOpt
using JLD

using PyPlot
using DataFrames
plt = PyPlot

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles","parameters.txt"))
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
 
# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

 # opt problem
problem_type = "battery"


 # load saved JLD data
saved_data_dict= load("outfiles/aggregated_results.jld")
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
 #inner_iter =  zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)
 #weights = Dict{Tuple{Int,Int,Int},Array}()
 #revenue = zeros(length(n_clust_ar),length(rad_sc_ar),n_dbaclust)






 # TODO 
 # Find best cost index - save
ind_mincost = findmin(cost,3)[2]  # along dimension 3
ind_mincost = reshape(ind_mincost,size(ind_mincost,1),size(ind_mincost,2))




# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

 #### Figures #######
plot_sc_ar = [0,1,2,3,4]  # [0,5,10,15,20,24]
figure()
for j in plot_sc_ar
  plt.plot(n_clust_ar,revenue[:,j+1,1]/1e6,lw=2,label=string("skband=",j))
end
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()

 # function plot cost vs revenue  
function plot_cost_rev(sc_ind)
  figure()
  for i=1:9
    plt.plot(cost[i,sc_ind,:],revenue[i,sc_ind,:],".",label=string(i))
  end
  plt.title(string("sc_ind=",sc_ind))
  plt.legend()
  plt.xlabel("cost")
  plt.ylabel("revenue")
end #function

plot_cost_rev(1)

 # plot iterations and inner iterations
sc_ind=1
figure()
boxplot(inner_iter[:,sc_ind,:]')
plt.title("iterations inner")

 # cumulative cost
 # TODO - random indice generator for k - generate many sample paths in this way
cum_cost=zeros(cost)
for i=1:size(cost,1)
  for j=1:size(cost,2)
    for k=1:size(cost,3)
      cum_cost[i,j,k]=minimum(cost[i,j,1:k])
    end
  end
end
figure()
plt.plot(cum_cost[k_ind,sc_ind,:])  
plt.title("best minimum cost to it")





plt.show()
