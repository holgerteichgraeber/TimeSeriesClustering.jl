"""
function load_timeseriesdata(application::String, region::String, K-#Periods, T-#Segments)
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
                              K=365::Int,
                              T=24::Int
                              )
  dt = Dict{String,Array}()
  num=0
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data",application,region,"TS"))
  for fulldataname in readdir(data_path)
      dataname=split(fulldataname,".")[1]
      data_df=CSV.read(joinpath(data_path,fulldataname);allowmissing=:none)
      for column in eachcol(data_df, true)
          if findall([:Timestamp,:time,:Time,:Zeit].==(column[1]))==[]
              dt[dataname*"-"*string(column[1])]=Float64.(column[2])
              newnum=length(column[2])
              if newnum!=num && num!=0
                  @error("The TimeSeries have different lengths!")
              else
                  num=newnum
              end
          end
      end
  end
  data_full =  FullInputData(region, num, dt)
  data_reshape =  ClustData(data_full,K,T)
  return data_reshape, data_full
end #load_pricedata

"""
function load_cep_data(region::String)
Loading from .csv files in a the folder ../ClustForOpt/data/CEP/{region}/
Follow instructions for the CSV-Files:
    nodes       nodes x installed capacity of different tech in MW_el
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
  cap_costs[4]=map((tech, EUR) -> find_val_in_df(techs,:tech,tech,:annuityfactor)*EUR, cap_costs[:tech], cap_costs[4])
  cap_costs[:CO2]=map((tech, CO2) -> CO2/find_val_in_df(techs,:tech,tech,:lifetime), cap_costs[:tech], cap_costs[:CO2])
  return OptDataCEP(region,nodes,var_costs,fix_costs,cap_costs,techs,lines)
end #load_pricedata
