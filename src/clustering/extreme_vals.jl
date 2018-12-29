"""

ts_data: The full input data 365. Used for individual opt run
ts_data_mod: The input data used for clustering (365, or 365-extreme values in the case of append)
clust_data: The clustered data: n_clust + extreme values 
"""
function run_clust_extr(
      ts_data::ClustData,
      opt_data::OptDataCEP,
      extr_value_descr_ar::Array{SimpleExtremeValueDescr,1};
      norm_op::String="zscore",
      norm_scope::String="full",
      method::String="kmeans",
      representation::String="centroid",
      n_clust::Int=5,
      n_init::Int=100,
      iterations::Int=300,
      attribute_weights::Dict{String,Float64}=Dict{String,Float64}(),
      extreme_event_selection_method="feasibility",
      rep_mod_method::String="feasibility",
      save::String="",
      get_all_clust_results::Bool=false,
      solver::Any=CbcSolver(),
      descriptor::String="",
      co2_limit::Number=Inf,
      slack_cost::Number=Inf,
      existing_infrastructure::Bool=false,
      limit_infrastructure::Bool=false,
      storage::String="non",
      transmission::Bool=false,
      k_ids::Array{Int64,1}=Array{Int64,1}(),
      print_flag::Bool=true,
      kwargs...
                        # simple_extreme_days=true
                        # extreme_day_selection_method="feasibility", "slack", "none"
                        # + extreme_value_descr_ar
                        # needs input data for optimization problem
                        )
    # QUESTION: should keyword arguments be specified or rather be kwargs? kwargs may not work because the subsequent functions would through an error that some of the keyword arguments are not supported
    # simple extreme value selection
    use_simple_extr = !isempty(extr_value_descr_ar)
    extr_vals=ClustData
    extr_idcs=Int[]
    ts_data_mod=ts_data
    if use_simple_extr
       ts_data_mod,extr_vals,extr_idcs = simple_extr_val_sel(ts_data,extr_value_descr_ar;rep_mod_method=rep_mod_method)
    end
    
    # run initial clustering 
    clust_res = run_clust(ts_data_mod;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust,n_init=n_init,iterations=iterations,attribute_weights=attribute_weights,save=save,get_all_clust_results=get_all_clust_results,kwargs...)
   
   # if simple: representation modification
    clust_data=clust_res.best_results
    if use_simple_extr
      clust_data = representation_modification(extr_vals,clust_data)
    end
    
    if extreme_event_selection_method=="none"
      return ClustResult(clust_res,clust_data) # TODO: adjust clust_config in these functions
    elseif (extreme_event_selection_method !="feasibility") && (extreme_event_selection_method != "slack")
      @warn "extreme_event_selection_method - "*extreme_event_selection_method*" - does not match any of the three predefined keywords: feasibility, append, none. The function assumes -none-."
      return ClustResult(clust_res,clust_data) # TODO: adjust clust_config in these functions
    end
    
    # convert ts_data into N individual ClustData structs
    ts_data_indiv_ar = clustData_individual(ts_data) 
    is_feasible = false # indicates if optimization result from clustered input data is feasible on operatoins optimization with full input data 
    
    i=0 
    while !is_feasible 
      i+=1
      # initial design and operations optimization
      d_o_opt = run_opt(clust_data,opt_data;solver=solver,descriptor=descriptor,co2_limit=co2_limit,existing_infrastructure=existing_infrastructure,limit_infrastructure=limit_infrastructure,storage=storage,transmission=transmission,slack_cost=Inf,print_flag=print_flag)
      dvs = get_cep_design_variables(d_o_opt)
      # run individual optimization with fixed design
      o_opt_individual = OptResult[]
      if extreme_event_selection_method=="feasibility"
        eval_res = Symbol[] 
      elseif extreme_event_selection_method=="slack"
        eval_res = OptVariable[] 
      end 
      for k=1:ts_data.K
        # TODO: include in run_opt an option to turn off warnings. This optimization is often infeasible, and it currently gives a warning every time. There should be an option for this case to turn it off. 
        if extreme_event_selection_method=="feasibility"
           push!(o_opt_individual,run_opt(ts_data_indiv_ar[k],opt_data,d_o_opt.opt_config,dvs;solver=solver,slack_cost=Inf))
           push!(eval_res,o_opt_individual[k].status)
        elseif extreme_event_selection_method=="slack"
           slack_cost==Inf && (@warn "extreme_event_selection_method is -slack-,but slack cost are Inf")
           push!(o_opt_individual,run_opt(ts_data_indiv_ar[k],opt_data,d_o_opt.opt_config,dvs;solver=solver,slack_cost=slack_cost))
           push!(eval_res,get_cep_slack_variables(o_opt_individual[k]))
         end 
      end
      is_feasible = check_indiv_opt_feasibility(eval_res)
      println("feasibility: ",is_feasible, " i=",i)  # TODO - delete this line
      is_feasible && return ClustResult(clust_res,clust_data) # TODO: adjust clust_config in these functions
     
      # get infeasible value
      idx_infeas = get_index_inf(eval_res)
      push!(extr_idcs,idx_infeas)
      println(idx_infeas)
      extr_val_inf = extreme_val_output(ts_data,idx_infeas,rep_mod_method=rep_mod_method)
      # add extr_val_inf to extr_vals (using representation modification method)
      if typeof(extr_vals)==DataType
        extr_vals=extr_val_inf
      else
        extr_vals = representation_modification(extr_val_inf,extr_vals)
      end
      if rep_mod_method=="append"
        ts_data_mod = input_data_modification(ts_data,extr_idcs)
        clust_res = run_clust(ts_data_mod;norm_op=norm_op,norm_scope=norm_scope,method=method,representation=representation,n_clust=n_clust,n_init=n_init,iterations=iterations,attribute_weights=attribute_weights,save=save,get_all_clust_results=get_all_clust_results,kwargs...)
        clust_data=clust_res.best_results
        clust_data = representation_modification(extr_vals,clust_data) 
      elseif rep_mod_method == "feasibility"
        clust_data = representation_modification(extr_val_inf,clust_data) 
      else 
        @error "rep_mod_method does not exist" # TODO: Write automatic check functions for the different options
      end

    end
    # while !is_feasible
    #   for i=1:365
    #     method that puts one day out of ClustData into its own ClustData struct
    #     run_opt() single day, given DVs(operations only) 
    #   end
    #   is_feasible = [depends on if any day was infeasible]
    #   if is_feasible: break out of while loop here
    #   idx_extr_val = feasibility: first infeasible index; append: idx with highest slack variable
    #   extr_val_output(idx_extr_val)
    #   representation_modification()
    #   if append: run_clust()  # really? should representation modification not be afterwards? / figure 2.5 Constantin Thesis
    #   
    #   DVs = run_opt().variables["CAP"]
    # end
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    #
    
    
    return ClustResult(clust_res,clust_data) # TODO: adjust clust_config in these functions

end

"""
    function run_clust_extr(
          ts_data::ClustData,
          opt_data::OptDataCEP;
          kwargs...
          )

Clustering and extreme value selection WITHOUT simple extreme values.
"""
function run_clust_extr(
      ts_data::ClustData,
      opt_data::OptDataCEP;
      kwargs...
      )
      return run_clust_extr(ts_data,opt_data,SimpleExtremeValueDescr[];kwargs...)
end

"""
function simple_extr_val_sel(data::ClustData,
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )

Selects simple extreme values and returns modified data, extreme values, and the corresponding indices.
"""
function simple_extr_val_sel(data::ClustData,
                             extr_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )
  idcs = simple_extr_val_ident(data,extr_value_descr_ar)
  extr_vals = extreme_val_output(data,idcs;rep_mod_method=rep_mod_method)
  # for append method: modify data to be clustered to only contain the values that are not extreme values
  if rep_mod_method=="feasibility"
    data_mod = data
  elseif rep_mod_method=="append"
    data_mod = input_data_modification(data,idcs)
  else
    @error("rep_mod_method - "*rep_mod_method*" - does not exist")
  end
  return data_mod,extr_vals,idcs
end

"""
function simple_extr_val_sel(data::ClustData,
                             extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1};
                             rep_mod_method::String="feasibility"
                             )

Wrapper function for only one simple extreme value.
Selects simple extreme values and returns modified data, extreme values, and the corresponding indices.
"""
function simple_extr_val_sel(data::ClustData,
                             extr_value_descr::SimpleExtremeValueDescr;
                             rep_mod_method::String="feasibility"
                             )
  return simple_extr_val_sel(data,[extr_value_descr];rep_mod_method=rep_mod_method)
end

"""
    function simple_extr_val_ident(data::ClustData,extreme_value_descr::Array{SimpleExtremeValueDescr,1})

identifies multiple simple extreme values from the data and returns array of column indices of extreme value within data

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustData,
                               extreme_value_descr_ar::Array{SimpleExtremeValueDescr,1})
  idcs = Array{Int,1}()
  # for each desired extreme value description, finds index of that extreme value within data
  for i=1:length(extreme_value_descr_ar)
    push!(idcs,simple_extr_val_ident(data,extreme_value_descr_ar[i]))
  end
  return idcs
end

"""
    function simple_extr_val_ident(data::ClustData,extreme_value_descr::SimpleExtremeValueDescr)

identifies a single simple extreme value from the data and returns column index of extreme value

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustData,
                               extreme_value_descr::SimpleExtremeValueDescr)
  return simple_extr_val_ident(data, extreme_value_descr.data_type; extremum=extreme_value_descr.extremum, peak_def=extreme_value_descr.peak_def)
end

"""
    function simple_extr_val_ident(data::ClustData,data_type::String;extremum="max",peak_def="absolute")

identifies a single simple extreme value from the data and returns column index of extreme value

data_type: any attribute from the attributes contained within *data*
extremum: "min" or "max"
peak_def: "absolute" or "integral"
"""
function simple_extr_val_ident(data::ClustData,
                               data_type::String;
                               extremum::String="max",
                               peak_def::String="absolute")
  # TODO: Possibly add option to find maximum among all series of a data_type for a certain node
  !(data_type in keys(data.data)) && @error("the provided data type - "*data_type*" - is not contained in data")
  return simple_extr_val_ident(data.data[data_type]; extremum=extremum, peak_def=peak_def)
end

"""
    function simple_extr_val_ident(data::Array{Float64};extremum="max",peak_def="absolute")
"""
function simple_extr_val_ident(data::Array{Float64};
                               extremum::String="max",
                               peak_def::String="absolute")
  # set data to be compared
  if peak_def=="absolute"
    data_eval = data
  elseif peak_def=="integral"
    data_eval = sum(data,dims=1)
  else
    @error("peak_def - "*peak_def*" - not defined")
  end
  # find minimum or maximum index. Second argument returns cartesian indices, second argument of that is the column (period) index
  if extremum=="max"
    idx = findmax(data_eval)[2][2]
  elseif extremum=="min"
    idx = findmin(data_eval)[2][2]
  else
    @error("extremum - "*extremum*" - not defined")
  end
  return idx
end

"""
    function input_data_modification(data::ClustData,extr_val_idcs::Array{Int,1})

returns ClustData structs with extreme vals and with remaining input data [data-extreme_vals].
Gives extreme vals the weight that they had in data.
This function is needed for the append method for representation modification
"""
function input_data_modification(data::ClustData,extr_val_idcs::Array{Int,1})
  unique_extr_val_idcs = unique(extr_val_idcs)
  K_dn = data.K- length(unique_extr_val_idcs)
  data_dn=Dict{String,Array}()
  for dt in keys(data.data)
    data_dn[dt] = data.data[dt][:,setdiff(1:size(data.data[dt],2),extr_val_idcs)] #take all columns but the ones that are extreme vals. If index occurs multiple times, setdiff only treats it as one.
  end
  weights_dn = data.weights[setdiff(1:size(data.weights,2),extr_val_idcs)]
  data_modified = ClustData(data.region,K_dn,data.T,data_dn,weights_dn;mean=data.mean,sdv=data.sdv)
  return data_modified
end

"""
    function input_data_modification(data::ClustData,extr_val_idcs::Int)

wrapper function for a single extreme val.
returns ClustData structs with extreme vals and with remaining input data [data-extreme_vals].
Gives extreme vals the weight that they had in data.
"""
function input_data_modification(data::ClustData,extr_val_idcs::Int)
  return input_data_modification(data,[extr_val_idcs])
end

"""
   function extreme_val_output(data::ClustData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")

Takes indices as input and returns ClustData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")
  unique_extr_val_idcs = unique(extr_val_idcs)
  K_ed = length(unique_extr_val_idcs)
  data_ed=Dict{String,Array}()
  for dt in keys(data.data)
    data_ed[dt] = data.data[dt][:,unique_extr_val_idcs]
  end
  weights_ed=[]
  if rep_mod_method == "feasibility"
    weights_ed = zeros(length(unique_extr_val_idcs))
  elseif rep_mod_method == "append"
    weights_ed = data.weights[unique_extr_val_idcs]
  else
    @error("rep_mod_method - "*rep_mod_method*" - does not exist")
  end
  extr_vals = ClustData(data.region,K_ed,data.T,data_ed,weights_ed;mean=data.mean,sdv=data.sdv)
  return extr_vals
end

"""
   function extreme_val_output(data::ClustData,
                            extr_val_idcs::Array{Int,1};
                            rep_mod_method="feasibility")

wrapper function for a single extreme val.
Takes indices as input and returns ClustData struct that contains the extreme vals from within data.
"""
function extreme_val_output(data::ClustData,
                            extr_val_idcs::Int;
                            rep_mod_method="feasibility")
  return extreme_val_output(data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end

"""
function representation_modification(extr_vals::ClustData,
                                     clust_data::ClustData,
                                     )

Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(extr_vals::ClustData,
                                     clust_data::ClustData,
                                     )
                                     #TODO: The input order of extr_vals and clust_data should probably be reversed. Usually, we return the modified version of the first input argument.
  K_mod = clust_data.K + extr_vals.K
  data_mod=Dict{String,Array}()
  for dt in keys(clust_data.data)
    data_mod[dt] = [clust_data.data[dt] extr_vals.data[dt]]
  end
  weights_mod = deepcopy(clust_data.weights)
  for w in extr_vals.weights
    push!(weights_mod,w)
  end
  return ClustData(clust_data.region,K_mod,clust_data.T,data_mod,weights_mod;mean=clust_data.mean,sdv=clust_data.sdv)
end

"""
    function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Array{Int,1};
                                     rep_mod_method::String="feasibility")

Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Array{Int,1};
                                     rep_mod_method::String="feasibility")
  extr_vals = extreme_val_output(full_data,extr_val_idcs;rep_mod_method=rep_mod_method)
  return representation_modification(extr_vals,clust_data;rep_mod_method=rep_mod_method)
end

"""
    function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")

wrapper function for a single extreme val.
Merges the clustered data and extreme vals into one ClustData struct. Weights are chosen according to the rep_mod_method
"""
function representation_modification(full_data::ClustData,
                                     clust_data::ClustData,
                                     extr_val_idcs::Int;
                                     rep_mod_method::String="feasibility")
  return representation_modification(full_data,clust_data,[extr_val_idcs];rep_mod_method=rep_mod_method)
end
