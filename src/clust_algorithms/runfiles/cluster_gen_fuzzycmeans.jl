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
n_cmeans =100


 # iterations
iterations = 100

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
df[:n_cmeans]=n_cmeans
df[:iterations]=iterations
df[:region]=region

n_clust_ar = collect(n_clust_min:n_clust_max)

writetable(joinpath("outfiles",string("parameters_cmeans_",region,".txt")),df)

# normalized clustering hourly
seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,hourly=true)

 
problem_type_ar = ["battery", "gas_turbine"]

fuzzyness = [2.0]

for fuzz in fuzzyness

tic()

   # initialize dictionaries of the loaded data (key: number of clusters)
  centers = Dict{Tuple{Int,Int},Array}()
  clustids = Dict{Tuple{Int,Int},Array}()
  cost = zeros(length(n_clust_ar),n_cmeans)
  iter =  zeros(length(n_clust_ar),n_cmeans)
  weights = Dict{Tuple{Int,Int},Array}()
  revenue = Dict{String,Array}() 
  for i=1:length(problem_type_ar)
    revenue[problem_type_ar[i]] = zeros(length(n_clust_ar),n_cmeans)
  end


   # iterate through settings
  for n_clust_it=1:length(n_clust_ar)
    n_clust = n_clust_ar[n_clust_it] # use for indexing Dicts
      for i = 1:n_cmeans
        if n_clust ==1 
          centers_norm = mean(seq_norm,2) # should be 0 due to normalization
          centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)          
          centers[n_clust,i]=centers_ #transpose to match optimization formulation 
          clustids[n_clust,i] = ones(Int,size(seq,2))
          cost[n_clust_it,i] = sum(pairwise(SqEuclidean(),centers_norm,seq_norm)) #same as sum((seq_norm-repmat(mean(seq_norm,2),1,size(seq,2))).^2)
          iter[n_clust_it,i] = 1
          
          # calculate weights
          weights[n_clust,i] = zeros(n_clust) 
          for j=1:length(clustids[n_clust,i])
              weights[n_clust,i][clustids[n_clust,i][j]] +=1
          end
          weights[n_clust,i] =  weights[n_clust,i] /length(clustids[n_clust,i])
        else
          results = fuzzy_cmeans(seq_norm,n_clust,fuzz;maxiter=iterations)

          # save clustering results
          centers_norm = results.centers
          centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)    
          centers[n_clust,i]=centers_ 
          clustids[n_clust,i] = ones(Int,size(seq,2)) # irrelevant, thus set arbitrarily
          cost[n_clust_it,i] = 0
          for ii=1:size(seq,2)
            for jj=1:n_clust
              cost[n_clust_it,i] += results.weights[ii,jj]*sum((seq_norm[:,ii]-results.centers[:,jj]).^2)
            end
          end
          iter[n_clust_it,i] = results.iterations
          weights[n_clust,i] =  sum(results.weights,1)'    # weights 
          weights[n_clust,i] =  weights[n_clust,i] /length(clustids[n_clust,i])
        end
         ##########################
        


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
                    
  save(string("outfiles/aggregated_results_cmeans_","fuzzy_",fuzz,"_",region,".jld2"),save_dict)
  println("cmeans data revenue calculated + saved.")

toc()

end # fuzz in fuzzyness

