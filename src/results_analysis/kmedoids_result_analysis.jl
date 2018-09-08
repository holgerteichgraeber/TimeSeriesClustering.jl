using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

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
saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kmedoids_"),dist_type,"_",region,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue=revenue[problem_type] 


 # load saved JLD data - exact algorithm of kmedoids
saved_data_dict_exact= load(string(joinpath("outfiles","aggregated_results_kmedoids_exact_"),dist_type,"_",region,".jld2"))
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

 #### Figures #######


clust_methods = Array{Dict,1}()

 # revenue vs. k
push!(clust_methods,Dict("name"=>"full representation", "rev"=> revenue_orig_daily*ones(length(n_clust_ar)),"color"=>"c","linestyle"=>"--","width"=>3))
push!(clust_methods,Dict("name"=>"k-medoids", "rev"=> revenue_best[:],"color"=>"b","linestyle"=>"-","width"=>2))  
plot_k_rev(n_clust_ar,clust_methods,string(joinpath("plots","kmedoids_"),region,".png"))


 # revenue vs. SSE
 # averaging
cost_rev_clouds = Dict()
cost_rev_points = Array{Dict,1}()
descr=string(joinpath("plots","cloud_kmedoids_"),region,".png")

cost_rev_clouds["cost"]=cost
cost_rev_clouds["rev"] = revenue

push!(cost_rev_points,Dict("label"=>"kmedoids best","cost"=>cost_best,"rev"=>revenue_best,"mec"=>"k","mew"=>2.0,"marker"=>"s" ))

plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily)


figure()
plt.plot(n_clust_ar,revenue_best[:]/1e6,label="k-medoids greedy",color="b",lw=2)
plt.plot(n_clust_ar,revenue_exact_best[:]/1e6,label="k-medoids exact",color="k",lw=2)
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()

 # function plot cost vs revenue  
function plot_cost_rev()
  figure()
  for i=1:length(n_clust_ar)
    plt.plot(cost[i,:],revenue[i,:]/1e6,".",label=string("k=",n_clust_ar[i]))
  end
  for i=1:length(n_clust_ar)
    plt.plot(cost_exact[i,:],revenue_exact[i,:]/1e6,".",label=string("k=",n_clust_ar[i]," exact"),mec="k",mew=10,fillstyle="none") # mec="k"
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


plt.show()
