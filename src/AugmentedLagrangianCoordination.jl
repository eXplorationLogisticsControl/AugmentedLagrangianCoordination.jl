module AugmentedLagrangianCoordination

    using JuMP
    using LinearAlgebra
    using Printf: @printf
    using StatsBase
    using TypedTables

    include("misc.jl")
    include("penalty.jl")
    include("problem.jl")
    include("innerloop.jl")
    include("outerloop.jl")

    include("toy/Golinski.jl")

end # module AugmentedLagrangianCoordination
