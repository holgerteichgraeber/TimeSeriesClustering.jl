function run_clust_kmeans_medoid(
      region::String,
      opt_problems::Array{String},
      norm_op::String,
      norm_scope::String,
      n_clust_ar::Array,
      n_init::Int,
      iterations::Int
    )

    n_clust_min = minimum(n_clust_ar)
    n_clust_max = maximum(n_clust_ar)

    # read in original data
    seq = load_pricedata(region)

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
    df[:n_init]=n_init
    df[:iterations]=iterations
    df[:region]=region

    n_clust_ar = collect(n_clust_min:n_clust_max)

    writetable(joinpath("outfiles",string(string("parameters_kmeans_medoidrep",region,".txt"))),df)

    # normalized clustering hourly
    seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,scope="full")

     
    problem_type_ar = ["battery", "gas_turbine"]

     # initialize dictionaries of the loaded data (key: number of clusters)
    centers = Dict{Tuple{Int,Int},Array}()
    clustids = Dict{Tuple{Int,Int},Array}()
    cost = zeros(length(n_clust_ar),n_init)
    iter =  zeros(length(n_clust_ar),n_init)
    weights = Dict{Tuple{Int,Int},Array}()
    revenue = Dict{String,Array}() 
    for i=1:length(problem_type_ar)
      revenue[problem_type_ar[i]] = zeros(length(n_clust_ar),n_init)
    end

     
     # iterate through settings
    for n_clust_it=1:length(n_clust_ar)
      n_clust = n_clust_ar[n_clust_it] # use for indexing Dicts
        for i = 1:n_init
          if n_clust ==1 
            centers_norm = mean(seq_norm,2) # should be 0 due to normalization
            #centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)          
            clustids[n_clust,i] = ones(Int,size(seq,2))
            centers[n_clust,i]= undo_z_normalize(find_medoids(seq_norm,centers_norm,clustids[n_clust,i]),hourly_mean,hourly_sdv)  
     # kmeans cost for now
            cost[n_clust_it,i] = sum(pairwise(SqEuclidean(),centers_norm,seq_norm)) #same as sum((seq_norm-repmat(mean(seq_norm,2),1,size(seq,2))).^2)
            iter[n_clust_it,i] = 1
          else
            results = kmeans(seq_norm,n_clust;maxiter=iterations)

            # save clustering results
            centers_norm = results.centers
            #centers_ = undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)    
            clustids[n_clust,i] = results.assignments
            centers_= find_medoids(seq_norm,centers_norm,clustids[n_clust,i]) 
            centers[n_clust,i]=undo_z_normalize(centers_,hourly_mean,hourly_sdv) 
            
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

            ##### recalculate centers
          centers[n_clust,i] = resize_medoids(seq,centers[n_clust,i],weights[n_clust,i])
          
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
                      
    save(string(joinpath("outfiles","aggregated_results_kmeans_medoidrep"),region,".jld2"),save_dict)
    println("kmeans medoid rep. data revenue calculated + saved.")

    return save_dict
end # function



