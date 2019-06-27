using ClustForOpt
using JLD2

reference_results = Dict{String,Any}()

Random.seed!(1111)
for data in ["CEP_GER1","CEP_GER18"]
    ts_input_data = load_timeseries_data(Symbol(data))
    #mr: method, representation, n_init
    mr = [["kmeans","centroid",1000],
    ["kmeans","medoid",1000],
    ["kmedoids","centroid",1000],
    ["kmedoids","medoid",1000],
    ["hierarchical","centroid",1],
    ["hierarchical","medoid",1]]
    # default
    for (method,repr,n_init) in mr
        Random.seed!(1111)
        try
            reference_results["$data-$method-$repr-default"] = run_clust(ts_input_data;method=method,representation=repr,n_clust=5,n_init=n_init)
        catch
            reference_results["$data-$method-$repr-default"] = "not defined"
            println("$data-$method-$repr-default not defined")
        end
    end
    # n_clust=1
    for (method,repr,n_init) in mr
        Random.seed!(1111)
        try
            reference_results["$data-$method-$repr-n_clust1"] = run_clust(ts_input_data;method=method,representation=repr,n_clust=1,n_init=n_init)
        catch
            reference_results["$data-$method-$repr-n_clust1"] = "not defined"
            println("$data-$method-$repr-n_clust1 not defined")
        end
    end
    # n_clust = N
    for (method,repr,n_init) in mr
        Random.seed!(1111)
        try
            reference_results["$data-$method-$repr-n_clustK"] = run_clust(ts_input_data;method=method,representation=repr,n_clust=ts_input_data.K,n_init=n_init)
        catch
            reference_results["$data-$method-$repr-n_clustK"] = "not defined"
            println("$data-$method-$repr-n_clustK not defined")
        end
    end
#    mr_kmexact = [["kmedoids_exact","centroid",1],
#    for (method,repr,n_init) in mr_kmexact

#    end
end


@save normpath(joinpath(dirname(@__FILE__),"run_clust.jld2")) reference_results
