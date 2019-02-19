using Documenter
using Plots
using ClustForOpt

makedocs(sitename="ClustForOpt.jl",
    pages = [
        "index.md",
        "Workflow" => "workflow.md",
        "Load Data" => "load_data.md",
        "Clustering" => "clust.md",
        "Optimization" => ["opt.md", "opt_cep.md", "opt_cep_data.md"]
        ])

deploydocs(repo = "github.com/holgerteichgraeber/ClustForOpt.jl.git", devbranch = "documentation",)
