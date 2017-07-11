# imports
push!(LOAD_PATH, normpath(joinpath(pwd(),".."))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt

using PyPlot
using DataFrames
plt = PyPlot

close("all")

#### DATA INPUT ######
 # Input options:
 # region: "GER", "CA"
 # results_data:
  # kshape_it1000_max20000
  # kshape_it1000_max100
  # kshape_it10000_max100
 # opt_problem:
  # storage
  # gas
  # storage and gas

# number of clusters - should be 9
n_k=9

# region:
region = "GER"   # "CA"   "GER"
result_data = "kshape_it1000_max100"
 # opt problem


 ############################
if result_data == "kshape_it1000_max20000"
  n_init =1000
  data_folder = "kshape_results"
elseif result_data == "kshape_it1000_max100"
  n_init =1000
  data_folder = "kshape_results_itmax"
end


# read in original data
if region =="CA"
  region_str = ""
  region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.txt"))
else
  region_str = "GER_"
  region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.txt"))
end
data_orig = Array(readtable(region_data, separator = '\t', header = false)) 
data_orig_daily = reshape(data_orig,24,365)
 
# Load kshape clusters 
# calc hourly mean and sdv, Note: For GER, these are in EUR, since the original data is in EUR
hourly_mean = zeros(size(data_orig_daily)[1])
hourly_sdv = zeros(size(data_orig_daily)[1])
for i=1:size(data_orig_daily)[1]
  hourly_mean[i] = mean(data_orig_daily[i,:])
  hourly_sdv[i] = std(data_orig_daily[i,:])
end

 # initialize dictionaries of the loaded data (key: number of clusters)
kshape_centroids = Dict() 
kshape_labels = Dict()
# kshape_dist_daily = Dict()
kshape_dist = Dict()
kshape_dist_all = Dict()
kshape_iterations = Dict()
ind_conv = Dict()
num_conv = zeros(Int32,n_k) # number of converged values
kshape_weights = Dict()


for k=1:n_k 
  kshape_iterations[k] = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data",data_folder,region * "iterations_kshape_" * string(k) * ".pkl")))
  ind_conv[k] = find(collect(kshape_iterations[k]) .< 19999)  # only converged values - collect() transforms tuple to array
  num_conv[k] = length(ind_conv[k])
  kshape_iterations[k] = kshape_iterations[k][ind_conv[k]] #only converged values
  kshape_centroids_in = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data",data_folder, region * "_centroids_kshape_" * string(k) * ".pkl")))
  #### back transform centroids from normalized data
  kshape_centroids[k] = zeros(size(kshape_centroids_in[1])[1],size(kshape_centroids_in[1])[2],num_conv[k]) # only converged values
  for i=1:num_conv[k]
    kshape_centroids[k][:,:,i] = (kshape_centroids_in[ind_conv[k][i]].* hourly_sdv' + ones(k)*hourly_mean')
  end
  kshape_labels[k] = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data",data_folder,region * "labels_kshape_" * string(k) * ".pkl"))) 
  kshape_dist[k] = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data",data_folder,region * "distance_kshape_" * string(k) * ".pkl")))[ind_conv[k]] # only converged
  kshape_dist_all[k] = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data",data_folder,region * "distance_kshape_" * string(k) * ".pkl")))
  # calculate weights
  kshape_weights[k] = zeros(size(kshape_centroids[k][:,:,1])[1],num_conv[k]) # only converged
  for i=1:num_conv[k]
    for j=1:length(kshape_labels[k][ind_conv[k][i]])
        kshape_weights[k][kshape_labels[k][ind_conv[k][i]][j]+1,i] +=1
    end
    kshape_weights[k][:,i] = kshape_weights[k][:,i]/length(kshape_labels[k][ind_conv[k][i]])
  end


end #k=1:n_k

 # loaded best data (with best distance calculated in python) for comparison
saved_data = []
saved_weights = []
revenue_saved = []
for k=1:n_k
  push!(saved_data,Array(readtable(normpath(joinpath(pwd(),"..","..","data",data_folder,string(region_str, "Elec_Price_kmeans_","kshape","_","cluster", "_", k,".txt"))), separator = '\t', header = false))/get_EUR_to_USD(region));
  push!(saved_weights,Array(readtable(normpath(joinpath(pwd(),"..","..","data",data_folder,string(region_str, "Weights_kmeans_","kshape","_","cluster", "_",k,".txt"))), separator = '\t', header = false)))
  push!(revenue_saved,sum(run_battery_opt(saved_data[k]',saved_weights[k],false)));
end

# optimization on original data
revenue_orig_daily = sum(run_battery_opt(data_orig_daily));

# optimization on kshape data
revenue_ksh = zeros(n_init,n_k)
revenue_ksh_plotting = []
for k=1:n_k
  for i=1:num_conv[k] # try @parallel here? / need for shared array?
    revenue_ksh[i,k] = sum(run_battery_opt(kshape_centroids[k][:,:,i]',kshape_weights[k][:,i],false));
  end
  revenue_ksh_plotting = push!(revenue_ksh_plotting, revenue_ksh[1:num_conv[k],k])
end

 # find best distance 
ind_best_dist = zeros(Int32,n_k) #only converged 
best_dist = zeros(n_k)
ind_best_dist_all = zeros(Int32,n_k) #includes non-converged 
rev_best_dist = zeros(n_k) # only converged
for k=1:n_k
  best_dist[k],ind_best_dist[k] = findmin(kshape_dist[k])
  ind_best_dist_all[k] = findmin(kshape_dist_all[k])[2]
  rev_best_dist[k] = revenue_ksh[ind_best_dist[k],k]
end

# reformat Dictionaries for plotting

kshape_dist_plotting = []
iterations_plotting =[]
for k=1:n_k
  kshape_dist_plotting = push!(kshape_dist_plotting, kshape_dist[k])
  iterations_plotting = push!(iterations_plotting, kshape_iterations[k])
end

 ### print some convergence statistics ###
for k=1:n_k
  println("Number of converged cases at k=",k,": ",num_conv[k])
end


 ###### Figures ########

# Boxplot revenue
figure()
boxplot(revenue_ksh_plotting/1e6)
hold
plt.plot(1:n_k,rev_best_dist/1e6,color="blue",lw=2,label="best distance") 
plt.plot(1:n_k,revenue_saved/1e6,color="red",lw=2,label="python")
plt.plot(1:n_k,revenue_orig_daily/1e6*ones(n_k),label="365 days",color="c",lw=3)
plt.xlabel("Number of clusters",fontsize=25)
if region == "CA"
  plt.ylabel("Revenue [Mio USD/year]",fontsize=25)
else
  plt.ylabel("Revenue [Mio EUR/year]",fontsize=25)
end
plt.ylim(3000000*1e-6, 6500000*1e-6 )
ax  =axes()
ax[:tick_params]("both")
plt.title("k_shape "*string(n_init)*" initial runs" )
plt.legend(loc=2,fontsize=20)
plt.tight_layout()



 # \TODO
  # boxplot of distances
figure()
boxplot(kshape_dist_plotting)
plt.plot(1:n_k,best_dist,color="blue",label="best distance")
plt.legend()
plt.title("kshape distances")
plt.tight_layout()

# distance vs. revenue (parity plot,one plot for each k)
 #=
for k=1:n_k
  figure()
  plt.plot(kshape_dist[k], revenue_ksh_plotting[k],linestyle="None",marker=".")
  plt.title(string("k=",k))
  plt.xlabel("distance")
  plt.ylabel("revenue")
end
=#

 # histogram of number of iterations (one for each k), or boxplots of number of iterations (all in one plot, k on x axis)
figure()
boxplot(iterations_plotting)
plt.title("kshape iterations")
plt.tight_layout()

# plot iterations vs. distance

for k=1:n_k
  figure()
  plt.plot(kshape_iterations[k],kshape_dist[k],linestyle="None",marker=".")
  plt.title(string("k=",k))
  plt.xlabel("iterations")
  plt.ylabel("distance")
  plt.title(string("distance vs. iterations: k=",k))
end

 # plot iterations vs. revenue
  
for k=1:n_k
  figure()
  plt.plot(kshape_iterations[k],revenue_ksh_plotting[k],linestyle="None",marker=".")
  plt.title(string("k=",k))
  plt.xlabel("iterations")
  plt.ylabel("revenue")
  plt.title(string("revenue vs. iterations: k=",k))
end

  
if is_linux()
  plt.show()
end
