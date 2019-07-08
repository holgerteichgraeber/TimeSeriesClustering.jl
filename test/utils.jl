@testset "sort centers" begin
  c = [1 2 3;4 5 6]
  w = [0.2, 0.5, 0.3]
  c_s, w_s = sort_centers(c,w)
  @test all(c_s .== c[:,[2,3,1]])
  @test all(w_s .== w[[2,3,1]])
end

@testset "sakoe_chiba_band" begin
  r=0
  l=3
  i2min,i2max = sakoe_chiba_band(r,l)
  @test all(i2min .== [1,2,3])
  @test all(i2max .== [1,2,3])
  r=1
  l=3
  i2min,i2max = sakoe_chiba_band(r,l)
  @test all(i2min .== [1,1,2])
  @test all(i2max .== [2,3,3])
  r=3
  l=3
  i2min,i2max = sakoe_chiba_band(r,l)
  @test all(i2min .== [1,1,1])
  @test all(i2max .== [3,3,3])
end

@testset "calc SSE" begin
  c = [1 2 3;4 5 6]
  a = [1,1,1]
  sse = calc_SSE(c,a)
  @test sse ≈ 2 + 2
end

# resize medoids

@testset "z_normalize" begin
  #srand(1991)
  data = rand(24,365)
  # hourly
  dn,mn,sdv = z_normalize(data;scope="hourly")
  @test sum(mn - mean(data,dims=2)) <= 1e-8
  @test sum(sdv - StatsBase.std(data,dims=2)) <= 1e-8

  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8

  # full
  dn,mn,sdv = z_normalize(data;scope="full")
  @test sum(mn .- mean(data)) <= 1e-8
  @test sum(sdv .- StatsBase.std(data)) <= 1e-8

  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8

  # sequence
  data = ones(5,4)
  m_t=zeros(4)
  sdv_t=zeros(4)
  d1 = [1,2,3,4,5]
  m_t[1] = mean(d1)
  sdv_t[1]= StatsBase.std(d1)
  d2 = [3,3,3,3,3]
  m_t[2] = mean(d2)
  sdv_t[2] = StatsBase.std(d2)
  d3 = [-1,-2,1,2,0]
  m_t[3] = mean(d3)
  sdv_t[3] = StatsBase.std(d3)
  d4 = [0,1,5,3,4]
  m_t[4] = mean(d4)
  sdv_t[4] = StatsBase.std(d4)
  data[:,1]=d1
  data[:,2]=d2
  data[:,3]=d3
  data[:,4]=d4
  dn,mn,sdv = z_normalize(data;scope="sequence")
  println(mn)
  println(sdv)
  println(dn)
  @test sum(m_t -mn) <= 1e-8
  @test sum(sdv_t - sdv) <= 1e-8
  @test sum(isnan.(dn)) == 0 # tests edge case standard deviation 0

  data_out = undo_z_normalize(ones(5,2),mn,sdv;idx=[1,2,2,1])
  @test size(data_out,2) ==2
  @test sum(data_out[:,1] - ( ones(5)*1*(sdv_t[1]+sdv_t[4])/2 .+ (m_t[1]+m_t[4])/2) ) <=1e-8
  @test sum(data_out[:,2] - ( ones(5)*1*(sdv_t[2]+sdv_t[3])/2 .+ (m_t[2]+m_t[3])/2) ) <=1e-8

  # edge case 1: data with zero standard deviation
  data = zeros(24,365)
  # full
  dn,mn,sdv = z_normalize(data;scope="full")
  @test sum(mn .- mean(data)) <= 1e-8
  @test sum(sdv .- StatsBase.std(data)) <= 1e-8
  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8

  # hour
  dn,mn,sdv = z_normalize(data;scope="hourly")
  @test sum(mn - mean(data,dims=2)) <= 1e-8
  @test sum(sdv - StatsBase.std(data,dims=2)) <= 1e-8

  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8

  # sequence
  #already covered by case above d2

  # edge case 2: data with zero standard deviation, but nonzero values
  data = ones(24,365)
  # full
  dn,mn,sdv = z_normalize(data;scope="full")
  @test sum(mn .- mean(data)) <= 1e-8
  @test sum(sdv .- StatsBase.std(data)) <= 1e-8
  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8

  # hour
  dn,mn,sdv = z_normalize(data;scope="hourly")
  @test sum(mn - mean(data,dims=2)) <= 1e-8
  @test sum(sdv - StatsBase.std(data,dims=2)) <= 1e-8

  data_out = undo_z_normalize(dn,mn,sdv)
  @test sum(data_out - data) <=1e-8

  # sequence
  #already covered by case above d2
end
