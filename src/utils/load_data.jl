normpath(joinpath(dirname(@__FILE__),"..","..","data"))
"""
function load_pricedata(region::String)

Loads price data from either GER or CA
"""
function load_pricedata(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  if region =="CA" #\$/MWh
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.csv"))
  elseif region == "GER" #EUR/MWh
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.csv"))
  else
    error("Region ",region," not defined.")
  end
  data_orig = CSV.read(region_data, separator = '\t', header = true)[Symbol(region)][:]
  data_full = FullInputData(region,size(data_orig)[1];el_price=data_orig)
  data_reshape =  ClustInputData(data_full,365,24)
  cd(wor_dir) # change working directory to old previous file's dir
  return data_reshape, data_full
end #load_pricedata

"""
function load_timeseriesdata(application::String, region::String)

Loads price data for applications:
- DAM - electricity day ahead market prices
- CEP - capacity expansion problem data

and regions:
- GER Germany
- CA California
- TX Texas
"""
function load_timeseriesdata(application::String, region::String)
  dt = Dict{String,Array}()
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data",application,region))https://juliadocs.github.io/Julia-Cheat-Sheet/
  for fulldataname in readdir(data_path)
      dataname=split(fulldataname,".")[1]
      if split(dataname,"_")[1]=="ts"
          data_df=CSV.read("$data_path/$fulldataname")
          for col in eachcol(data_df)
            dt[Symbol(split(dataname,"_")[2:end]*col[1])]=col[2]
            size=size(col[2])
          end
      end
  end
  data_full =  FullInputData(region, size, dt)
  data_reshape =  ClustInputData(data_full,365,24)
  return data_reshape, data_full
end #load_pricedata

#TODO State Data
function load_statedata(region::String)
  data_full = Dict{String,Array}()
  data_path=normpath(joinpath(dirname(@__FILE__),"..","..","data",application,region))
  for fulldataname in readdir(data_path)
      dataname=split(fulldataname,".")[1]
      if split(dataname,"_")[1]!="ts"
          data_df=CSV.read("$data_path/$fulldataname")
          for col in eachcol(anscombe)
            data_full[Symbol(split(dataname,"_")[2:end]*col[1])]=col[2]
          end
      end
  end
  data_reshape =  ClustInputData(dt,365,24)
  return data_reshape, data_full
end #load_pricedata

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
    ret=load_timeseriesdata(application, region)
  elseif application == "CEP"
    ret=load_timeseriesdata(application, region)
  else
    error("application "*application*" not defined")
  end
  #check if output is of the right format
  if typeof(ret) != Tuple{ClustInputData,FullInputData}
    error("Output from load_input_data needs to be of ClustInputData,FullInputData")
  end
  return ret
end
