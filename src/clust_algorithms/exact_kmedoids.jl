# exact k-medoids modeled similar as in Kotzur et al, 2017
using Distances
using JuMP
 #using GLPKMathProgInterface 
 #using Cbc
using Gurobi  # Gurobi is super fast compared to the other solvers

"""
   kmedoidsResult()
 
Holds results of kmedoids run

"""
mutable struct kmedoidsResult
    medoids::Array{Float64}
    assignments::Array{Int}
    totalcost::Float64
end


"""  
   results = kmedoids_exact()
   data { HOURS,DAYS }
Performs the exact kmedoids algorithm as in Kotzur et al, 2017

"""
function kmedoids_exact(
   data::Array{Float64},
   nclust::Int,
   _dist::SemiMetric = SqEuclidean();
   unnecessary_param::Int = 1
   )
N_i = size(data,2)


# calculate distance matrix
d_mat=pairwise(_dist,data)


# create jump model
m = Model(solver=GurobiSolver())  
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
tic()
status=solve(m)
toc()

println("status: ",status)
y_opt=round(Integer,getvalue(y))
z_opt=round(Integer,getvalue(z))
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
centerids = findn(z_opt)[1]
clustids = zeros(Int,N_i)
for i=1:N_i
  clustids[i] = id[centerids[i]]
end
centers = data[:,find(id.!=0.0)]
tot_dist = getobjectivevalue(m)
 # output centers
results = kmedoidsResult(centers, clustids, tot_dist) 

return results

end #kmedoids_exact

