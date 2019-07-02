using ClustForOpt
using Test
using Random
using JLD2


@load normpath(joinpath(dirname(@__FILE__),"reference_generation","run_clust.jld2")) reference_results
data = "CEP_GER1"
ts_input_data = load_timeseries_data(Symbol(data))

include("test_utils.jl")


@testset "ClustResultAll" begin
    method = "hierarchical"
    repr = "medoid"
    Random.seed!(1111)
    ref_all = reference_results["$data-$method-$repr-ClustResultAll"]
    t_all = run_clust(ts_input_data;method=method,representation=repr,n_clust=5,n_init=10,get_all_clust_results=true)
    test_ClustResult(t_all,ref_all)
    for i = 1:length(t_all.centers_all)
        @test all(t_all.centers_all[i] .≈ ref_all.centers_all[i])
        @test all(t_all.weights_all[i] .≈ ref_all.weights_all[i])
        @test all(t_all.clustids_all[i] .≈ ref_all.clustids_all[i])
        @test all(t_all.cost_all[i] .≈ ref_all.cost_all[i])
        @test all(t_all.iter_all[i] .≈ ref_all.iter_all[i])
    end
end
