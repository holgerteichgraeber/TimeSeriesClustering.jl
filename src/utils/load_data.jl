"""
function load_pricedata(region::String)

Loads price data from either GER or CA    
"""
function load_pricedata(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  if region =="CA" #\$/MWh
    region_str = ""
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.txt"))
  elseif region == "GER" #EUR/MWh
    region_str = "GER_"
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.txt"))
  else
    error("Region ",region," not defined.")
  end
  data_orig = Array(readtable(region_data, separator = '\t', header = false))
  data_full = FullInputData(region,size(data_orig)[1];el_price=data_orig)
  data_reshape =  ClustInputData(data_full,365,24)
  cd(wor_dir) # change working directory to old previous file's dir
  return data_reshape, data_full
end #load_pricedata

"""
function load_capacity_expansion_data(region::String)

outputs one dict with the following keys. They each contain a 24x365 array:
eldemand [GW]
solar availability [-]
wind availability [-]
"""
function load_capacity_expansion_data(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  
  N=nothing # initialize 
  demand=nothing
  solar=nothing
  wind=nothing  
  if region == "TX"
    # Texas system data from Merrick (Energy Economics) and Merrick (MS thesis) 
    #demand - [GW]
    demand= Array(readtable(normpath(joinpath(pwd(),"..","..","data","texas_merrick","demand.txt")),separator=' ')[:DEM]) # MW
    demand=reshape(demand,(size(demand)[1],1))
     # load growth (Merrick assumption)
    demand=1.486*demand
    demand=demand/1000 # GW
    N=size(demand)[1]
    # solar availability factor
    solar= Array(readtable(normpath(joinpath(pwd(),"..","..","data","texas_merrick","TexInsolationFactorV1.txt")),separator=' ')[:solar_61])
    solar=reshape(solar,(size(solar)[1],1))
    solar = solar/1000
   # wind availability factor
    wind= Array(readtable("/home/hteich/.julia/v0.6/ClustForOpt_priv/data/texas_merrick/windfactor2.txt",separator=' ')[:Wind_61])
    wind=reshape(wind,(size(wind)[1],1))
  else
    error("region "*region*" not implemented.")
  end # region
  
  data_full = FullInputData(region,N;el_demand=demand,solar=solar,wind=wind)
  data_reshape =  ClustInputData(data_full,365,24)
  
  cd(wor_dir) # change working directory to old previous file's dir
  return data_reshape,data_full 

 # TODO - add CA data
 # TODO - add multiple nodes data
end

"""
function load_input_data(application::String,region::String)

wrapper function to call capacity expansion data and price data

applications:
- DAM - electricity day ahead market prices
- CEP - capacity expansion problem data

potential outputs:
- elprice [electricity price]
- wind
- solar 
- eldemand [electricity demand]
  
  
"""
function load_input_data(application::String,region::String)
  ret=nothing
  if application == "DAM"
    ret=load_pricedata(region)
  elseif application == "CEP"
    ret= load_capacity_expansion_data(region)
  else
    error("application "*application*" not defined")
  end
  #check if output is of the right format
  if typeof(ret) != Tuple{ClustInputData,FullInputData}
    error("Output from load_input_data needs to be of ClustInputData,FullInputData") 
  end
  return ret
end
