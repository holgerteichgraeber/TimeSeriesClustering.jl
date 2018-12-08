using Test

@testset "merrick texas" begin
    include(normpath(joinpath(dirname(@__FILE__),"..","src","ClustForOpt_priv_development.jl")))
    # load data
    ts_input_data, = load_timeseries_data("CEP", "TX_1";K=365, T=24)
    cep_input_data_GER=load_cep_data("TX_1")

    # run clustering
    ts_clust_res = run_clust(ts_input_data;method="kmeans",representation="centroid",n_init=1,n_clust=365) # default k-means

    # run optimization
    model = run_opt(ts_clust_res.best_results,cep_input_data_GER;solver=GurobiSolver())

    # compare to exact result
    exact_res=[70540.26439790576;0.0;8498.278397905757;0.0;80132.88454450261]
    @test round.(exact_res)==round.(model.variables["CAP"].data[:,1,1])

end
