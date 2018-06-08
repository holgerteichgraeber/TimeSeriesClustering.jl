CLUST_FOR_OPT=ENV["CLUST_FOR_OPT"]
push!(LOAD_PATH, normpath(joinpath(CLUST_FOR_OPT,"src"))) #adds the location of ClustForOpt to the LOAD_PATH
  @everywhere using ClustForOpt
  @everywhere using TimeWarp


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
n_init = 1 # number of initial guesses for each dbaclust run # should be set to 1 for most experiments
n_dbaclust =10000 # number of dbaclust runs (each with n_init)

# warping window (sakoe chiba band radius)
rad_sc_min=0
rad_sc_max=5

 # iterations
iterations = 100
inner_iterations=30


n_clust_ar = collect(n_clust_min:n_clust_max)
rad_sc_ar = collect(rad_sc_min:rad_sc_max)

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

writetable(joinpath("outfiles",string("parameters_dtw_",region,".txt")),df)


 #  dbac_par_sc(n_clust,i,rad_sc,input_struct)

 # Function that can be an input to pmap

 @everywhere function dbac_par_sc(n_clust::Int,i::Int,rad_sc::Int,seq::Array{Float64,2},n_init::Int,iterations::Int,inner_iterations::Int) # function to use with pmap to parallelize sc band calculation

  rmin,rmax=sakoe_chiba_band(rad_sc,24)

   ##########################
  # normalized clustering hourly
  seq_norm, hourly_mean, hourly_sdv = z_normalize(seq;scope="sequence")
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

end #dbac_par_sc



 # generate iterables for pmap
num_iter = length(n_clust_ar)*length(rad_sc_ar)*n_dbaclust

seq_iter = [seq for i=1:num_iter]
n_init_iter = [n_init for i=1:num_iter]
iterations_iter = [iterations for i=1:num_iter]
inner_iterations_iter = [inner_iterations for i=1:num_iter]
n_clust_iter = reshape(repmat(n_clust_ar,1,length(rad_sc_ar)*n_dbaclust)',:,1)
i_iter = repmat(reshape(repmat(collect(1:n_dbaclust),1,length(rad_sc_ar))',:,1),length(n_clust_ar),1)
rad_sc_iter = repmat(rad_sc_ar,length(n_clust_ar)*n_dbaclust,1)

pmap(dbac_par_sc,n_clust_iter,i_iter,rad_sc_iter,seq_iter,n_init_iter,iterations_iter,inner_iterations_iter;retry_delays=ones(10)*20)

