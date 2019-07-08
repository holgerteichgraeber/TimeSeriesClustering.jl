
@testset "struct ClustData" begin
    @test 1==1
    # constructors are all tested by run_clust
    # TODO: add unit tests for constructors anyways.
end

@testset "SimpleExtremeValueDescr" begin
    @testset "normal" begin
        ev1 = SimpleExtremeValueDescr("wind-dena42","max","absolute")
        @test ev1.data_type =="wind-dena42"
        @test ev1.extremum =="max"
        @test ev1.peak_def =="absolute"
        @test ev1.consecutive_periods ==1
    end
    @testset "edge cases" begin
        @test_throws ErrorException ev1 = SimpleExtremeValueDescr("wind-dena42","maximum","absolute")
        @test_throws ErrorException ev1 = SimpleExtremeValueDescr("wind-dena42","max","abs")
    end
end
