
"""
function subplot_clusters(centers::Array,weights::Array,axis::Any;region::String="GER",sorting::Bool=true,descr::String="",linestyle="-")
"""
function subplot_clusters(centers::Array,weights::Array,axis::Any;region::String="GER",sorting::Bool=true,descr::String="",linestyle="-")
   if sorting
     centers,weights = sort_centers(centers,weights) 
   end 
   for i=1:size(centers,2) # number of clusters
     axis["plot"](centers[:,i],color=cols[i],label=string(descr,": ","w=",round(weights[i]*100,2),"\%"),linestyle=linestyle )
   end
   ylim(-20,60)
end #function


  """
function plot_clusters(centers::Array,weights::Array,region::String;sorting::Bool=true,descr::String="")
  centers: hours x days e.g.[24x9] 

  """
function plot_clusters(centers::Array,weights::Array;region::String="GER",sorting::Bool=true,descr::String="")
   if sorting
     centers,weights = sort_centers(centers,weights) 
   end 
   figure()
   for i=1:size(centers,2) # number of clusters
     plot(centers[:,i],color=cols[i],label=string("w=",round(weights[i]*100,2),"\%") )
   end
   ylim(-20,60)
   xlabel("hour")
   if region == "GER"
     ylabel("EUR/MWh")
   elseif region == "CA"
     ylabel("USD/MWh")
   else
     error("region not defined: $region")
   end
   title(descr)
   legend()
end #function




  """
  plot_k_rev(range_k::Array,rev::Array{Dict,1},region::String)
  The array rev contains Dicts with:  
    key: name of feature
    features:
      name ( of method)
      rev
      color
      linestyle
      width

  """
function plot_k_rev(range_k::Array,methods::Array{Dict,1},descr::String; save::Bool=true)
  figure()
  fsize_ref = 16
  for m in methods
    plot(range_k,m["rev"]/methods[1]["rev"][1],label=m["name"],color=m["color"],linestyle=m["linestyle"],lw=m["width"])
  end
  xlabel("Number of clusters",fontsize=fsize_ref)
  ylabel("Objective function value",fontsize=fsize_ref)
  legend(loc="lower right",fontsize=fsize_ref-4,ncol=2)
  ax = axes()
  ax[:tick_params]("both",labelsize=fsize_ref-1)
  xticks(range_k,range_k)
  tight_layout()
  ylim((0.0,1.05)) # 1.05
  save && savefig(descr,format="png",dpi=300)
end #plot_k_rev

"""
plot within subfigure
  plot_k_rev(range_k::Array,rev::Array{Dict,1},region::String)
  The array rev contains Dicts with:  
    key: name of feature
    features:
      name ( of method)
      rev
      color
      linestyle
      width
"""
function plot_k_rev_subplot(range_k::Array,methods::Array{Dict,1},descr::String, axis::Any; save::Bool=true,legend::Bool=false)
  fsize_ref = 16
  for m in methods
    # use if all start at 1, but some are not until 9
    axis["plot"](1:length(m["rev"]),m["rev"]/methods[1]["rev"][1],label=m["name"],color=m["color"],linestyle=m["linestyle"],lw=m["width"])
 #axis["plot"](range_k,m["rev"]/methods[1]["rev"][1],label=m["name"],color=m["color"],linestyle=m["linestyle"],lw=m["width"])
  end
 legend && axis["legend"](loc="lower right")
 axis["set_ylim"]([0.0,1.4])
 #=
  xlabel("Number of clusters",fontsize=fsize_ref)
  ylabel("Objective function value",fontsize=fsize_ref)
  legend(loc="lower right",fontsize=fsize_ref-4,ncol=2)
  ax = axes()
  ax[:tick_params]("both",labelsize=fsize_ref-1)
  xticks(range_k,range_k)
  tight_layout()
  ylim((0.0,1.05)) # 1.05
  save && savefig(descr,format="png",dpi=300)
  =#
end #plot_k_rev

function plot_SSE_rev(range_k::Array,cost_rev_clouds::Dict,cost_rev_points::Array{Dict,1},descr::String,rev_365::Float64;n_col::Int=2, save::Bool=true)
  figure()
  fsize_ref = 16
  for i=1:length(range_k)
    ii= length(range_k)-i+1
    if typeof(cost_rev_clouds["rev"]) == Array{Array{Float64,1},1} # exceptional case for kshape
      plot(cost_rev_clouds["cost"][ii],cost_rev_clouds["rev"][ii]/rev_365,".",label=string("k=",range_k[ii]),color=cols[i],alpha=0.2)
    else # normal case 
      plot(cost_rev_clouds["cost"][ii,:],cost_rev_clouds["rev"][ii,:]/rev_365,".",label=string("k=",range_k[ii]),color=cols[i],alpha=0.2)
    end
  end
  for i=1:length(cost_rev_points)
    for j=1:length(range_k)
      if j==1
        plot(cost_rev_points[i]["cost"][j,:],cost_rev_points[i]["rev"][j,:]/rev_365,mec=cost_rev_points[i]["mec"],marker=cost_rev_points[i]["marker"],mew=cost_rev_points[i]["mew"],markerfacecolor="none",linestyle="none",label=cost_rev_points[i]["label"])
      else 
        plot(cost_rev_points[i]["cost"][j,:],cost_rev_points[i]["rev"][j,:]/rev_365,mec=cost_rev_points[i]["mec"],marker=cost_rev_points[i]["marker"],mew=cost_rev_points[i]["mew"],markerfacecolor="none",linestyle="none",label=nothing)  # nothing instead of None # mew: markeredgewidth
      end # if
    end
  end
  plot(0.0,1.0,marker="*",ms=10,linestyle="none",color=StanfordDGreen,fillstyle="bottom",markeredgecolor="k",label="Full representation") # markerfacecoloralt=StanfordDGreen
  leg = legend(fontsize=fsize_ref-4,ncol=n_col)
  xlabel("Clustering measure (SSE)",fontsize=fsize_ref)
  ylabel("Objective value",fontsize=fsize_ref)
  ax = axes()
  ax[:tick_params]("both",labelsize=fsize_ref-1)
  tight_layout()
  xlim((7120,-120)) #9500
  ylim((0.5,1.05))
  save && savefig(descr,format="png",dpi=600) #; eps does not support transparency, pdf takes forever to load in inkscape, format="png",dpi=300
end # plot_SSE_rev
