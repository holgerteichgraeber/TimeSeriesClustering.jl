using Base.Test
push!(LOAD_PATH,normpath("../src"))
using ClustForOpt

@testset "z_normalize" begin
  srand(1991)
  data = rand(24,365)
  # hourly
  dn,mn,sdv = z_normalize(data,hourly=true)
  @test sum(mn - mean(data,2)) <= 1e-8
  @test sum(sdv - std(data,2)) <= 1e-8

  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8
  
  # full 
  dn,mn,sdv = z_normalize(data,hourly=false)
  @test sum(mn - mean(data)) <= 1e-8
  @test sum(sdv - std(data)) <= 1e-8

  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8
  
  # sequence
  data = ones(5,4)
  m_t=zeros(4)
  sdv_t=zeros(4)
  d1 = [1,2,3,4,5]
  m_t[1] = mean(d1)
  sdv_t[1]= std(d1)
  d2 = [3,3,3,3,3]
  m_t[2] = mean(d2)
  sdv_t[2] = std(d2)
  d3 = [-1,-2,1,2,0]
  m_t[3] = mean(d3)
  sdv_t[3] = std(d3)
  d4 = [0,1,5,3,4]
  m_t[4] = mean(d4)
  sdv_t[4] = std(d4)
  data[:,1]=d1
  data[:,2]=d2
  data[:,3]=d3
  data[:,4]=d4
  dn,mn,sdv = z_normalize(data,sequence=true)
  @test sum(m_t -mn) <= 1e-8
  @test sum(sdv_t - sdv) <= 1e-8 

  data_out = undo_z_normalize(ones(5,2),mn,sdv;idx=[1,2,2,1])
  @test size(data_out,2) ==2
  @test sum(data_out[:,1] - ( ones(5)*1*(sdv_t[1]+sdv_t[4])/2 + (m_t[1]+m_t[4])/2) ) <=1e-8
  @test sum(data_out[:,2] - ( ones(5)*1*(sdv_t[2]+sdv_t[3])/2 + (m_t[2]+m_t[3])/2) ) <=1e-8
end



