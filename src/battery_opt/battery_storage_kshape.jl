# imports
using JuMP
using Clp
using PyCall
using PyPlot
using DataFrames
plt = PyPlot


unshift!(PyVector(pyimport("sys")["path"]), "") # add current path to search path

util_path = normpath(joinpath(pwd(),"..","utils"))
unshift!(PyVector(pyimport("sys")["path"]), util_path) # add util path to search path
@pyimport load_clusters

function get_EUR_to_USD(region)
   if region =="GER"
     ret = 1.109729
   else
     ret =1
   end
   return ret
end


function run_opt(el_price, weight=1, prnt=false)
  num_periods = size(el_price,2); # number of periods, 1day, one week, etc.
  num_hours = size(el_price,1); # hours per period (24 per day, 48 per 2days)

  # time steps
  del_t = 1; # hour

  # example battery Southern California Edison
  P_battery = 100; # MW
  E_battery = 400; # MWh
  eff_Storage_in = 0.95;
  eff_Storage_out = 0.95;
  #Stor_init = 0.5;

  # optimization
  # Sets
  # time
  t_max = num_hours;

  E_in_arr = zeros(num_hours,num_periods)
  E_out_arr = zeros(num_hours,num_periods)
  stor = zeros(num_hours +1,num_periods)

  obj = zeros(num_periods);
  m= Model(solver=ClpSolver() )

  # hourly energy output
  @variable(m, E_out[t=1:t_max] >= 0) # kWh
  # hourly energy input
  @variable(m, E_in[t=1:t_max] >= 0) # kWh
  # storage level
  @variable(m, Stor_lev[t=1:t_max+1] >= 0) # kWh

  @variable(m,0 <= Stor_init <= 1) # this as a variable ensures

  # maximum battery power
  for t=1:t_max
    @constraint(m, E_out[t] <= P_battery*del_t)
    @constraint(m, E_in[t] <= P_battery*del_t)
  end

  # maximum storage level
  for t=1:t_max+1
    @constraint(m, Stor_lev[t] <= E_battery)
  end

  # battery energy balance
  for t=1:t_max
    @constraint(m,Stor_lev[t+1] == Stor_lev[t] + eff_Storage_in*del_t*E_in[t]-(1/eff_Storage_out)*del_t*E_out[t])
  end

  # initial storage level
  @constraint(m,Stor_lev[1] == Stor_init*E_battery)
  @constraint(m,Stor_lev[t_max+1] >= Stor_lev[1])

  for i =1:num_periods
    #objective
    @objective(m, Max, sum((E_out[t] - E_in[t])*el_price[t,i] for t=1:t_max) )
    status = solve(m)

    if weight ==1
      obj[i] = getobjectivevalue(m)
    else
      obj[i] = getobjectivevalue(m) * weight[i] * 365
    end
    E_in_arr[:,i] = getvalue(E_in)'
    E_out_arr[:,i] = getvalue(E_out)
    stor[:,i] = getvalue(Stor_lev)
  end

  # plots
  if(prnt)
    figure()
    for i=1:num_periods
      plt.plot(stor[:,i], label=string("stor lev: ", i))
      plt.legend()
    end

    figure()
    for i=1:num_periods
      plt.plot(E_in_arr[:,i],label=string("E_in: ",i))
      plt.plot(E_out_arr[:,i], label=string("E_out: ",i))
      plt.legend()
    end
  end # prnt

  return obj
end # function

###########################################
####### main function ######################

# set working directory here
close("all")
#cd("C:\Users\Holger\Dropbox\ere-apc34\Research\data_electricity\California\Price modification")

# import data

#### DATA INPUT ######

# region:
region = "GER"   # "CA"   "GER"
n_k=9
n_init =1000

if region =="CA"
  region_str = ""
  region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.txt"))
else
  region_str = "GER_"
  region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.txt"))
end

# original data
data_orig = Array(readtable(region_data, separator = '\t', header = false)) # * get_EUR_to_USD(region);
#data_synth_markov = array(readtable("synth_markov_ca_2015_n10.txt", separator = '\t', header = false));
# optimization on original data
data_orig_daily = reshape(data_orig,24,365)
#data_orig_weekly = reshape(data_orig[1:24*7*52],24*7,52);
revenue_orig_daily = sum(run_opt(data_orig_daily));
println("Original data rev: ", revenue_orig_daily, " USD")

# calc hourly mean and sdv
hourly_mean = zeros(size(data_orig_daily)[1])
hourly_sdv = zeros(size(data_orig_daily)[1])
for i=1:size(data_orig_daily)[1]
  hourly_mean[i] = mean(data_orig_daily[i,:])
  hourly_sdv[i] = std(data_orig_daily[i,:])
end


## kshape boxplot testing (put into loop with if later)

revenue_ksh = zeros(n_init,9)
for k=1:9


  kshape_centroids_in = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data","kshape_results", region * "_centroids_kshape_" * string(k) * ".pkl"))) # GER
  kshape_labels = load_clusters.load_pickle(normpath(joinpath(pwd(),"..","..","data","kshape_results",region * "labels_kshape_" * string(k) * ".pkl")))  # GER
  #println(kshape_centroids[1])
  kshape_centroids = zeros(size(kshape_centroids_in[1])[1],size(kshape_centroids_in[1])[2],n_init)

  #### back transfrom from normalized data
  for i=1:n_init
    #kshape_centroids[i] = kshape_centroids[i] + ones(k)*hourly_mean'
    kshape_centroids[:,:,i] = (kshape_centroids_in[i].* hourly_sdv' + ones(k)*hourly_mean')
  end
  if k==0
    figure()
    for i=1:n_init
      plot(kshape_centroids[:,:,i]',color="0.75")
    end
    #figure()
    data = Array(readtable(normpath(joinpath(pwd(),"..","..","data","kshape_results",string(region_str, "Elec_Price_kmeans_","kshape","_","cluster", "_", k,".txt"))), separator = '\t', header = false))/get_EUR_to_USD(region);
    plot(data',color="red")
  end

  for i=1:n_init
    weights = zeros(size(kshape_centroids[:,:,i])[1])
    for j=1:length(kshape_labels[i])
        weights[kshape_labels[i][j]+1] +=1
    end
    weights = weights/length(kshape_labels[i])
 #println("weights: ",k," ",weights)
    revenue_ksh[i,k] = sum(run_opt(kshape_centroids[:,:,i]',weights,false));
    #println("revenuekshape-",revenue_ksh[i,k])
    #println("k=",k,"w=",weights)
  end

end
# Create a figure instance
figure()
boxplot(revenue_ksh/1e6)
hold
plt.xlabel("Number of clusters",fontsize=25)
if region == "CA"
  plt.ylabel("Revenue [Mio USD/year]",fontsize=25)
else
  plt.ylabel("Revenue [Mio EUR/year]",fontsize=25)
end
plt.legend(loc="bottom right",fontsize=20)
ax  =axes()
ax[:tick_params]("both",labelsize=24)
plt.tight_layout()
ax[:tick_params]("both")
#plt.title("normalized" * region * " kshape revenue")
plt.plot(1:n_k,revenue_orig_daily/1e6*ones(n_k),label="365 days",color="c",lw=3)
plt.legend(loc=2,fontsize=20)
plt.ylim(3000000*1e-6, 6500000*1e-6 )

norm = ["kshape"]
norm_descr = ["k-shape"]
cluster_kind = ["cluster","closest"]
revenue = zeros(n_k,length(norm)*length(cluster_kind))
ii=0
for c in cluster_kind
  fig =figure()
  if c=="cluster"

    boxplot(revenue_ksh/1e6)
    hold
    ax = axes()
  end
  j=0
  for n in norm
    j+=1
    ii +=1
    for k=1:n_k
      data = Array(readtable(normpath(joinpath(pwd(),"..","..","data","kshape_results",string(region_str, "Elec_Price_kmeans_",n,"_",c, "_", k,".txt"))), separator = '\t', header = false))/get_EUR_to_USD(region);
      weight = Array(readtable(normpath(joinpath(pwd(),"..","..","data","kshape_results",string(region_str, "Weights_kmeans_", n,"_",c, "_",k,".txt"))), separator = '\t', header = false))
      revenue[k,ii] = sum(run_opt(data',weight,false));
      #println("best k=",k,"w=",weight)
      #println("rev: ", revenue[k,ii], " USD \n")
    end
    plt.plot(1:n_k,revenue[:,ii]/1e6,label=string(norm_descr[j]))
  end
  plt.plot(1:n_k,revenue_orig_daily/1e6*ones(n_k),label="365 days",color="c",lw=3)
  plt.ylim(3000000e-6, 6500000e-6 )
  plt.xlabel("Number of clusters",fontsize=25)
  if region == "CA"
    plt.ylabel("Revenue [Mio USD/year]",fontsize=25)
  else
    plt.ylabel("Revenue [Mio EUR/year]",fontsize=25)
  end
  plt.legend(loc=2,fontsize=20)
  ax  =axes()
  ax[:tick_params]("both",labelsize=24)
  plt.tight_layout()
  #println( revenue)
end



ii=0
for c in cluster_kind
  fig =figure()
  if c=="cluster"

    boxplot(revenue_ksh)
    hold
    ax = axes()
  end
  j=0
  for n in norm
    j+=1
    ii +=1
    for k=1:n_k
      #println("best k=",k,"w=",weight)
      #println("rev: ", revenue[k,ii], " USD \n")
    end
    plt.plot(1:n_k,revenue[:,ii]/1000,label=string(norm_descr[j]))
  end
  plt.plot(1:n_k,revenue_orig_daily*ones(n_k),label="365 days")
  plt.ylim(3000000, 6500000 )
  plt.xlabel("Number of clusters")
  if region == "CA"
    plt.ylabel("Revenue [USD/year]")
  else
    plt.ylabel("Revenue [EUR/year]")
  end
  plt.legend(loc=2)
  plt.tight_layout()

  #println( revenue)
end

plt.show()

#=
# optimize on one sample week from markov
# take one week:
n_samples = 1000;
revenue_synth_weekly = zeros(n_samples)

week = 50;
for i=1:n_samples
  print(i)
  data_synth_weekly = reshape(data_synth_markov[(24*7*(week-1)+1):24*7*week,i],24*7,1)
  revenue_synth_weekly[i] = 52*run_opt(data_synth_weekly)[1];
end

# Create a figure instance
figure()
boxplot(revenue_synth_weekly/10^9)
ax = axes()
ax[:set_xlabel]("", fontsize=25)
ax[:set_ylabel](L"[10^{9}\$]", fontsize=25)
ax[:tick_params]("both",labelsize=25)
plt.title("1000 samples - annualized revenue",fontsize=25)
#plt.title("ann. revenue random week: " * string(week))
=#
