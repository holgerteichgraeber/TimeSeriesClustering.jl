# before running this file, run kshape_res_to_jld2.jl
  
using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

using PyPlot
using DataFrames
plt = PyPlot

region = "GER"  # GER , CA

 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles",string("parameters_kshape_",region,".txt")))
catch
  @error("No input file parameters.txt exists in folder outfiles.")
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
saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kshape_"),region,".jld2"))
 #unpack saved JLD data
 for (k,v) in saved_data_dict
   @eval $(Symbol(k)) = $v
 end

 #set revenue to the chosen problem type
revenue=revenue[problem_type] 

 # initialize dictionaries of the loaded data (key: number of clusters)
 #centers = Dict{Tuple{Int,Int,Int},Array}()
 #clustids = Dict{Tuple{Int,Int,Int},Array}()
 #  cost = Dict{Int,Array}()
 # iter =  Dict{Int,Array}()
 #weights = Dict{Tuple{Int,Int,Int},Array}()
 #revenue = Dict{String,Dict}() 






 # TODO 
 # Find best cost index - save
ind_mincost = zeros(Int,size(n_clust_ar,1))
for i=1:size(n_clust_ar,1)
  ind_mincost[i] = findmin(cost[i])[2] 
end
revenue_best = zeros(size(n_clust_ar,1))
cost_best = zeros(size(n_clust_ar,1))
for i=1:size(n_clust_ar,1)
    revenue_best[i]=revenue[i][ind_mincost[i]] 
    cost_best[i]=cost[i][ind_mincost[i]] 
end



# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

 #### Figures #######

  
clust_methods = Array{Dict,1}()

 # revenue vs. k
push!(clust_methods,Dict("name"=>"full representation", "rev"=> revenue_orig_daily*ones(length(n_clust_ar)),"color"=>"c","linestyle"=>"--","width"=>3))
push!(clust_methods,Dict("name"=>"k-shape", "rev"=> revenue_best[:],"color"=>"b","linestyle"=>"-","width"=>2))  
plot_k_rev(n_clust_ar,clust_methods,string(joinpath("plots","kshape_"),region,".png"))
  
  
 # revenue vs. SSE
 # averaging
cost_rev_clouds = Dict()
cost_rev_points = Array{Dict,1}()
descr=string(joinpath("plots","cloud_kshape_"),region,".png")

cost_rev_clouds["cost"]=[cost[i] for i in 1:size(n_clust_ar,1)]
cost_rev_clouds["rev"] = [revenue[i] for i in 1:size(n_clust_ar,1)]

push!(cost_rev_points,Dict("label"=>"k-shape best","cost"=>cost_best,"rev"=>revenue_best,"mec"=>"k","mew"=>2.0,"marker"=>"s" ))

plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily)
  
  
  
  
  
  
 ## old stuff
  
  figure()
plt.plot(n_clust_ar,revenue_best[:]/1e6,lw=2)
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()


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


 # ind_mincost_2 = ind2sub(cost,ind_mincost)[2]
 # plot clusters k=1:9

 #for n_clust=1:9
 #  figure()
 # plt.plot(centers[n_clust,ind_mincost_2[n_clust]])
 # plt.title(string("k=",n_clust))
 #end




plt.show()
