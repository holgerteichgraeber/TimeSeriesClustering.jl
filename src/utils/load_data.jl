"""
    load_timeseriesdata!(dt::Dict{String,Array}, data_path::String; num::Int64=0)
- Adding the information in the `*.csv` file at `data_path` to the data dictionary
The `*.csv` files shall have the following structure and must have the same length:
|Timestamp |[column names...]|
|[iterator]|[values]         |
The first column should be called `Timestamp` if it contains a time iterator
The other columns can specify the single timeseries like specific geolocation.
"""
function load_timeseries_data!(data::Dict{String,Array},
                              data_path::String;
                              num::Int64=0
                              )
    base_name=basename(data_path)
    data_name=split(base_name,".")[1]
    data_df=CSV.read(data_path;allowmissing=:none)
    for column in eachcol(data_df, true)
      if findall([:Timestamp,:time,:Time,:Zeit].==(column[1]))==[]
          data[data_name*"-"*string(column[1])]=Float64.(column[2])
          newnum=length(column[2])
          if newnum!=num && num!=0
              throw(@error("The TimeSeries have different lengths!"))
          else
              num=newnum
          end
      end
    end
    return num
end #load_pricedata

"""
    load_timeseriesdata(data_path::String; region::String="", K-#Periods, T-#Segments)
- Loading all `*.csv` files in the folder or the file `data_path`
The `*.csv` files shall have the following structure and must have the same length:
|Timestamp |[column names...]|
|[iterator]|[values]         |
The first column should be called `Timestamp` if it contains a time iterator
The other columns can specify the single timeseries like specific geolocation.
Each column in `[file name].csv` file will be added to the ClustData.data called `"[file name]-[column name]"`
- region is an additional String to specify the loaded time series data
- K describes the number of periods in the input data
- T describes the length of each period
"""
function load_timeseries_data(data_path::String;
                              region::String="",
                              K=365::Int,
                              T=24::Int
                              )
  data = Dict{String,Array}()
  num=0
  if isdir(data_path)
      for full_data_name in readdir(data_path)
          if split(full_data_name,".")[end]=="csv"
              num=load_timeseries_data!(data, joinpath(data_path, full_data_name); num=num)
          end
      end
  elseif isfile(data_path)
      load_timeseries_data!(data, data_path; num=num)
  else
      throw(@error("The path $data_path is neither recognized as a directory nor as a file"))
  end
  data_full =  FullInputData(region, num, data)
  data_reshape =  ClustData(data_full,K,T)
  return data_reshape, data_full
end #load_pricedata

"""
    load_timeseriesdata(application::String, region::String, K-#Periods, T-#Segments)
Loading from .csv files provided with the package in the folder ../ClustForOpt/data/{application}/{region}/TS
Timestamp-column has to be called Timestamp
Other columns have to be called with the location/node name
for application:
- `DAM`: Day Ahead Market
- `CEP`: Capacity Expansion Problem
and regions:
- `"GER_1"`: Germany 1 node
- `"GER_18"`: Germany 18 nodes
- `"CA_1"`: California 1 node
- `"CA_14"`: California 14 nodes
- `"TX_1"`: Texas 1 node
"""
function load_timeseries_data(application::String,
                              region::String;
                              K=365::Int,
                              T=24::Int
                              )
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data",application,region,"TS"))
  return load_timeseries_data(data_path; region=region, K=K, T=T)
end #load_pricedata

"""
    load_cep_data(region::String)
Loading from .csv files in a the folder ../ClustForOpt/data/CEP/{region}/
Follow instructions for the CSV-Files:
- `nodes`:       `nodes x region, infrastruct, capacity-of-different-tech... in MW_el`
- `var_costs`:     `tech x [USD for fossils: in USD/MWh_el, CO2 in kg-CO₂-eq./MWh_el]` # Variable costs per year
- `fix_costs`:     `tech x [USD in USD/MW_el, CO2 in kg-CO₂-eq./MW_el]` # Fixed costs per year
- `cap_costs`:     `tech x [USD in USD/MW_el, CO2 in kg-CO₂-eq./MW_el]` # Entire (NOT annulized) Costs per Investment in technology
- `techs`:        `tech x [categ,sector,lifetime in years,effic in %,fuel]`
- `lines`:       `lines x [node_start,node_end,reactance,resistance,power,voltage,circuits,length]`
for regions:
- `"GER_1"`: Germany 1 node
- `"GER_18"`: Germany 18 nodes
- `"CA_1"`: California 1 node
- `"CA_14"`: California 14 nodes
- `"TX_1"`: Texas 1 node
"""
function load_cep_data(region::String)
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data","CEP",region))
  nodes=CSV.read(joinpath(data_path,"nodes.csv"),allowmissing=:none)
  var_costs=CSV.read(joinpath(data_path,"var_costs.csv"),allowmissing=:none)
  fix_costs=CSV.read(joinpath(data_path,"fix_costs.csv"),allowmissing=:none)
  cap_costs=CSV.read(joinpath(data_path,"cap_costs.csv"),allowmissing=:none)
  techs=CSV.read(joinpath(data_path,"techs.csv"),allowmissing=:none)
  if isfile(joinpath(data_path,"lines.csv"))
      lines=CSV.read(joinpath(data_path,"lines.csv"),allowmissing=:none)
  else
      lines=DataFrame()
  end
  # The time for the cap-investion to be paid back is the minimum of the max. financial lifetime and the lifetime of the product (If it's just good for 5 years, you'll have to rebuy one after 5 years)
  # annuityfactor = (1+i)^y*i/((1+i)^y-1) , i-discount_rate and y-payoff years
  techs[:annuityfactor]=map((lifetime,financial_lifetime,discount_rate) -> (1+discount_rate)^(min(financial_lifetime,lifetime))*discount_rate/((1+discount_rate)^(min(financial_lifetime,lifetime))-1), techs[:lifetime],techs[:financial_lifetime],techs[:discount_rate])
  # The capital costs (given by currency value in column 4) are adjusted by the annuity factor"
  cap_costs[4]=map((tech, EUR) -> find_val_in_df(techs,:tech,tech,:annuityfactor)*EUR, cap_costs[:tech], cap_costs[4])
  # Emissions (column 5 and on) are just devided by the lifetime, without discount_rate
  for name in names(cap_costs)[5:end]
      cap_costs[name]=map((tech, emission) -> emission/find_val_in_df(techs,:tech,tech,:lifetime), cap_costs[:tech], cap_costs[name])
  end
  return OptDataCEP(region,nodes,var_costs,fix_costs,cap_costs,techs,lines)
end #load_pricedata
