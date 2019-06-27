using Test
using ClustForOpt
using JLD2
# make sure to put Random.seed!() before every evaluation of run_clust, because most of them use random number generators in clustering.jl
# Random.seed!() should give the same result even on different machines:https://discourse.julialang.org/t/is-rand-guaranteed-to-give-the-same-sequence-of-random-numbers-in-every-machine-with-the-same-seed/12344

# put DAM_GER, DAM_CA, CEP GER1, CEP GER18 all years into data.jl file that just tests kmeans with all data inputs

"""
    test_ClustResult

Tests if the two structs ClustResult are identical in key properties
"""
function test_ClustResult(t::ClustResult,ref::ClustResult)
    @test t.cost ≈ ref.cost
    @test t.clust_data.region == ref.clust_data.region
    @test t.clust_data.K == ref.clust_data.K
    @test t.clust_data.T == ref.clust_data.T
    @test all(t.clust_data.weights .≈ ref.clust_data.weights)
    @test all(t.clust_data.delta_t .== ref.clust_data.delta_t)
    @test all(t.clust_data.k_ids .== ref.clust_data.k_ids)
    for (k,v) in t.clust_data.data
        @test all(t.clust_data.data[k] .≈ ref.clust_data.data[k])
        @test all(t.clust_data.mean[k] .≈ ref.clust_data.mean[k])
        @test all(t.clust_data.sdv[k] .≈ ref.clust_data.sdv[k])
    end
end

@load normpath(joinpath(dirname(@__FILE__),"reference_generation","run_clust.jld2")) reference_results

Random.seed!(1111)
@testset "run_clust $data" for data in ["CEP_GER1","CEP_GER18"] begin
    ts_input_data = load_timeseries_data(Symbol(data))
    #mr: method, representation, n_init
    mr = [["kmeans","centroid",1000],
    ["kmeans","medoid",1000],
    ["kmedoids","centroid",1000],
    ["kmedoids","medoid",1000],
    ["hierarchical","centroid",1],
    ["hierarchical","medoid",1]]
    @testset "method=$method + representation=$repr" for (method,repr,n_init) in mr begin
        @testset "default" begin
            Random.seed!(1111)
            try
                ref = reference_results["$data-$method-$repr-default"]
                t = run_clust(ts_input_data;method=method,representation=repr,n_clust=5,n_init=n_init)
                test_ClustResult(t,ref)
            catch
                @test reference_results["$data-$method-$repr-default"] == "not defined"
            end
        end
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
        #@testset "n_init=1" begin
        #end
      end
    end
    #@testset "method=kmedoids_exact + representation=$repr" for repr in ["centroid","medoid"] begin
    #["kmedoids_exact","centroid",1],
    #["kmedoids_exact","medoid",1],
    # also test without optimizer
    #end
  end
end






# run_clust
 # method + representation (exact with Cbc on a mini problem)

# make sure to include edge cases: n=1, n=K ...

# make a new file for extreme values
# make a test file for every file in src
