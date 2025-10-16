"""Outer loop functions"""

"""
Update consistency constraints c_k = y - y_k for a subproblem"""
function update_consistency!(CP::CoordinatedProblems, k::Int)
    for s in CP.master_variable_symbols
        if s in CP.local_variable_symbols[k]
            CP.consistency_violations[k][s] = CP.master_variables_values[s] - value(CP.subproblems[k][s])
        end
    end
end


"""
Set Lagrange multipliers into parameters in a subproblem according to eqn (17) in Isaji et al, 2022.
"""
function set_lagrange_multipliers!(CP::CoordinatedProblems, k::Int)
    for s in CP.master_variable_symbols
        if s in CP.local_variable_symbols[k]
            λ = parameter_value(CP.subproblems[k][cat(:λ_, s)])
            w = parameter_value(CP.subproblems[k][cat(:w_, s)])
            λ_new = λ + 2 * w^2 * (CP.master_variables_values[s] - value(CP.subproblems[k][s]))
            set_parameter_value(CP.subproblems[k][cat(:λ_, s)], λ_new)
        end
    end
end


"""
Set weights into parameters in a subproblem according to eqn (18) in Isaji et al, 2022.
"""
function set_weights!(CP::CoordinatedProblems, k::Int, prev_consistency_violations::Dict{Symbol, Real}, γ, β)
    for s in CP.master_variable_symbols
        if s in CP.local_variable_symbols[k]
            if abs(CP.consistency_violations[k][s]) <= γ * abs(prev_consistency_violations[s])
                # we keep the same weight
                continue
            else
                # we update weight by multiplying with β
                w = parameter_value(CP.subproblems[k][cat(:w_, s)])
                set_parameter_value(CP.subproblems[k][cat(:w_, s)], w * β)
            end
        end
    end
end


"""
Iterate inner loop, solving subproblems and the master problem

Note: 
- γ smaller value means more frequent increase of penalty weight
- β higher value means faster increase of penalty weight

# Arguments
- `CP::CoordinatedProblems`: Coordinated problem struct
- `γ::Real`: fraction of consistency violation to determine if penalty weight should be increased or not
- `β::Real`: factor to increase penalty weight
- `ϵ_outer::Float64`: convergence tolerance for outer loop
- `ϵ_inner::Float64`: convergence tolerance for inner loop
- `maxiter_outer::Int`: maximum number of iterations for outer loop
- `maxiter_inner::Int`: maximum number of iterations for inner loop
- `verbosity::Int`: verbosity level

# Returns
- `exitflag::Int`: exit condition of outer-loop (1: converged, 0: ran out of iterations, -1: inner loop did not converge)
"""
function outerloop!(
    CP::CoordinatedProblems,
    γ::Real = 0.25,
    β::Real = 1.5,
    ϵ_outer::Float64 = 1e-3,
    ϵ_inner::Float64 = 1e-5;
    maxiter_outer::Int=10, maxiter_inner::Int=10, verbosity::Int = 0
)
    # exit flag initialization
    exitflag = 0

    # storage
    prev_consistency_violations = Vector{Dict{Symbol, Real}}(undef, CP.M)
    c_max_symbol, c_max, c_max_k = :unassigned, 0.0, 0
    prev_c_max_symbol, prev_c_max, prev_c_max_k = :unassigned, 0.0, 0

    for it_outer = 1:maxiter_outer
        # store consistency violations from previous iteration
        for k = 1:CP.M
            prev_consistency_violations[k] = CP.consistency_violations[k]
        end

        # solve inner loop
        exitflag_inner = innerloop!(CP, ϵ_inner; maxiter = maxiter_inner, verbosity = verbosity)
        if exitflag_inner != 1
            @printf("    Inner loop did not converge at iteration %d\n", it_outer)
            exitflag = -1
            break
        end

        # query consistency violations
        for k = 1:CP.M
            update_consistency!(CP, k)
        end

        # update Lagrange multipliers and weights
        for k = 1:CP.M
            # query current λ's`and w's for the k-th subproblem
            λs_current = Dict{Symbol, Real}()
            ws_current = Dict{Symbol, Real}()
            for s in CP.master_variable_symbols
                if s in CP.local_variable_symbols[k]
                    λs_current[s] = parameter_value(CP.subproblems[k][cat(:λ_, s)])
                    ws_current[s] = parameter_value(CP.subproblems[k][cat(:w_, s)])
                end
            end

            # update λ's and w's for the k-th subproblem
            for s in CP.master_variable_symbols
                if s in CP.local_variable_symbols[k]
                    λ_new = λs_current[s] + 2 * ws_current[s]^2 * CP.consistency_violations[k][s]
                    set_parameter_value(CP.subproblems[k][cat(:λ_, s)], λ_new)
                    
                    if abs(CP.consistency_violations[k][s]) <= γ * abs(prev_consistency_violations[k][s])
                        # we keep the same weight
                        continue
                    else
                        # we update weight by multiplying with β
                        w_new = ws_current[s] * β
                        set_parameter_value(CP.subproblems[k][cat(:w_, s)], w_new)
                    end
                end
            end
        end

        # check violation of consistency constraints
        c_max_symbol, c_max, c_max_k = :unassigned, 0.0, 0      # reset
        for k = 1:CP.M
            _c, _s = findmax(abs(val) for (key, val) in CP.consistency_violations[k])
            if _c > c_max
                c_max_symbol, c_max, c_max_k = _s, _c, k
            end
        end

        if verbosity > 0
            @printf("  Outer loop iteration %d : c_max = %1.4e (subproblem %d variable %s)\n", 
                it_outer, c_max, c_max_k, c_max_symbol)
        end

        # check convergence
        if it_outer > 1
            if (abs(c_max)/(1 + CP.local_variable_values[c_max_k][c_max_symbol]) <= ϵ_outer) &&
               (abs(c_max - prev_c_max)/(1 + CP.local_variable_values[c_max_k][c_max_symbol]) <= ϵ_outer)
                if verbosity > 0
                    @printf("  Converged at iteration %d\n", it_outer)
                end
                CP.solved = true
                exitflag = 1
                break
            end
        end

        # update consistency violations
        prev_c_max_symbol, prev_c_max, prev_c_max_k = c_max_symbol, c_max, c_max_k
    end
    return exitflag
end