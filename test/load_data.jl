
@testset "load_timeseries_data" begin
    # load one and check if all the fields are correct
    ts_input_data = load_timeseries_data(:CEP_GER1)
    @test ts_input_data.K == 366
    @test ts_input_data.T == 24
    @test all(ts_input_data.weights .== 1.)

    # load all four by name - just let them run and see if they run without error
    ts_input_data = load_timeseries_data(:DAM_GER)
    ts_input_data = load_timeseries_data(:DAM_CA)
    ts_input_data = load_timeseries_data(:CEP_GER1)
    ts_input_data = load_timeseries_data(:CEP_GER18)

    #load a folder by path
    ts_input_data = load_timeseries_data(normpath(joinpath(dirname(@__FILE__),"..","data","TS_GER_1")))

    # load single file by path
    ts_input_data = load_timeseries_data(normpath(joinpath(dirname(@__FILE__),"..","data","TS_GER_1","solar.csv")))
    @test all(["solar-germany"] .== keys(ts_input_data.data) )
end
