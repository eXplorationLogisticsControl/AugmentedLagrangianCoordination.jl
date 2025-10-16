"""Master problem struct"""


mutable struct CoordinatedProblems
    M::Int
    subproblems::Vector{JuMP.Model}
    master_variable_symbols::Vector{Symbol}
    master_variables_values::Dict{Symbol, Real}
    local_variable_symbols::Vector{Vector{Symbol}}
    local_variable_values::Vector{Dict{Symbol, Real}}
    local_objectives::Vector{Real}
    consistency_violations::Vector{Dict{Symbol, Real}}
    solved::Bool

    function CoordinatedProblems(
        subproblems::Vector{JuMP.Model},
        local_variable_symbols::Vector{Vector{Symbol}},
        master_variables_values::Dict{Symbol, Real},
    )
        @assert(length(subproblems) == length(local_variable_symbols))
        M = length(subproblems)

        # get master variable symbols
        stacked_variables = vcat(local_variable_symbols...)
        counts_per_variable = countmap(stacked_variables)
        master_variable_symbols = unique([s for s in stacked_variables if counts_per_variable[s] >= 2])
        #master_variable_symbols = keys(master_variables_values)

        # initialize storage
        local_objectives = Vector{Real}(undef, M)
        local_variable_values = Vector{Dict{Symbol, Real}}(undef, M)
        consistency_violations = Vector{Dict{Symbol, Real}}(undef, M)
        for k in 1:M
            local_variable_values[k] = Dict{Symbol, Real}()
            consistency_violations[k] = Dict{Symbol, Real}()
            for s in local_variable_symbols[k]
                if s in local_variable_symbols[k]
                    local_variable_values[k][s] = 0.0
                    consistency_violations[k][s] = 0.0
                end
            end
        end

        # create instance
        new(M, subproblems, master_variable_symbols, master_variables_values, 
            local_variable_symbols, local_variable_values, local_objectives, 
            consistency_violations,
            false)
    end
end


function get_x(CP::CoordinatedProblems)
    if CP.solved != true
        println("Warning: The problem is not solved.")
        return
    end
    solution_variables = Dict{Symbol, Real}()
    for k_variable_values in CP.local_variable_values
        for (key, value) in k_variable_values
            solution_variables[key] = value
        end
    end
    return solution_variables
end



"""
Overload method for showing
"""
function Base.show(io::IO, CP::CoordinatedProblems)
    println("Master problem with $(CP.M) subproblems")
    println("    Master variables: $(CP.master_variable_symbols)")
    for k = 1:CP.M
        @printf("    Subproblem %d has variables %s\n",
            k, CP.local_variable_symbols[k])
    end
end


"""
Tabulate variables
"""
function tabulate_variables(CP::CoordinatedProblems)
    all_variables_symbols = unique(vcat(CP.local_variable_symbols...))
    local_variable_values_filled = deepcopy(CP.local_variable_values)
    local_variables_tuples = []

    for k in 1:CP.M
        for s in all_variables_symbols
            if s in CP.local_variable_symbols[k]
                # @show s
                # @show CP.local_variable_values[k]
                # local_variable_values_filled[k][s] = CP.local_variable_values[k][s]
                continue
            else
                local_variable_values_filled[k][s] = NaN
            end
        end

        push!(local_variables_tuples, dict_to_sorted_tuple(local_variable_values_filled[k]))
    end
    # @show local_variables_tuples
    # @show keys(local_variable_values_filled)
    # local_variable_values_filled = Dict(k => local_variable_values_filled[k] for k in sort(collect(String.(keys(local_variable_values_filled)))))
    t = Table(local_variable_values_filled)
    return t
end