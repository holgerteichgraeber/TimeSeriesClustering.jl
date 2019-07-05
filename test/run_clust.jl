using ClustForOpt
using Test
using JLD2
using Random
# make sure to put Random.seed!() before every evaluation of run_clust, because most of them use random number generators in clustering.jl
# Random.seed!() should give the same result even on different machines:https://discourse.julialang.org/t/is-rand-guaranteed-to-give-the-same-sequence-of-random-numbers-in-every-machine-with-the-same-seed/12344

# put DAM_GER, DAM_CA, CEP GER1, CEP GER18 all years into data.jl file that just tests kmeans with all data inputs


@load normpath(joinpath(dirname(@__FILE__),"reference_generation","run_clust.jld2")) reference_results

Random.seed!(1111)
@testset "run_clust $data" for data in [:CEP_GER1,:CEP_GER18] begin
    ts_input_data = load_timeseries_data(data)
    #mr: method, representation, n_init
    mr = [["kmeans","centroid",1000],
    ["kmeans","medoid",1000],
    ["kmedoids","centroid",1000],
    ["kmedoids","medoid",1000],
    ["hierarchical","centroid",1],
    ["hierarchical","medoid",1]]
    @testset "method=$method + representation=$repr" for (method,repr,n_init) in mr begin
        # somehow the following passes if I use julia runtest.jl, but does not pass if
        # I use ] test ClustForOpt.
        #@testset "default" begin
        #    Random.seed!(1111)
        #        ref = reference_results["$data-$method-$repr-default"]
        #        t = run_clust(ts_input_data;method=method,representation=repr,n_clust=5,n_init=n_init)
        #        test_ClustResult(t,ref)
        #    catch
        #        @test reference_results["$data-$method-$repr-default"] == "not defined"
        #    end
        #end
        @testset "n_clust=1" begin
            Random.seed!(1111)
            try
                ref = reference_results["$data-$method-$repr-n_clust1"]
                t = run_clust(ts_input_data;method=method,representation=repr,n_clust=1,n_init=n_init)
                test_ClustResult(t,ref)
            catch
                @test reference_results["$data-$method-$repr-n_clust1"] == "not defined"
            end
        end
        @testset "n_clust=N" begin
            Random.seed!(1111)
            try
                ref = reference_results["$data-$method-$repr-n_clustK"]
                t= run_clust(ts_input_data;method=method,representation=repr,n_clust=ts_input_data.K,n_init=n_init)
                test_ClustResult(t,ref)
            catch
                @test reference_results["$data-$method-$repr-n_clustK"] == "not defined"
            end
        end
      end
    end
  end
end

# Use the same data for all subsequent tests
data = :CEP_GER1
ts_input_data = load_timeseries_data(data)

using Cbc
optimizer = Cbc.Optimizer
method = "kmedoids_exact"
repr = "medoid"
# kmedoids exact: only run for small system because cbc does not solve for large system
# no seed needed because kmedoids exact solves globally optimal
@testset "$method-$repr-$data" begin
    @testset "default" begin
        ref = reference_results["$data-$method-$repr-default"]
        t = run_clust(ts_input_data;method=method,representation=repr,n_clust=5,n_init=1,kmexact_optimizer=optimizer)
        test_ClustResult(t,ref)
    end
    @testset "n_clust=1" begin
        ref = reference_results["$data-$method-$repr-n_clust1"]
        t = run_clust(ts_input_data;method=method,representation=repr,n_clust=1,n_init=1,kmexact_optimizer=optimizer)
        test_ClustResult(t,ref)
    end
    @testset "n_clust=1" begin
        ref = reference_results["$data-$method-$repr-n_clustK"]
        t = run_clust(ts_input_data;method=method,representation=repr,n_clust=ts_input_data.K,n_init=1,kmexact_optimizer=optimizer)
        test_ClustResult(t,ref)
    end
end

@testset "MultiClustAtOnce" begin
    method = "hierarchical"
    repr = "centroid"
    Random.seed!(1111)
    ref_array = reference_results["$data-$method-$repr-MultiClust"]
    t_array = run_clust(ts_input_data,[1,5,ts_input_data.K];method=method,representation=repr,n_init=1)
    for i = 1:length(t_array)
        test_ClustResult(t_array[i],ref_array[i])
    end
end

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

@testset "AttributeWeighting" begin
    method = "hierarchical"
    repr = "centroid"
    Random.seed!(1111)
    attribute_weights=Dict("solar"=>1.0, "wind"=>2.0, "el_demand"=>3.0)
    ref = reference_results["$data-$method-$repr-AttributeWeighting"]
    t = run_clust(ts_input_data;method=method,representation=repr,n_clust=5,n_init=1,attribute_weights=attribute_weights)
    test_ClustResult(t,ref)
end
