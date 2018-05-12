CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using Distances
using Clustering
using JLD2
using FileIO

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
n_kmeans =10000


 # iterations
iterations = 300

 ############################################

# create directory where data is saved
try
  mkdir("outfiles")
catch
 # 
end

# save settings in txt file
df = DataFrame()
df[:n_clust_min]=n_clust_min
df[:n_clust_max]=n_clust_max
df[:n_kmeans]=n_kmeans
df[:iterations]=iterations
df[:region]=region

n_clust_ar = collect(n_clust_min:n_clust_max)

writetable(joinpath("outfiles",string(string("parameters_kmeans_",region,".txt"))),df)

# normalized clustering hourly
seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,scope="full")

 
problem_type_ar = ["battery", "gas_turbine"]

 # initialize dictionaries of the loaded data (key: number of clusters)
centers = Dict{Tuple{Int,Int},Array}()
clustids = Dict{Tuple{Int,Int},Array}()
cost = zeros(length(n_clust_ar),n_kmeans)
iter =  zeros(length(n_clust_ar),n_kmeans)
weights = Dict{Tuple{Int,Int},Array}()
revenue = Dict{String,Array}() 
for i=1:length(problem_type_ar)
  revenue[problem_type_ar[i]] = zeros(length(n_clust_ar),n_kmeans)
end

 
 # iterate through settings
for n_clust_it=1:length(n_clust_ar)
  n_clust = n_clust_ar[n_clust_it] # use for indexing Dicts
    for i = 1:n_kmeans
      if n_clust ==1 
        centers_norm = mean(seq_norm,2) # should be 0 due to normalization
        centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)          
        centers[n_clust,i]=centers_ #transpose to match optimization formulation 
        clustids[n_clust,i] = ones(Int,size(seq,2))
        cost[n_clust_it,i] = sum(pairwise(SqEuclidean(),centers_norm,seq_norm)) #same as sum((seq_norm-repmat(mean(seq_norm,2),1,size(seq,2))).^2)
        iter[n_clust_it,i] = 1
      else
        results = kmeans(seq_norm,n_clust;maxiter=iterations)

        # save clustering results
        centers_norm = results.centers
        centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)    
        centers[n_clust,i]=centers_ 
        clustids[n_clust,i] = results.assignments
        cost[n_clust_it,i] = results.totalcost
        iter[n_clust_it,i] = results.iterations
      end
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
                  
save(string(joinpath("outfiles","aggregated_results_kmeans_"),region,".jld2"),save_dict)
println("kmeans data revenue calculated + saved.")






