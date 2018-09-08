## Before running this file, dbaclust_res_to_jld.jl has to be run once
 
using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

using PyPlot
using DataFrames
plt = PyPlot

 # region
region_ = "GER"
 
 # read parameters
param=DataFrame()
try
  param = readtable(joinpath("outfiles_jld2",string("parameters_dtw_",region_,".txt")))
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
saved_data_dict= load(string(joinpath("outfiles_jld2","aggregated_results_dtw_"),region,".jld2"))
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
revenue_best = zeros(size(revenue,1),size(revenue,2))
for i=1:size(revenue,1)
  for j=1:size(revenue,2)
    revenue_best[i,j]=revenue[ind_mincost[i,j]] 
  end
end



# optimization on original data
revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

 #### Figures #######
plot_sc_ar = [0,1,2,3,4]  # [0,5,10,15,20,24]
figure()
for j in plot_sc_ar
  plt.plot(n_clust_ar,revenue_best[:,j+1]/1e6,lw=2,label=string("skband=",j))
end
plt.plot(n_clust_ar,revenue_orig_daily/1e6*ones(length(n_clust_ar)),label="365 days",color="c",lw=3)
plt.legend()

 # function plot cost vs revenue  
function plot_cost_rev(sc_ind)
  figure()
  for i=1:9
    plt.plot(cost[i,sc_ind,:],revenue[i,sc_ind,:]/1e6,".",label=string("k=",i))
  end
  plt.title(string("Sakoe Chiba Band Width=",sc_ind-1))
  plt.legend()
  plt.xlabel("cost")
  plt.ylabel("revenue [mio EUR]")
end #function

plot_cost_rev(1)

 # plot iterations and inner iterations
sc_ind=1
figure()
boxplot(inner_iter[:,sc_ind,:]')
plt.title("iterations inner")

function print_conv(sc_ind)
println("Inner Iterations: Convergence skband=",sc_ind)
  for i=1:9
    println("Not converged: k=",i," :",count(inner_iter[i,sc_ind,:].==inner_iterations)/count(inner_iter[i,sc_ind,:].<=inner_iterations)) 
  end
println("Iterations: Convergence skband=",sc_ind)
  for i=1:9
    println("Not converged: k=",i," :",count(iter[i,sc_ind,:].==iterations)/count(iter[i,sc_ind,:].<=iterations)) 
  end
end
print_conv(sc_ind)

 # cumulative cost
 # TODO - random indice generator for k - generate many sample paths in this way

function plot_cum_cost(cost,k_ind,sc_width,n_perm)
  cum_cost=zeros(size(cost,3),n_perm)
  sc_ind=sc_width+1
   #n_perm=20 # number of permutations
  figure()
  for i=1:n_perm
    cost_perm = cost[k_ind,sc_ind,:][randperm(size(cost,3))]
    for k=1:size(cost,3)
      cum_cost[k,i]=minimum(cost_perm[1:k])
    end
    plt.plot(cum_cost[:,i],color="grey",alpha=0.4)  
  end
  plt.xlabel("No. of trials")
  plt.ylabel("cost [clustering algorithm]")
  plt.title(string("k=",k_ind,", SakoeChibaWidth=",sc_width,", No. of permutations:",n_perm))
end # function

plot_cum_cost(cost,2,0,20)


plt.show()
