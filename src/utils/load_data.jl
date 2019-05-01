"""
    load_timeseriesdata(data_path::String; T-#Segments,years::Array{Int,1}=# years to be selected for the time series, att::Array{String,1}=# attributes to be loaded)
- Loading all `*.csv` files in the folder or the file `data_path`
- The `*.csv` files shall have the following structure and must have the same length:
|Timestamp |Year  |[column names...]|
|----------|------|-----------------|
|[iterator]|[year]|[values]         |
- The first column should be called `Timestamp` if it contains a time iterator
- The second column should be called `Year` and contains the corresponding year
- The other columns can specify the single timeseries like specific geolocation.
- Each column in `[file name].csv` file will be added to the ClustData.data called `"[file name]-[column name]"`
- Loads all attributes if the `att`-Array is empty or only the ones specified in it
"""
function load_timeseries_data(data_path;
                              region::String="none",
                              T::Int=24,
                              years::Array{Int,1}=[2016],
                              att::Array{String,1}=Array{String,1}())
  dt = Dict{String,Array}()
  num=0
  K=0
  #Check if data_path is directory or file
  if isdir(data_path)
      for full_data_name in readdir(data_path)
          if split(full_data_name,".")[end]=="csv"
              data_name=split(full_data_name,".")[1]
              if isempty(att) || data_name in att
                  # Add the
                  K=add_timeseries_data!(dt, data_name, data_path; K=K, T=T, years=years)
              end
          end
      end
  elseif isfile(data_path)
      full_data_name=splitdir(data_path)[end]
      data_name=split(full_data_name,".")[1]
      K=add_timeseries_data!(dt, data_name, dirname(data_path); K=K, T=T, years=years)
  else
      throw(@error("The path $data_path is neither recognized as a directory nor as a file"))
  end
  # Store the data
  ts_input_data =  ClustData(FullInputData(region, years, num, dt),K,T)
  return ts_input_data
end #load_timeseries_data

"""
    add_timeseries_data!(dt::Dict{String,Array}, data::DataFrame; K::Int=0, T::Int=24, years::Array{Int,1}=[2016])
selects first the years and second the data_points so that their number is a multiple of T and same with the other timeseries
"""
function add_timeseries_data!(dt::Dict{String,Array},
                            data_name::SubString,
                            data_path::String;
                            K::Int=0,
                            T::Int=24,
                            years::Array{Int,1}=[2016])
    #Load the data
    data_df=CSV.read(joinpath(data_path,data_name*".csv");allowmissing=:none)
    # Add it to the dictionary
    return add_timeseries_data!(dt,data_name, data_df; K=K, T=T, years=years)
end

"""
    add_timeseries_data!(dt::Dict{String,Array}, data::DataFrame; K::Int=0, T::Int=24, years::Array{Int,1}=[2016])
selects first the years and second the data_points so that their number is a multiple of T and same with the other timeseries
"""
function add_timeseries_data!(dt::Dict{String,Array},
                            data_name::SubString,
                            data::DataFrame;
                            K::Int=0,
                            T::Int=24,
                            years::Array{Int,1}=[2016])
    # find the right years to select
    time_name=find_column_name(data, [:Timestamp, :timestamp, :Time, :time, :Zeit, :zeit, :Date, :date, :Datum, :datum]; error=false)
    year_name=find_column_name(data, [:year, :Year, :jahr, :Jahr])
    data_selected=data[in.(data[year_name],[years]),:]
    for column in eachcol(data_selected, true)
        # check that this column isn't time or year
        if !(column[1] in [time_name, year_name])
            K_calc=Int(floor(length(column[2])/T))
            if K_calc!=K && K!=0
                @error("The time_series $(column[1]) has K=$K_calc != K=$K of the previous")
            else
                K=K_calc
            end
            dt[data_name*"-"*string(column[1])]=Float64.(column[2][1:(Int(T*K))])
        end
    end
    return K
end

"""
        find_column_name(df::DataFrame, name_itr::Arrray{Symbol,1})
find wich of the supported name in `name_itr` is used as an
"""
function find_column_name(df::DataFrame, name_itr::Array{Symbol,1}; error::Bool=true)
    col_name=:none
    for name in name_itr
        if name in names(df)
            col_name=name
            break
        end
    end
    if error
        col_name!=:none || throw(@error "No $(name_itr) in $(repr(df)).")
    else
        col_name!=:none || @warn "No $(name_itr) in $(repr(df))."
    end
    return col_name
end

"""
        combine_timeseries_weather_data(ts::ClustData,ts_weather::ClustData)
-`ts` is the shorter timeseries with e.g. the demand
-`ts_weather` is the longer timeseries with the weather information
The `ts`-timeseries is repeated to match the number of periods of the longer `ts_weather`-timeseries.
If the number of periods of the `ts_weather` data isn't a multiple of the `ts`-timeseries, the necessary number of the `ts`-timeseries periods 1 to x are attached to the end of the new combined timeseries.
"""
function combine_timeseries_weather_data(ts::ClustData,
                                        ts_weather::ClustData)
    ts.T==ts_weather.T || throw(@error "The number of timesteps per period is not the same: `ts.T=$(ts.T)≢$(ts_weather.T)=ts_weather.T`")
    ts.K<=ts_weather.K || throw(@error "The number of timesteps in the `ts`-timeseries isn't shorter or equal to the ones in the `ts_weather`-timeseries.")
    ts_weather.K%ts.K==0 || @warn "The number of periods of the `ts_weather` data isn't a multiple of the other `ts`-timeseries: periods 1 to $(ts_weather.K%ts.K) are attached to the end of the new combined timeseries."
    ts_data=deepcopy(ts_weather.data)
    ts_mean=deepcopy(ts_weather.mean)
    ts_sdv=deepcopy(ts_weather.sdv)
    for (k,v) in ts.data
        ts_data[k]=repeat(v, 1, ceil(Int,ts_weather.K/ts.K))[:,1:ts_weather.K]
    end
    for (k,v) in ts.mean
        ts_mean[k]=v
    end
    for (k,v) in ts.sdv
        ts_sdv[k]=v
    end

    return ClustData(ts.region, ts_weather.years, ts_weather.K, ts_weather.T, ts_data, ts_weather.weights, ts_mean, ts_sdv, ts_weather.delta_t, ts_weather.k_ids)
end
