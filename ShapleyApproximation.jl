module ShapleyApproximation
    using Random, Distributions, Combinatorics, JLD2
    
    include("./instance_generation.jl")
    include("./shapley_algorithms.jl")

end # module