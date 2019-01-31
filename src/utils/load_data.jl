"""
function load_timeseries_data(application::String, region::String, T-#Segments,
years::Array{Int64,1}=# years to be selected for the time series)
Loading from .csv files in a the folder ../ClustForOpt/data/{application}/{region}/TS
Timestamp-column has to be called Timestamp
Other columns have to be called with the location/node name
for application:
- DAM Day Ahead Market
- CEP Capacity Expansion Problem
and regions:
- GER Germany
- CA California
- TX Texas
"""
function load_timeseries_data( application::String,
                              region::String;
                              T::Int64=24,
                              years::Array{Int64,1}=[2016])
  dt = Dict{String,Array}()
  num=0
  K=0
  # Generate the data path based on application and region
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data",application,region,"TS"))
  #Loop through all available files
  for fulldataname in readdir(data_path)
      dataname=split(fulldataname,".")[1]
      #Load the data
      data_df=CSV.read(joinpath(data_path,fulldataname);allowmissing=:none)
      # Add it to the dictionary
      K=add_timeseries_data!(dt,dataname, data_df; K=K, T=T, years=years)
  end
  # Store the data
  ts_input_data =  ClustData(FullInputData(region, years, num, dt),K,T)
  return ts_input_data
end #load_timeseries_data

"""
function add_timeseries_data(dt::Dict{String,Array}, data::DataFrame; K::Int64=0, T::Int64=24, years::Array{Int64,1}=[2016])
    selects first the years and second the data_points so that their number is a multiple of T and same with the other timeseries
"""
function add_timeseries_data!(dt::Dict{String,Array},
                            dataname::SubString,
                            data::DataFrame;
                            K::Int64=0,
                            T::Int64=24,
                            years::Array{Int64,1}=[2016])
    # find the right years to select
    data_selected=data[in.(data[:year],[years]),:]
    for column in eachcol(data_selected, true)
        # check that this column isn't time or year
        if !(column[1] in [:Timestamp,:time,:Time,:Zeit,:year])
            K_calc=Int(floor(length(column[2])/T))
            if K_calc!=K && K!=0
                @error("The time_series $(column[1]) has K=$K_calc != K=$K of the previous")
            else
                K=K_calc
            end
            dt[dataname*"-"*string(column[1])]=Float64.(column[2][1:(Int(T*K))])
        end
    end
    return K
end

"""
function load_cep_data(region::String)
Loading from .csv files in a the folder ../ClustForOpt/data/CEP/{region}/
Follow instructions for the CSV-Files:
    nodes       nodes x region, infrastruct, capacity_of_different_tech... in MW_el
    var_costs   tech x [USD for fossils: in USD/MWh_el, CO2 in kg-CO₂-eq./MWh_el] # Variable costs per year
    fix_costs   tech x [USD in USD/MW_el, CO2 in kg-CO₂-eq./MW_el] # Fixed costs per year
    cap_costs   tech x [USD in USD/MW_el, CO2 in kg-CO₂-eq./MW_el] # Entire (NOT annulized) Costs per Investment in technology
    techs       tech x [categ,sector,lifetime in years,effic in %,fuel]
    lines       lines x [node_start,node_end,reactance,resistance,power,voltage,circuits,length]
for regions:
- GER Germany
- CA California
- TX Texas
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
