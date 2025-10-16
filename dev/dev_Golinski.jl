"""Develop with test problem using Golinski's speed reducer problem"""

using JuMP
using Ipopt

include(joinpath(@__DIR__, "../src/AugmentedLagrangianCoordination.jl"))

# get problem
master_variables_values, subproblems, local_variable_symbols = AugmentedLagrangianCoordination.Golinski(Ipopt.Optimizer, silent = true);

# construct coordinated problem
CP = AugmentedLagrangianCoordination.CoordinatedProblems(subproblems, local_variable_symbols, master_variables_values)

# solve inner loop
ϵ_inner = 1e-5

#AugmentedLagrangianCoordination.solve_subproblems!(CP; verbosity = 0)
#@show CP.local_objectives

#set_parameter_value(CP.subproblems[1][:master_x1], 0.5)
# for key in keys(CP.master_variables_values)
#     CP.master_variables_values[key] *= 10
# end
# for k = 1:CP.M
#     AugmentedLagrangianCoordination.set_master_variables!(CP, k)
# end

# AugmentedLagrangianCoordination.solve_subproblems!(CP; verbosity = 0)
# @show CP.local_objectives

# try solving innnver loop
#AugmentedLagrangianCoordination.innerloop!(CP, ϵ_inner; maxiter = 2, verbosity = 2)
#@show CP.master_variables_values
3
# for key in keys(master_variables)
#     master_variables[key] *= 12
# end
# println("")
# AugmentedLagrangianCoordination.solve_subproblems!(CP, master_variables, verbosity = 1)

# try soplving outer loop
ϵ_outer = 1e-3
exitflag = AugmentedLagrangianCoordination.outerloop!(CP, 0.25, 3.0, ϵ_outer; maxiter_outer = 30, verbosity = 1)

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
    @assert(abs(solution_vars[key] - value) <= 1e-2, 
        "Solution for $key is not within tolerance $(abs(solution_vars[key] - value))")
end

# tabulate solution
t = AugmentedLagrangianCoordination.tabulate_variables(CP)