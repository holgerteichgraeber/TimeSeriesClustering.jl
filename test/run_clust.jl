using Test

# put DAM_GER, DAM_CA, CEP GER1, CEP GER18 all years into data.jl file that just tests kmeans with all data inputs

"""
    test_ClustResult

Tests if the two structs ClustResult are identical in key properties
"""
function test_ClustResult(t::ClustResult,ref::ClustResult)
    @test t.cost == ref.cost
end

@testset "run_clust $data" for data in ["CEP_GER1","CEP_GER18"] begin
    #mr: method, representation, n_init
    mr = [["kmeans","centroid",1000],
    ["kmeans","medoid",1000],
    ["kmedoids","centroid",1000],
    ["kmedoids","medoid",1000],
    ["hierarchical","centroid",1],
    ["hierarchical","medoid",1]]
    mr_result = [
    ]
    @testset "method=$method + representation=$repr" for (method,repr,n_init) in mr begin
        @testset "default" begin

        end
        @testset "n_clust=1" begin
        end
        @testset "n_clust=N" begin
        end
        @testset "n_init=1" begin
        end
    end
    @testset "method=kmedoids_exact + representation=$repr" for repr in ["centroid","medoid"] begin
    ["kmedoids_exact","centroid",1],
    ["kmedoids_exact","medoid",1],
    # also test without optimizer
    end
end






# run_clust
 # method + representation (exact with Cbc on a mini problem)

# make sure to include edge cases: n=1, n=K ...

# make a new file for extreme values
# make a test file for every file in src
