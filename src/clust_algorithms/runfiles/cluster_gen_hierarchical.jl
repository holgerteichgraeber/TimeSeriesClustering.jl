push!(LOAD_PATH, normpath(joinpath(pwd(),"..",".."))) #adds the location of ClustForOpt to the LOAD_PATH
push!(LOAD_PATH, normpath(joinpath("/data/cees/hteich/clustering/src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using Distances
using Clustering
using JLD2
using FileIO

using PyCall
util_path = normpath(joinpath("/data","cees","hteich","clustering","src","clust_algorithms"))
unshift!(PyVector(pyimport("sys")["path"]), util_path) # add util path to search path ### unshift!(PyVector(pyimport("sys")["path"]), "") # add current path to search path
@pyimport hierarchical


 ######## DATA INPUT ##########

 # region
region = "GER"


# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

println("data loaded")

# number of clusters
n_clust_min =1
n_clust_max =9

# initial points
n_hier =1


 # iterations
iterations = 300

 ############################################

# create directory where data is saved
try
  mkdir("outfiles")
catch
  rm("outfiles",recursive=true)
  mkdir("outfiles")
end

# save settings in txt file
df = DataFrame()
df[:n_clust_min]=n_clust_min
df[:n_clust_max]=n_clust_max
df[:n_hier]=n_hier
df[:iterations]=iterations
df[:region]=region

n_clust_ar = collect(n_clust_min:n_clust_max)

writetable(joinpath("outfiles",string("parameters_hier_",region,".txt")),df)

# normalized clustering hourly
seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,hourly=true)

 
problem_type_ar = ["battery", "gas_turbine"]


centroid_descr = ["centroid","medoid"]

for centr = 1:length(centroid_descr)

   # initialize dictionaries of the loaded data (key: number of clusters)
  centers = Dict{Tuple{Int,Int},Array}()
  clustids = Dict{Tuple{Int,Int},Array}()
  cost = zeros(length(n_clust_ar),n_hier)
  iter =  zeros(length(n_clust_ar),n_hier)
  weights = Dict{Tuple{Int,Int},Array}()
  revenue = Dict{String,Array}() 
  for i=1:length(problem_type_ar)
    revenue[problem_type_ar[i]] = zeros(length(n_clust_ar),n_hier)
  end

   
   # iterate through settings
  for n_clust_it=1:length(n_clust_ar)
    n_clust = n_clust_ar[n_clust_it] # use for indexing Dicts
      for i = 1:n_hier
        results = hierarchical.run_hierClust(seq_norm',n_clust) # transpose input data because scikit learn has opposite convention of julia clustering

        # save clustering results
        if centroid_descr[centr] == "centroid"
          centers_norm = results["centers"]' # transpose back 
          centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)    
          centers[n_clust,i]=centers_ 
        elseif centroid_descr[centr] == "medoid" 
          centers[n_clust,i] = seq[:,round.(Int,results["closest_day_ind"])+1] 
        end
        clustids[n_clust,i] = results["labels"]+1
        cost[n_clust_it,i] = results["SSE"]
        iter[n_clust_it,i] = 1
         ##########################
        
        # calculate weights
        weights[n_clust,i] = zeros(n_clust) 
        for j=1:length(clustids[n_clust,i])
            weights[n_clust,i][clustids[n_clust,i][j]] +=1
        end
        weights[n_clust,i] =  weights[n_clust,i] /length(clustids[n_clust,i])

        # run opt
        for ii=1:length(problem_type_ar)
          revenue[problem_type_ar[ii]][n_clust_it,i]=sum(run_opt(problem_type_ar[ii],(centers[n_clust,i]),weights[n_clust,i],region,false))
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
                    
  save(string("outfiles/aggregated_results_hier_",centroid_descr[centr],"_",region,".jld2"),save_dict)
  println("hier data revenue calculated + saved.")

end # centr = 1:length(centroid_descr)

