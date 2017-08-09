# imports

push!(LOAD_PATH, normpath(joinpath("/data/cees/hteich/clustering/src"))) #adds the location of ClustForOpt to the LOAD_PATH
using ClustForOpt
using TimeWarp # has to be before ClustForOpt
 #using PyPlot
 # plt = PyPlot

 ######## DATA INPUT ##########

 # region
region = "GER"


# read in original data
data_orig_daily = load_pricedata(region)
seq = data_orig_daily[:,1:365]  # do not load as sequence

println("data loaded")

# number of clusters
n_clust_min =3
n_clust_max =3

# initial points
n_init = 50 # number of initial guesses for each dbaclust run
n_dbaclust =1 # number of dbaclust runs (each with n_init)

# warping window (sakoe chiba band radius)
rad_sc_min=0
rad_sc_max=0

 # iterations
iterations = 100
inner_iterations=15

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

      seq_norm, hourly_mean, hourly_sdv = z_normalize(seq,hourly=true)
      tic()
      centers_norm, clustids, result_norm = dbaclust(seq_norm,n_clust,n_init,ClassicDTW();iterations=iterations,inner_iterations=inner_iterations,rtol=1e-5,show_progress=false,store_trace=false,i2min=rmin,i2max=rmax)
      toc()


      centers = undo_z_normalize(seq_to_array(centers_norm),hourly_mean,hourly_sdv)

       # save results to txt



      writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",1,"_cluster.txt")),DataFrame(centers'),separator='\t',header=false)
      writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",1,"_clustids.txt")),DataFrame(id=clustids),separator='\t',header=false)
      writetable(joinpath("outfiles",string("dbaclust_k_",n_clust,"_scband_",rad_sc,"_ninit_",n_init,"_it_",iterations,"_innerit_",inner_iterations,"_",1,"_cost.txt")),DataFrame(cost=result_norm.cost),separator='\t',header=false)

    end
  end
end


