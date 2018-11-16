# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.
<<<<<<< HEAD
using ClustForOpt_priv
=======
@time include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))

# This file exemplifies the workflow from data input to optimization result generation
#QUESTION using ClustForOpt_priv.col in module Main conflicts with an existing identifier., using ClustForOpt_priv.cols in module Main conflicts with an existing identifier.

>>>>>>> f8396d003e387eab540f637f2a26bc501ccb715c
# load data
#input_data,~ = load_timeseries_data("DAM", "GER") DAM
ts_input_data,~ = load_timeseries_data("CEP", "GER";K=365, T=24) #CEP

cep_input_data_GER=load_cep_data("GER";interest_rate=0.05,max_years_of_payment=20)

 # run clustering
<<<<<<< HEAD
ts_clust_res = run_clust(ts_input_data;n_init=10,n_clust_ar=collect(1:9)) # default k-means

 # optimization
#using Cbc
#opt_res = run_opt("battery",clust_res.best_results[5])
opt_res = run_cep_opt(ts_clust_res.best_results[5],cep_input_data_GER;solver=GurobiSolver(),co2limit=1e9)
 #opt_res = run_opt("gas_turbine",clust_res.best_results[5])qw
=======
Scenarios=Dict{String,Scenario}()
#TODO combine reference and specific scenarios
Scenarios["reference"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=collect(30)).best_results[1])
Scenarios["kmeans-4"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=collect(4))) # default k-means
Scenarios["kmean-10"] = Scenario(clust_res=run_clust(ts_input_data;n_init=10,n_clust_ar=collect(10))) # default

co2limitmax=1e12
co2limitmin=0.1e12
steps=5
for (name,Scenario) in Scenarios
# optimization
    Scenario.name=name
    Scenario.opt_res=OptResult[]
    for co2limit=co2limitmax:(-(co2limitmax-co2limitmin)/(steps-1)):co2limitmin
        if name=="reference"
            tsdata=Scenario.clust_res
        else
            tsdata=Scenario.clust_res.best_results[1]
        end
        push!(Scenario.opt_res,run_cep_opt(tsdata,cep_input_data_GER;solver=GurobiSolver(),co2limit=co2limit))
    end
end
>>>>>>> f8396d003e387eab540f637f2a26bc501ccb715c
