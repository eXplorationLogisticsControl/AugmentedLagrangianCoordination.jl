"""Inner loop functions"""


"""
Set values of master variables into parameters in a subproblem
"""
function set_master_variables!(
    CP::CoordinatedProblems,
    k::Int,
)
    for s in CP.master_variable_symbols
        if s in CP.local_variable_symbols[k]
            set_parameter_value(CP.subproblems[k][cat(:master_, s)], CP.master_variables_values[s])
        end
    end
end


"""
Query variable values of a subproblem
"""
function store_local_variables_values(CP::CoordinatedProblems, k::Int)
    for s in CP.local_variable_symbols[k]
        CP.local_variable_values[k][s] = value(CP.subproblems[k][s])
    end
end


"""
Set initial variable values of a subproblem
"""
function set_local_variable_values(CP::CoordinatedProblems, k::Int)
    for s in CP.local_variable_symbols[k]# (s, value) in zip(var_symbols, var_values)
        set_start_value(CP.subproblems[k][s], CP.local_variable_values[k][s])
    end
end


"""
Solve each subproblem within coordinated problems
"""
function solve_subproblems!(
    CP::CoordinatedProblems;
    use_previous_values::Bool = false,
    verbosity::Int = 0
)
    # # for each subproblem, update master variables and solve
    for (k, (subproblem, var_symbols)) in enumerate(zip(CP.subproblems, CP.local_variable_symbols))
        if use_previous_values
            set_local_variable_values(CP, k)
        end

        # solve subproblem
        optimize!(subproblem)
        store_local_variables_values(CP, k)
        CP.local_objectives[k] = MOI.get(subproblem, MOI.ObjectiveValue())
        if verbosity > 3
            @printf("     Subproblem %d objective = %1.8e (solved & feasible: %s)\n",
                k,
                CP.local_objectives[k],
                string(is_solved_and_feasible(subproblem)))
        end
    end
end


"""
Solve master problem analytically via eqn (19) in Isaji et al, 2022
"""
function solve_masterproblem!(CP::CoordinatedProblems; verbosity::Int = 0)
    master_variables_values_new = Dict{Symbol, Real}()
    for key in keys(CP.master_variables_values)
        master_variables_values_new[key] = 0.0
    end

    # iterate through each shared variable
    for s in keys(CP.master_variables_values)
        divisor = 0.0
        for (subproblem,var_symbols) in zip(CP.subproblems, CP.local_variable_symbols)
            if s in var_symbols
                vk = value(subproblem[cat(:λ_, s)])
                wk = value(subproblem[cat(:w_, s)])
                yk = value(subproblem[s])
                divisor += wk^2
                master_variables_values_new[s] += (wk^2 * yk - 0.5*vk)
            end
        end
        CP.master_variables_values[s] = master_variables_values_new[s] / divisor
    end
end


"""
Iterate inner loop, solving subproblems and the master problem
"""
function innerloop!(CP::CoordinatedProblems, ϵ_inner::Float64; maxiter::Int=20, verbosity::Int = 0)
    F_previous = 0.0       # initialize storage of objective sum for convergence check
    exitflag = 0           # initialize exit flag

    # iterate inner loop
    for it = 1:maxiter
        # solve master problem and update master variables
        if it > 1
            solve_masterproblem!(CP, verbosity = verbosity)
            for k in 1:CP.M
                #(k, (subproblem, var_symbols)) in enumerate(zip(CP.subproblems, CP.local_variable_symbols))
                set_master_variables!(CP, k) #subproblem, CP.master_variable_symbols)
            end
        end

        # solve subproblems
        if it == 1
            use_previous_values = false
        else
            use_previous_values = true
        end
        solve_subproblems!(CP; use_previous_values = use_previous_values, verbosity = verbosity)
        F_current = sum(CP.local_objectives)
        ϵ = abs(F_current - F_previous) / (1 + abs(F_current))

        if verbosity > 2
            @printf("    Inner loop iteration %d: F = %1.8e, ϵ = %1.4e\n", it, F_current, ϵ)
        end
        
        # check convergence of inner loop
        if it > 1
            if ϵ <= ϵ_inner
                exitflag = 1
                if verbosity > 1
                    @printf("    Inner loop converged at iteration %d\n", it)
                end
                break
            end
        end
        F_previous = sum(CP.local_objectives)

        if it == maxiter
            # reached maximum iteration
            exitflag = -1
        end
    end
    return exitflag
end