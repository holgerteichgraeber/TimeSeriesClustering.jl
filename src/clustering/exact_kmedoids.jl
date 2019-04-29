# exact k-medoids modeled similar as in Kotzur et al, 2017

"Holds results of kmedoids run"
mutable struct kmedoidsResult
    medoids::Array{AbstractFloat}
    assignments::Array{Int}
    totalcost::AbstractFloat
end


"""
    kmedoids_exact(
     data::Array{AbstractFloat},
     nclust::Int,
     _dist::SemiMetric = SqEuclidean(),
     env::Any;
     )
   results = kmedoids_exact()
   data { HOURS,DAYS }
Performs the exact kmedoids algorithm as in Kotzur et al, 2017
optimizer=Gurobi.Optimizer
"""
function kmedoids_exact(
   data::Array{AbstractFloat},
   nclust::Int,
   optimizer::DataType;
   _dist::SemiMetric = SqEuclidean(),
   )
   N_i = size(data,2)


  # calculate distance matrix
  d_mat=pairwise(_dist,data, dims=2)


  # create jump model
  m = JuMP.Model(with_optimizer(optimizer)) # GurobiSolver(env,OutputFlag=0)
  @variable(m,z[1:N_i,1:N_i],Bin)
  @variable(m,y[1:N_i],Bin)
  @objective(m,Min,sum(d_mat[i,j]*z[i,j] for i=1:N_i, j=1:N_i))
  for j=1:N_i
    @constraint(m,sum(z[i,j] for i=1:N_i)==1)
  end
  for i=1:N_i
    for j=1:N_i
    @constraint(m,z[i,j]<=y[i])
    end
  end
  @constraint(m,sum(y[i] for i=1:N_i) == nclust)

  # solve jump model
  optimize!(m)
  status=Symbol(termination_status(m))

  println("status: ",status)
  y_opt=round.(Integer,JuMP.value.(y))
  z_opt=round.(Integer,JuMP.value.(z))
   #println("y ",y_opt, " z ",z_opt)
  # determine centers and cluster mappings
  id = zeros(Int,N_i)
  ii=0
  for i=1:N_i
    if y_opt[i]==1
      ii +=1
      id[i]=ii
    end
  end
  nz = findall(!iszero,z_opt)
  centerids=Int[]
  for i=1:length(nz) # just take the first dimension of each of the elements of the array of cartesianCoordinates
    push!(centerids, nz[i][1])
  end
  clustids = zeros(Int,N_i)
  for i=1:N_i
    clustids[i] = id[centerids[i]]
  end
  centers = data[:,findall(id.!=0.0)]
  tot_dist = objective_value(m)
   # output centers
  results = kmedoidsResult(centers, clustids, tot_dist)

  return results

end #kmedoids_exact
