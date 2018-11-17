
function run_clust_kmedoids_exact_medoid(
    data_norm::ClustInputDataMerged,
    n_clust::Int,
    iterations::Int;
    gurobi_env=0
    )
   
    (typeof(gurobi_env)==Int) && @error("Please provide a gurobi_env (Gurobi Environment). See test file for example")
    
    # TODO: optional in future: pass distance metric as kwargs
    dist = SqEuclidean()
    results = kmedoids_exact(data_norm.data,n_clust,gurobi_env;_dist=dist)#;distance_type_ar[dist])
    clustids = results.assignments
    centers_norm = results.medoids
    centers = undo_z_normalize(centers_norm,data_norm.mean,data_norm.sdv;idx=clustids)
    cost = results.totalcost
    iter = 1

    weights = calc_weights(clustids,n_clust)
    
    return centers,weights,clustids,cost,iter
end

"""
OLD
"""
function run_clust_kmedoids_exact_medoid(
      region::String,
      opt_problems::Array{String},
      norm_op::String,
      norm_scope::String,
      n_clust_ar::Array,
      n_init::Int,
      iterations::Int;
      gurobi_env=0
    )
   
    (typeof(gurobi_env)==Int) && @error("Please provide a gurobi_env (Gurobi Environment). See test file for example")

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

    writetable(joinpath("outfiles",string("parameters_kmedoids_exact_",region,".txt")),df)

    # normalized clustering hourly
    seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,scope="full")

     
    problem_type_ar = ["battery", "gas_turbine"]

      centers = Dict{Tuple{Int,Int},Array}()
      clustids = Dict{Tuple{Int,Int},Array}()
      cost = zeros(length(n_clust_ar),n_init)
      iter =  zeros(length(n_clust_ar),n_init)
      weights = Dict{Tuple{Int,Int},Array}()
      revenue = Dict{String,Array}() 
      for i=1:length(problem_type_ar)
        revenue[problem_type_ar[i]] = zeros(length(n_clust_ar),n_init)
      end

      
    distance_type_ar = [SqEuclidean()]#, Cityblock()]
    distance_descr = ["SqEuclidean"]#, "Cityblock"]

    for dist = 1:length(distance_type_ar)

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
             
              results = kmedoids_exact(seq_norm,n_clust,gurobi_env)#;distance_type_ar[dist])

              # save clustering results
              centers_norm = results.medoids
              clustids[n_clust,i] = results.assignments
              centers[n_clust,i]=  undo_z_normalize(centers_norm,hourly_mean,hourly_sdv)  
              cost[n_clust,i] = results.totalcost
              iter[n_clust,i] = 1
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


      save_dict = Dict("centers"=>deepcopy(centers),
                       "clustids"=>deepcopy(clustids),
                       "cost"=>deepcopy(cost),
                       "iter"=>deepcopy(iter),
                       "weights"=>deepcopy(weights),
                       "revenue"=>deepcopy(revenue) )
                        
      save(string(joinpath("outfiles","aggregated_results_kmedoids_exact_"),distance_descr[dist],"_",region,".jld2"),save_dict)
      println("kmedoids exact ",distance_descr[dist] ," data revenue calculated + saved.")


    return save_dict
    end # for dist=1:length(dist_type_ar)
    

end # function
