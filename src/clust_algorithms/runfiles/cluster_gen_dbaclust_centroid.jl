function run_clust_dbaclust_centroid(
      region::String,
      opt_problems::Array{String},
      norm_op::String,
      norm_scope::String,
      n_clust_ar::Array,
      n_init::Int,
      iterations::Int;
      rad_sc_min::Int=0,
      rad_sc_max::Int=3,
      inner_iterations::Int=30
    )

    n_clust_min = minimum(n_clust_ar)
    n_clust_max = maximum(n_clust_ar)

    # read in original data
    seq = load_pricedata(region)

    # initial points
    n_dbaclust= n_init # number of dbaclust runs (each with n_init below)

    n_init = 1 # number of initial guesses for each dbaclust run / should be set to 1 for each experiment. dbaclust is deterministic once an initial guess has been formed. We sample the initial guesses on the outer run.  

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
    df[:n_init]=n_init
    df[:n_dbaclust]=n_dbaclust
    df[:rad_sc_min]=rad_sc_min
    df[:rad_sc_max]=rad_sc_max
    df[:iterations]=iterations
    df[:inner_iterations]=inner_iterations
    df[:region]=region

    writetable(joinpath("outfiles",string("parameters.txt")),df)

     # iterate through settings
    for n_clust=n_clust_min:n_clust_max
      for rad_sc=rad_sc_min:rad_sc_max
        for i = 1:n_dbaclust

          rmin,rmax = sakoe_chiba_band(rad_sc,24)

           ##########################
          # normalized clustering hourly
          seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,scope="sequence")
          tic()
          results = dbaclust(seq_norm,n_clust,n_init,ClassicDTW();iterations=iterations,inner_iterations=inner_iterations,rtol=1e-5,show_progress=false,store_trace=false,i2min=rmin,i2max=rmax)
          el_time = toq()
          println("Elapsed time: ",el_time ," ; n_clust=",n_clust," rad_sc=",rad_sc," i=",i)
          flush(STDOUT)

          centers_norm = results.centers
          clustids = results.clustids
          centers = undo_z_normalize(seq_to_array(centers_norm),hourly_mean,hourly_sdv;idx=clustids)    

           # save results to txt



          writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",i,"_cluster.txt")),DataFrame(centers'),separator='\t',header=false)
          writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",i,"_clustids.txt")),DataFrame(id=clustids),separator='\t',header=false)
          writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",i,"_cost.txt")),DataFrame(cost=results.dbaresult.cost),separator='\t',header=false)
          writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",i,"_it.txt")),DataFrame(iterations=results.iterations),separator='\t',header=false)
          writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",i,"_innerit.txt")),DataFrame(inner_iterations=results.dbaresult.iterations),separator='\t',header=false)

        end
      end
    end
    
    # TODO  - import dbaclust_res_to_jld2.jl and automatically generate jld2 files.
    return 0
end # function
