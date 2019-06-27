
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
    @test all(t.clust_data.delta_t .≈ ref.clust_data.delta_t)
    @test all(t.clust_data.k_ids .≈ ref.clust_data.k_ids)
    for (k,v) in t.clust_data.data
        @test all(t.clust_data.data[k] .≈ ref.clust_data.data[k])
        @test all(t.clust_data.mean[k] .≈ ref.clust_data.mean[k])
        @test all(t.clust_data.sdv[k] .≈ ref.clust_data.sdv[k])
    end
end
