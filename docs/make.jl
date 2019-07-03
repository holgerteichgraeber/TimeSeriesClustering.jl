using Documenter
using Plots
using ClustForOpt

makedocs(sitename="ClustForOpt.jl",
    authors = "Holger Teichgraeber, and Elias Kuepper",
    pages = [
        "Introduction" => "index.md",
        "Quick Start Guide" => "quickstart.md",
        "Load Data" => "load_data.md",
        "Representative Periods" => "repr_per.md",
        "Optimization" => "opt.md"
        ],
    format = Documenter.HTML(assets=["assets/clust_for_opt_text.svg"])
    )

deploydocs(repo = "github.com/holgerteichgraeber/ClustForOpt.jl.git", devbranch="dev")
