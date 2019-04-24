#using ClustForOpt_priv
using JuMP
using Clp
using DataFrames
 # parameters

acf = 0.1 # annualized cost of capital factor

c_cap_s = (11.94e6 + acf*2.58e9)*20/100 # $/GW   # 20/100 ~ 0.5$/W, 40/100~ 1$/W
c_cap_w = 30.98e6 + acf*1.74e9 # $/GW
c_cap_gas = 11.96e6 + acf*0.968e9 # $/GW
c_cap_nuc = 92.04e6 + acf*3.82e9 # $/GW
c_cap_coal = 28.15e6 + acf*2.22e9 # $/GW
c_cap = [c_cap_coal,c_cap_nuc,c_cap_gas,c_cap_w,c_cap_s]

c_var_s = 0.5 # $/GWh
c_var_w = 0.5 # $/GWh
c_var_gas = 41500 # $/GWh
c_var_nuc = 7025 # $/GWh
c_var_coal = 23000 # $/GWh
c_var = [c_var_s,c_var_w,c_var_gas,c_var_nuc,c_var_coal]
c_var = [c_var_coal,c_var_nuc,c_var_gas,c_var_w,c_var_s]


c_lost = 1000e6 # $/GW # VOLL


n_years = 10  # depreciation period for capital
r = 0.07 # real discount rate

 # load input data

de= readtable("/home/hteich/.julia/v0.6/ClustForOpt_priv/data/texas_merrick/demand.txt",separator=' ')[:DEM] # MW
d=reshape(de,(size(de)[1],1))
 # load growth
d=1.486*d
d=d/1000 # GW

 #d = rand(8760,1)  # demand
 # load growth *1.5 (footnote 6 merrick)
a_s= readtable("/home/hteich/.julia/v0.6/ClustForOpt_priv/data/texas_merrick/TexInsolationFactorV1.txt",separator=' ')[:solar_61]
a_s=reshape(a_s,(size(a_s)[1],1))
  a_s = a_s/1000
 #a_s = rand(8760,1) # availability solar
 #a_w = rand(8760,1) # availability wind
a_w= readtable("/home/hteich/.julia/v0.6/ClustForOpt_priv/data/texas_merrick/windfactor2.txt",separator=' ')[:Wind_61]
a_w=reshape(a_w,(size(a_w)[1],1))
a_gas = ones(8760,1)
a_nuc = ones(8760,1)
a_coal =ones(8760,1)
a= [a_coal,a_nuc,a_gas,a_w,a_s]


N=ones(8760,1)

del_t = 1 # hour

  ### SETS ####
K = size(d)[1]
T = size(d)[2]
G_names = ["coal","nuclear","gas","wind","solar"] # generators
n_G = length(G_names)


  ##### MODEL #####
m = Model(optimizer=ClpSolver())

  ### VARIABLES ##
  ### DESIGN VARIABLES ###
# generation capacity build
@variable(m,G_max[1:n_G] >= 0) # GWh

 ### OPERATIONAL VARIABLES ####
# generation of individual generator per time step
@variable(m,G[1:n_G,1:K,1:T] >=0)

 ##### OBJECTIVE FUNCTION #####
 @objective(m,Min,sum(c_cap[g]*G_max[g] for g=1:n_G)  +
     sum(sum(sum( c_var[g]*G[g,k,t]
           for k=1:K )
         for t=1:T )
       for g=1:n_G )
     )

 #### CONSTRAINTS ######
 # energy balance constraint
@constraint(m,[k=1:K,t=1:T], sum(G[g,k,t] for g=1:n_G) >= d[k,t])
 # maximum power production constraint
@constraint(m,[g=1:n_G,k=1:K,t=1:T], G[g,k,t] <= G_max[g] * a[g][k,t] )


  #### SOLVE ####
  status = solve(m)

 #### Output results ####
 G_max = getvalue(G_max)
 G = getvalue(G) # installed capacity
 G_gen =sum(G[:,:,1],2) # generated power


 if true
    using PyPlot

    figure()
    bt = zeros(length(G_max))
    for i=2:length(bt)
      bt[i]=cumsum(G_max)[i-1]
    end
    for i=1:length(G_max)
      bar(1, G_max[i],bottom=bt[i],color=cols[i],label=G_names[i])
    end
    ylabel("GW")
    legend()
    title("Capacity built")

    figure()
    bt = zeros(length(G_gen))
    for i=2:length(bt)
      bt[i]=cumsum(G_gen)[i-1]
    end
    for i=1:length(G_gen)
      bar(1, G_gen[i],bottom=bt[i],color=cols[i],label=G_names[i])
    end
    ylabel("GWh")
    legend()
    title("Power generated")


 end

 # TODO - add clustering, check on paper what to do next
