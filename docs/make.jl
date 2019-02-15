using Documenter

using ClustForOpt

makedocs(sitename="ClustForOpt.jl",
    pages = [
        "index.md",
        "Clustering" => "clust.md",
        "Optimization" => ["opt_cep.md", "opt_cep_data.md"]
        ])
