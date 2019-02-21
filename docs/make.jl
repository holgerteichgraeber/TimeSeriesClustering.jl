using Documenter
using Plots
using ClustForOpt

makedocs(sitename="ClustForOpt.jl",
    authors = "Holger Teichgraeber, and Elias Kuepper",
    pages = [
        "Introduction" => "index.md",
        "Workflow" => "workflow.md",
        "Load Data" => "load_data.md",
        "Clustering" => "clust.md",
        "Optimization" => ["opt.md", "opt_cep.md", "opt_cep_data.md"]
        ],
    assets = [
        "assets/clust_for_opt_text.svg",
        "assets/opt_cep.svg",
        "assets/workflow.svg"])

deploydocs(repo = "github.com/holgerteichgraeber/ClustForOpt.jl.git")
