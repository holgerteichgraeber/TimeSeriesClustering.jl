using Test
using ClustForOpt
using Clp

tests = ["cep"]

println("Runing tests:")
for t in tests
    fp = "$(t).jl"
    println("* $fp ...")
    include(fp)
end
