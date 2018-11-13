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
                              K=365,
                              T=24
                              )
  dt = Dict{String,Array}()
  num=0
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data",application,region,"TS"))
  for fulldataname in readdir(data_path)
      dataname=split(fulldataname,".")[1]
      data_df=CSV.read(joinpath(data_path,fulldataname);allowmissing=:none)
      for column in eachcol(data_df)
          if findall([:Timestamp,:time,:Time,:Zeit].==(column[1]))==[]
              dt[dataname*"-"*string(column[1])]=column[2]
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
  data_reshape =  ClustInputData(data_full,K,T)
  return data_reshape, data_full
end #load_pricedata

"""
function load_cepdata(region::String)

Loading from .csv files in a the folder ../ClustForOpt/data/CEP/{region}/

Follow instructions for the CSV-Files:
    nodes       nodes x installed capacity of different tech
    fixprices   tech x [EUR, CO2]
    varprices   tech x [EUR, CO2]
    techs       tech x [categ,sector,lifetime,effic,fuel,annuityfactor]

for regions:
- GER Germany
- CA California
- TX Texas
"""
function load_cep_data(region::String)
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data","CEP",region))
  nodes=CSV.read(joinpath(data_path,"nodes.csv"),allowmissing=:none)
  fixprices=CSV.read(joinpath(data_path,"fixprices.csv"),allowmissing=:none)
  varprices=CSV.read(joinpath(data_path,"varprices.csv"),allowmissing=:none)
  techs=CSV.read(joinpath(data_path,"techs.csv"),allowmissing=:none)
  return CEPData(nodes,fixprices,varprices,techs)
end #load_pricedata
