"""Run tests"""

using JuMP
using Ipopt
using Test

include(joinpath(@__DIR__, "../src/AugmentedLagrangianCoordination.jl"))


@testset "Golinski" begin
    # get problem
    subproblems, local_variable_symbols, master_variables_values = AugmentedLagrangianCoordination.Golinski(Ipopt.Optimizer, silent = true);

    # make sure subproblems are solveable
    for k = 1:3
        optimize!(subproblems[k])
        @test is_solved_and_feasible(subproblems[k]) == true
    end
    
    # construct coordinated problem
    CP = AugmentedLagrangianCoordination.CoordinatedProblems(subproblems, local_variable_symbols, master_variables_values)

    # test for inner loop
    ϵ_inner = 1e-5
    exitflag_inner = AugmentedLagrangianCoordination.innerloop!(CP, ϵ_inner; maxiter = 2, verbosity = 0)
    @test exitflag_inner == 1

    # test for outer loop
    ϵ_outer = 1e-3
    exitflag = AugmentedLagrangianCoordination.outerloop!(CP, 0.25, 3.0, ϵ_outer; maxiter_outer = 30, verbosity = 1)
    @test exitflag == 1

    # check solution
    known_solution = Dict(
        :x1 => 3.50,
        :x2 => 0.70,
        :x3 => 17.00,
        :x4 => 7.30,
        :x5 => 7.72,
        :x6 => 3.35,
        :x7 => 5.29    
    )
    solution_vars = AugmentedLagrangianCoordination.get_x(CP)
    for (key, value) in known_solution
        @test abs(solution_vars[key] - value) <= 1e-2
    end
end
