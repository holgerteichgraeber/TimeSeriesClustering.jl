CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using JLD2
using FileIO
using PyCall
util_path = normpath(joinpath(CLUST_FOR_OPT,"src","utils"))
unshift!(PyVector(pyimport("sys")["path"]), util_path) # add util path to search path ### unshift!(PyVector(pyimport("sys")["path"]), "") # add current path to search path
@pyimport load_clusters


region = "GER"   # "CA"   "GER"

#### DATA INPUT ######
# Input options:
 # region: "GER", "CA"
 # results_data:
  # kshape_it1000_max20000
  # kshape_it1000_max100
  # kshape_it10000_max100
 # opt_problem:
  # battery
  # gas_turbine

# number of clusters - should be 9
n_k=9

n_clust_min=1
n_clust_max = n_k


result_data = "kshape_it1000_max100"

n_kshape =10
iterations=200

# create directory where data is saved
try
  mkdir("outfiles")
catch
  # do nothing
end

# save settings in txt file
df = DataFrame()
df[:n_clust_min]=n_clust_min
df[:n_clust_max]=n_clust_max
df[:n_kshape]=n_kshape
df[:iterations]=iterations
df[:region]=region

n_clust_ar = collect(n_clust_min:n_clust_max)

writetable(joinpath("outfiles",string("parameters_kshape_",region,".txt")),df)

 ###### load data from pkl and transform to usable format ####

# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

problem_type_ar = ["battery", "gas_turbine"]

# calc hourly mean and sdv, Note: For GER, these are in EUR, since the original data is in EUR
 # sequence based normalization
seq_norm, hourly_mean, hourly_sdv = z_normalize(seq;sequence=true)

 # initialize dictionaries of the loaded data (key: number of clusters)
 # for debugging - DELETE LATER
kshape_centroids_in=[]
kshape_centroids_all=[]


kshape_centroids = Dict()
kshape_labels = Dict()
# kshape_dist_daily = Dict()
kshape_dist = Dict()
kshape_dist_all = Dict()
kshape_iterations = Dict()
ind_conv = Dict()
num_conv = zeros(Int32,n_k) # number of converged values
kshape_weights = Dict()

path_scratch = normpath(joinpath(pwd(),"outfiles","pickle_save" ))

for k=1:n_k
  kshape_iterations[k] = load_clusters.load_pickle(normpath(joinpath(path_scratch,region * "iterations_kshape_" * string(k) * ".pkl")))
  kshape_labels[k] = load_clusters.load_pickle(normpath(joinpath(path_scratch,region * "labels_kshape_" * string(k) * ".pkl"))) .+1  # python to julia indexing
  ind_conv[k] = find(collect(kshape_iterations[k]) .< iterations-1)  # only converged values - collect() transforms tuple to array
  num_conv[k] = length(ind_conv[k])
  kshape_iterations[k] = kshape_iterations[k][ind_conv[k]] #only converged values
  kshape_centroids_in = load_clusters.load_pickle(normpath(joinpath(path_scratch, region * "_centroids_kshape_" * string(k) * ".pkl")))
  # transpose centroids in order to bring them to the same format as dtw, kmeans, etc. 
  kshape_centroids_all=[]
  for i=1:length(kshape_centroids_in)
    push!(kshape_centroids_all,kshape_centroids_in[i]')
  end  ## TODO TEST
  #### back transform centroids from normalized data
  kshape_centroids[k] = zeros(size(kshape_centroids_all[1])[1],size(kshape_centroids_all[1])[2],num_conv[k]) # only converged values
  for i=1:num_conv[k]
    kshape_centroids[k][:,:,i] = undo_z_normalize(kshape_centroids_all[ind_conv[k][i]],hourly_mean,hourly_sdv; idx=kshape_labels[k][ind_conv[k][i]])
  end
  kshape_dist[k] = load_clusters.load_pickle(normpath(joinpath(path_scratch,region * "distance_kshape_" * string(k) * ".pkl")))[ind_conv[k]] # only converged
  kshape_dist_all[k] = load_clusters.load_pickle(normpath(joinpath(path_scratch,region * "distance_kshape_" * string(k) * ".pkl")))
  # calculate weights
  kshape_weights[k] = zeros(k,num_conv[k]) # only converged
  for i=1:num_conv[k]
    for j=1:length(kshape_labels[k][ind_conv[k][i]])
        kshape_weights[k][kshape_labels[k][ind_conv[k][i]][j],i] +=1
    end
    kshape_weights[k][:,i] = kshape_weights[k][:,i]/length(kshape_labels[k][ind_conv[k][i]])
  end


end #k=1:n_k

 ##### end of load data from  pickle ###########


   # initialize dictionaries of the loaded data (key: number of clusters)
  ########
 ###### 
 ###
  # TODO: eliminate n_kshape, substitue num_conv -> make cost and iter Dicts as well  - there must be zeros in revenue (now solved) and in cost -> which leads to the 0/0 pair in the plot
  centers = Dict{Tuple{Int,Int},Array}()
  clustids = Dict{Tuple{Int,Int},Array}()
  cost = Dict{Int,Array}()
  iter =  Dict{Int,Array}()
  weights = Dict{Tuple{Int,Int},Array}()
  revenue = Dict{String,Dict}() 
  for i=1:length(problem_type_ar)
    revenue[problem_type_ar[i]] = Dict{Int,Array}() # could do this one as well: []
# zeros(length(n_clust_ar),n_kshape)
  end

   # iterate through settings
  for n_clust_it=1:length(n_clust_ar)
    n_clust = n_clust_ar[n_clust_it] # use for indexing Dicts
      cost[n_clust] = zeros(Float64,num_conv[n_clust_it])
      iter[n_clust] = zeros(Int,num_conv[n_clust_it])
      # initialize revenue array within dict
      for ii=1:length(problem_type_ar)
        revenue[problem_type_ar[ii]][n_clust] = zeros(Float64,num_conv[n_clust_it])
      end
      for i = 1:num_conv[n_clust_it]
          centers[n_clust,i]= kshape_centroids[n_clust_it][:,:,i]
          clustids[n_clust,i] = kshape_labels[n_clust_it][i] 
          cost[n_clust][i] = kshape_dist[n_clust_it][i]
          iter[n_clust][i] = kshape_iterations[n_clust_it][i]
          weights[n_clust,i] =  kshape_weights[n_clust_it][:,i]   # weights 
        # run opt
        for ii=1:length(problem_type_ar)
          revenue[problem_type_ar[ii]][n_clust][i]=sum(run_opt(problem_type_ar[ii],(centers[n_clust,i]),weights[n_clust,i],region,false))
        end 
     
      end
  end


   # save files to jld2 file


  save_dict = Dict("centers"=>centers,
                   "clustids"=>clustids,
                   "cost"=>cost,
                   "iter"=>iter,
                   "weights"=>weights,
                   "revenue"=>revenue )
                    
  save(string(joinpath("outfiles","aggregated_results_kshape_"),region,".jld2"),save_dict)
  println("kshape data revenue calculated + saved.")

 
