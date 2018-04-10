 # imports
CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

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
n_cmeans=param[:n_cmeans][1]
iterations=param[:iterations][1]
region=param[:region][1]

n_clust_ar = collect(n_clust_min:n_clust_max)
 
# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

 # opt problem
problem_type = "battery"


 # load saved JLD data
saved_data_dict= load(joinpath("outfiles","aggregated_results_cmeans_fuzzy_2.0.jld2"))
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






 # TODO 
 # Find best cost index - save
ind_mincost = findmin(cost,2)[2]  # along dimension 2
ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
revenue_best = zeros(size(revenue,1))
for i=1:size(revenue,1)
    revenue_best[i]=revenue[ind_mincost[i]] 
end

ind_mincost_2 = ind2sub(cost,ind_mincost)[2]


# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

 #### Figures #######
figure()
plt.plot(n_clust_ar,revenue_best[:]/1e6,lw=2)
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()

 # function plot cost vs revenue  
function plot_cost_rev()
  figure()
  for i=1:length(n_clust_ar)
    plt.plot(cost[i,:],revenue[i,:]/1e6,".",label=string("k=",n_clust_ar[i]))
  end
  plt.title(string("cost vs revenue"))
  plt.legend()
  plt.xlabel("cost")
  plt.ylabel("revenue [mio EUR]")
end #function

plot_cost_rev()

 # plot iterations and iterations
figure()
boxplot(iter[:,:]')
plt.title("iterations")

 # cumulative cost
 # TODO - random indice generator for k - generate many sample paths in this way

function plot_cum_cost(cost,k_ind,n_perm)
  cum_cost=zeros(size(cost,2),n_perm)
   #n_perm=20 # number of permutations
  figure()
  for i=1:n_perm
    cost_perm = cost[k_ind,:][randperm(size(cost,2))]
    for k=1:size(cost,2)
      cum_cost[k,i]=minimum(cost_perm[1:k])
    end
    plt.plot(cum_cost[:,i],color="grey",alpha=0.4)  
  end
  plt.xlabel("No. of trials")
  plt.ylabel("cost [clustering algorithm]")
  plt.title(string("k=",k_ind,", No. of permutations:",n_perm))
end # function

plot_cum_cost(cost,2,20)

figure()
boxplot(revenue')
plot(collect(1:length(n_clust_ar)),revenue_best,label="best cost")
plt.legend()
plt.ylabel("revenue")

 # plot clusters k=1:9

for n_clust=1:9
  figure()
  plt.plot(centers[n_clust,ind_mincost_2[n_clust]])
  plt.title(string("k=",n_clust))
end




plt.show()
