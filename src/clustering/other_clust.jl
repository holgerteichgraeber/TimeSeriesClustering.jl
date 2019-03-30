"""
    run_two_step_clust(data::ClustData; norm_op::String="zscore", norm_scope::String="full", method::String="kmeans", representation::String="centroid", n_clust_1::Int=5, n_clust_2::Int=3, n_seg::Int=data.T, n_init::Int=100, iterations::Int=300, attribute_weights::Dict{String,Float64}=Dict{String,Float64}(), features_2::Array{String,1}=Array{String,1}(), get_all_clust_results::Bool=false, kwargs...)
Run a first regular cluster over the data and a second about the defined `features_2` within each period.
"""
function run_two_step_clust(data::ClustData;
                            norm_op::String="zscore",
                            norm_scope::String="full",
                            method::String="kmeans",
                            representation::String="centroid",
                            n_clust_1::Int=5,
                            n_clust_2::Int=3,
                            n_seg::Int=data.T,
                            n_init::Int=100,
                            iterations::Int=300,
                            attribute_weights::Dict{String,Float64}=Dict{String,Float64}(),
                            features_2::Array{String,1}=Array{String,1}(),
                            get_all_clust_results::Bool=false,
                            kwargs...)
  clust_data=run_clust(data;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust_1,n_init=n_init,iterations=iterations,attribute_weights=attribute_weights).best_results
  new_k_ids=deepcopy(clust_data.k_ids)
  for i in 1:clust_data.K
      index=findall(clust_data.k_ids.==i)
      dt=Dict{String,Array}()
      for name in keys(data.data)
        tech=split(name,"-")[1]
        if name in features_2 || tech in features_2
          dt[name]=(data.data[name][:,index])
        end
      end
      single_period=ClustData(FullInputData(clust_data.region, clust_data.years, 0, dt),Int64(clust_data.weights[i]),clust_data.T)
      new_k_ids[index]=run_clust(single_period; n_clust=Int64(min(single_period.K,n_clust_2)),n_init=Int64(round(n_init/clust_data.K))).best_ids.+(i-1)*n_clust_2
  end
  return run_clust(data;method="predefined",representation=representation,n_init=1,n_clust=Int64(n_clust_1*n_clust_2),k_ids=new_k_ids,n_seg=n_seg,get_all_clust_results=get_all_clust_results)
end

"""
    run_minmax_clust(data::ClustData; norm_op::String="zscore", norm_scope::String="full", method::String="kmeans", representation::String="centroid", n_clust_1::Int=5, n_clust_2::Int=3, n_seg::Int=data.T, n_init::Int=100, iterations::Int=300, attribute_weights::Dict{String,Float64}=Dict{String,Float64}(), min::Array{String,1}=Array{String,1}(), max::Array{String,1}=Array{String,1}(),, get_all_clust_results::Bool=false, kwargs...)
Choose the min or max of a certain attribute to represent this attribute in this period instead of the centroid or so
"""
function run_minmax_clust(data::ClustData;
                            norm_op::String="zscore",
                            norm_scope::String="full",
                            method::String="kmeans",
                            representation::String="centroid",
                            n_clust::Int=5,
                            n_seg::Int=data.T,
                            n_init::Int=100,
                            iterations::Int=300,
                            attribute_weights::Dict{String,Float64}=Dict{String,Float64}(),
                            min::Array{String,1}=Array{String,1}(),
                            max::Array{String,1}=Array{String,1}(),
                            get_all_clust_results::Bool=false,
                            kwargs...)
  clust_result=run_clust(data;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust,n_init=n_init,iterations=iterations,attribute_weights=attribute_weights)
  clust_data=clust_result.best_results
  for i in 1:clust_data.K
    index=findall(clust_data.k_ids.==i)
    for name in keys(data.data)
      att=split(name,"-")[1]
      if name in min || att in min
        indexminmax=index[findmin(mean(data.data[name][:,index],dims=1))[2][2]]
        clust_data.data[name][:,i]=data.data[name][:,indexminmax]
      elseif name in max || att in max
        indexminmax=index[findmax(mean(data.data[name][:,index],dims=1))[2][2]]
        clust_data.data[name][:,i]=data.data[name][:,indexminmax]
      end
    end
  end
  return clust_result
end

"""
    run_pure_clust(data::ClustData; norm_op::String="zscore", norm_scope::String="full", method::String="kmeans", representation::String="centroid", n_clust_1::Int=5, n_clust_2::Int=3, n_seg::Int=data.T, n_init::Int=100, iterations::Int=300, attribute_weights::Dict{String,Float64}=Dict{String,Float64}(), clust::Array{String,1}=Array{String,1}(), get_all_clust_results::Bool=false, kwargs...)
Replace the original timeseries of the attributes in clust with their clustered value
"""
function run_pure_clust(data::ClustData;
                            norm_op::String="zscore",
                            norm_scope::String="full",
                            method::String="kmeans",
                            representation::String="centroid",
                            n_clust::Int=5,
                            n_seg::Int=data.T,
                            n_init::Int=100,
                            iterations::Int=300,
                            attribute_weights::Dict{String,Float64}=Dict{String,Float64}(),
                            clust::Array{String,1}=Array{String,1}(),
                            get_all_clust_results::Bool=false,
                            kwargs...)
  clust_result=run_clust(data;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust,n_init=n_init,iterations=iterations,attribute_weights=attribute_weights)
  clust_data=clust_result.best_results
  mod_data=deepcopy(data.data)
  for i in 1:clust_data.K
    index=findall(clust_data.k_ids.==i)
    for name in keys(mod_data)
      att=split(name,"-")[1]
      if name in clust || att in clust
        mod_data[name][:,index]=repeat(clust_data.data[name][:,i], outer=(1,length(index)))
      end
    end
  end
  return ClustResultSimple(ClustData(data.region, data.years, data.K, data.T, mod_data, data.weights, data.deltas, data.k_ids), clust_result.clust_config)
end

"""
    run_darkperiod_clust(data::ClustData, ev_arr::Array{SimpleExtremeValueDescr,1}; norm_op::String="zscore", norm_scope::String="full", method::String="kmeans", representation::String="centroid", n_clust_1::Int=5, n_clust_2::Int=3, n_seg::Int=data.T, n_init::Int=100, iterations::Int=300, attribute_weights::Dict{String,Float64}=Dict{String,Float64}(), get_all_clust_results::Bool=false, kwargs...)
Choose Seasonal extremes based on the provided Simple Extreme Value Descriptions
"""
function run_darkperiod_clust(data::ClustData,
                                ev_arr::Array{SimpleExtremeValueDescr,1};
                                norm_op::String="zscore",
                                norm_scope::String="full",
                                method::String="kmeans",
                                representation::String="centroid",
                                n_clust::Int=5,
                                n_clust_dark::Int=5,
                                n_seg::Int=data.T,
                                n_init::Int=100,
                                n_dark_init::Int=100,
                                iterations::Int=300,
                                attribute_weights::Dict{String,Float64}=Dict{String,Float64}(),
                                get_all_clust_results::Bool=false,
                                config::String="",
                                kwargs...)
    extr_results=Array{ClustData,1}()
    for ev in ev_arr
        data_mod,extr_val,x = simple_extr_val_sel(data,ev;rep_mod_method="append")
        if config=="2extr"
            ev=SimpleExtremeValueDescr(ev.data_type,ev.extremum,ev.peak_def,n_clust_dark)
            x,extr,x = simple_extr_val_sel(extr_val,ev;rep_mod_method="append")
            k_ids=zeros(Int64,size(extr_val.k_ids))
            k_ids[findall(extr_val.k_ids.!=0)].= 1
            extr_result=ClustData(extr.region, extr.years, extr.K, extr.T, extr.data, extr.weights, extr.deltas, k_ids)
        else
            extr_result=run_clust(extr_val;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust_dark,n_init=n_dark_init,iterations=iterations,attribute_weights=attribute_weights,kwargs...).best_results
        end
        push!(extr_results,extr_result)
        data=data_mod
    end
    # run clustering
    data_res = run_clust(data;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust,n_init=n_init,iterations=iterations,attribute_weights=attribute_weights) # default
    # representation modification
    return ClustResultSimple(representation_modification(extr_results, data_res.best_results), data_res.clust_config)
end
