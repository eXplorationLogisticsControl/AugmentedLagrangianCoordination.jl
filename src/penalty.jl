"""Penalty function for variables"""


"""Compute augmented Lagrangian penalty function for a subproblem
See: eqn (12) in Isaji et al, 2022.

# Arguments
- `variables_master::Vector`: vector of references to master variable parameters
- `variables_subproblem::Vector`: vector of references to subproblem variables
- `v::Vector`: vector of references to Lagrange multiplier estimate parameters
- `w::Vector`: vector of references to penalty weight parameters
"""
function augmented_lagrangian_penalty(
    variables_master::Vector,
    variables_subproblem::Vector,
    v::Vector,
    w::Vector,
)
    @assert length(variables_master) == length(variables_subproblem)
    residual = variables_master - variables_subproblem
    return v'residual + sum((w .* residual).^2)
end


"""Compute augmented Lagrangian penalty function for a subproblem
See: eqn (12) in Isaji et al, 2022.

# Arguments
- `variables_master::Vector`: vector of references to master variable parameters
- `variables_subproblem::Vector`: vector of references to subproblem variables
- `v::Vector`: vector of references to Lagrange multiplier estimate parameters
- `w::Vector`: vector of references to penalty weight parameters
"""
function augmented_lagrangian_penalty(
    subproblem::JuMP.Model,
    variables_master::Vector,
    var_symbols::Vector{Symbol},
)
    @assert length(variables_master) == length(var_symbols)
    variables_subproblem = [subproblem[var] for var in var_symbols]
    v = [subproblem[cat(:λ_, var_symbol)] for var_symbol in var_symbols]
    w = [subproblem[cat(:w_, var_symbol)] for var_symbol in var_symbols]
    residual = variables_master - variables_subproblem
    return v'residual + sum((w .* residual).^2)
end