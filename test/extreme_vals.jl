
ts_input_data = load_timeseries_data(:CEP_GER18)

 ev1 = SimpleExtremeValueDescr("wind-dena42","max","absolute") #idx 39
 ev2 = SimpleExtremeValueDescr("solar-dena42","min","integral") # idx 359
 ev3 = SimpleExtremeValueDescr("el_demand-dena21","max","integral") # idx 19
 ev4 = SimpleExtremeValueDescr("el_demand-dena21","min","absolute") # idx 185
 ev = [ev1, ev2, ev3]


# simple extreme day selection
@testset "simple extr day selection" begin
    @testset "single day" begin
        #max absolute"# max absolute
        ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev1;rep_mod_method="feasibility")
        test_ClustData(ts_input_data_mod, ts_input_data)
        for (k,v) in extr_vals.data
            @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,39])
        end
        @test extr_idcs == [39]

        # min integral
        ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev2;rep_mod_method="feasibility")
        test_ClustData(ts_input_data_mod, ts_input_data)
        for (k,v) in extr_vals.data
            @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,359])
        end
        @test extr_idcs == [359]

        # max integral
        ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev3;rep_mod_method="feasibility")
        test_ClustData(ts_input_data_mod, ts_input_data)
        for (k,v) in extr_vals.data
            @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,19])
        end
        @test extr_idcs == [19]

        # min absolute
        ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev4;rep_mod_method="feasibility")
        test_ClustData(ts_input_data_mod, ts_input_data)
        for (k,v) in extr_vals.data
            @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,185])
        end
        @test extr_idcs == [185]
    end

    @testset "multiple days" begin
        ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev;rep_mod_method="feasibility")
        test_ClustData(ts_input_data_mod, ts_input_data)
        for (k,v) in extr_vals.data
            @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,[39,359,19]])
        end
        @test extr_idcs == [39,359,19]

    end
end

@testset "representation modification" begin
     ev1 = SimpleExtremeValueDescr("wind-dena42","max","absolute") #idx 39
     ev2 = SimpleExtremeValueDescr("solar-dena42","min","integral") # idx 359
     ev3 = SimpleExtremeValueDescr("el_demand-dena21","max","integral") # idx 19
     ev = [ev1, ev2, ev3]
     mod_methods = ["feasibility","append"]
     @testset "$mod_method" for mod_method in mod_methods begin
         @testset "single day" begin
            ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev1;rep_mod_method=mod_method)
            for (k,v) in extr_vals.data
                @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,39])
            end
            if mod_method=="feasibility"
                @test all(extr_vals.weights .==0.)
            elseif mod_method=="append"
                @test all(extr_vals.weights .==1.)
            end
            @test extr_vals.T==24
            @test extr_vals.K==1
            @test extr_idcs == [39]

            ts_clust_res = run_clust(ts_input_data_mod;method="kmeans",representation="centroid",n_init=10,n_clust=5) # default k-means
            ts_clust_extr = representation_modification(extr_vals,ts_clust_res.clust_data)

            @test ts_clust_extr.T == ts_input_data.T
            @test ts_clust_extr.K == ts_clust_res.clust_data.K + 1
            for (k,v) in ts_clust_extr.data
                @test all(ts_clust_extr.data[k][:,1:ts_clust_res.clust_data.K] .≈ ts_clust_res.clust_data.data[k])
                @test all(ts_clust_extr.data[k][:,ts_clust_res.clust_data.K+1] .≈ extr_vals.data[k])
            end
            @test all(ts_clust_extr.weights[1:ts_clust_res.clust_data.K] .≈ ts_clust_res.clust_data.weights)
            @test all(ts_clust_extr.weights[ts_clust_res.clust_data.K+1] .≈ extr_vals.weights)
         end
         @testset "multiple days" begin
            ts_input_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_input_data,ev;rep_mod_method=mod_method)
            for (k,v) in extr_vals.data
                @test all(extr_vals.data[k] .≈ ts_input_data.data[k][:,[39,359,19]])
            end
            if mod_method=="feasibility"
                @test all(extr_vals.weights .==0.)
            elseif mod_method=="append"
                @test all(extr_vals.weights .==1.)
            end
            @test extr_vals.T==24
            @test extr_vals.K==3
            @test extr_idcs == [39,359,19]

            ts_clust_res = run_clust(ts_input_data_mod;method="kmeans",representation="centroid",n_init=10,n_clust=5) # default k-means
            ts_clust_extr = representation_modification(extr_vals,ts_clust_res.clust_data)

            @test ts_clust_extr.T == ts_input_data.T
            @test ts_clust_extr.K == ts_clust_res.clust_data.K + 3
            for (k,v) in ts_clust_extr.data
                @test all(ts_clust_extr.data[k][:,1:ts_clust_res.clust_data.K] .≈ ts_clust_res.clust_data.data[k])
                @test all(ts_clust_extr.data[k][:,ts_clust_res.clust_data.K+1:ts_clust_res.clust_data.K+3] .≈ extr_vals.data[k])
            end
            @test all(ts_clust_extr.weights[1:ts_clust_res.clust_data.K] .≈ ts_clust_res.clust_data.weights)
            @test all(ts_clust_extr.weights[ts_clust_res.clust_data.K+1:ts_clust_res.clust_data.K+3] .≈ extr_vals.weights)
         end


        end
    end


end
