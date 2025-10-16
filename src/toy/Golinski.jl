"""Golinski's speed reducer problem"""


"""
Construct Golinski's speed reducer problem
"""
function Golinski(solver; initial_multiplier::Float64 = 0.0, initial_weight::Float64 = 1e-3, silent::Bool = false)
    # create master variables dictionary
    initial_guess = Dict{Symbol, Real}()
    initial_guess[:x1] = 2.6168
    initial_guess[:x2] = 0.7440
    initial_guess[:x3] = 18.6323
    initial_guess[:x4] = 7.9214
    initial_guess[:x5] = 8.0544
    initial_guess[:x6] = 3.1806
    initial_guess[:x7] = 5.2636

    master_variables = Dict{Symbol, Real}()
    master_variables[:x1] = 2.6168
    master_variables[:x2] = 0.7440
    master_variables[:x3] = 18.6323

    variables_per_subproblem = [
        [:x1, :x2, :x3],
        [:x1, :x2, :x3, :x4, :x6],
        [:x1, :x2, :x3, :x5, :x7],
    ]

    # create subproblem 1 (gear problem)
    subproblem1 = JuMP.Model(solver, add_bridges = false)
    begin
        if silent == true
            set_silent(subproblem1)
        end
        # create master variables
        @variable(subproblem1, master_x1 in Parameter(master_variables[:x1]))
        @variable(subproblem1, master_x2 in Parameter(master_variables[:x2]))
        @variable(subproblem1, master_x3 in Parameter(master_variables[:x3]))

        # set local variables
        @variable(subproblem1, 2.6 <= x1 <= 3.6, start = initial_guess[:x1])
        @variable(subproblem1, 0.7 <= x2 <= 0.8, start = initial_guess[:x2])
        @variable(subproblem1, 17  <= x3 <= 28,  start = initial_guess[:x3])

        # create lagrange multiplier parameters
        @variable(subproblem1, λ_x1 in Parameter(initial_multiplier))
        @variable(subproblem1, λ_x2 in Parameter(initial_multiplier))
        @variable(subproblem1, λ_x3 in Parameter(initial_multiplier))

        # create penalty weight parameters
        @variable(subproblem1, w_x1 in Parameter(initial_weight))
        @variable(subproblem1, w_x2 in Parameter(initial_weight))
        @variable(subproblem1, w_x3 in Parameter(initial_weight))

        # objective & constraints
        penalty = augmented_lagrangian_penalty(
            subproblem1,
            [master_x1, master_x2, master_x3],
            [:x1, :x2, :x3],
        )
        F1 = 0.7854 * x1 * x2^2 * (3.3333 * x3^2 + 14.9335 * x3 - 43.0934)
        @objective(subproblem1, Min, F1 + penalty)

        @constraint(subproblem1, g_5, 27 / (x1 * x2^2 * x3) - 1 <= 0)
        @constraint(subproblem1, g_6, 397.5 / (x1 * x2^2 * x3^2) - 1 <= 0)
        @constraint(subproblem1, g_9, (x2 * x3) / 40 - 1 <= 0)
        @constraint(subproblem1, g_10, (5 * x2) / x1 - 1 <= 0)
        @constraint(subproblem1, g_11, x1 / (12 * x2) - 1 <= 0)
    end

    # create subproblem 2 (shaft problem 1)
    subproblem2 = JuMP.Model(solver, add_bridges = false)
    begin
        if silent == true
            set_silent(subproblem2)
        end
        # create master variables
        @variable(subproblem2, master_x1 in Parameter(master_variables[:x1]))
        @variable(subproblem2, master_x2 in Parameter(master_variables[:x2]))
        @variable(subproblem2, master_x3 in Parameter(master_variables[:x3]))

        # set local variables
        @variable(subproblem2, 2.6 <= x1 <= 3.6, start = initial_guess[:x1])
        @variable(subproblem2, 0.7 <= x2 <= 0.8, start = initial_guess[:x2])
        @variable(subproblem2, 17  <= x3 <= 28,  start = initial_guess[:x3])
        @variable(subproblem2, 7.3 <= x4 <= 8.3, start = initial_guess[:x4])
        @variable(subproblem2, 2.9 <= x6 <= 3.9, start = initial_guess[:x6])

        # create lagrange multiplier parameters
        @variable(subproblem2, λ_x1 in Parameter(initial_multiplier))
        @variable(subproblem2, λ_x2 in Parameter(initial_multiplier))
        @variable(subproblem2, λ_x3 in Parameter(initial_multiplier))

        # create penalty weight parameters
        @variable(subproblem2, w_x1 in Parameter(initial_weight))
        @variable(subproblem2, w_x2 in Parameter(initial_weight))
        @variable(subproblem2, w_x3 in Parameter(initial_weight))
        
        # objective & constraints
        penalty = augmented_lagrangian_penalty(
            [master_x1, master_x2, master_x3],
            [x1, x2, x3],
            [λ_x1, λ_x2, λ_x3],
            [w_x1, w_x2, w_x3],
        )
        F2 = -1.5079 * x1 * x6^2        # problematic
        F4 = 7.477 * x6^3
        F6 = 0.7854 * x4 * x6^2
        @objective(subproblem2, Min, F2 + F4 + F6 + penalty)
        
        @constraint(subproblem2, g_1, (1 / (110 * x6^3)) * sqrt((745 * x4 / (x2 * x3))^2 + 1.69e7) - 1 <= 0)
        @constraint(subproblem2, g_3, (1.5 * x6 + 1.9) / x4 - 1 <= 0)
        @constraint(subproblem2, g_7, (1.93 * x4^3) / (x2 * x3 * x6^4) - 1 <= 0)
    end

    # create subproblem 3 (shaft problem 2)
    subproblem3 = JuMP.Model(solver, add_bridges = false)
    begin
        if silent == true
            set_silent(subproblem3)
        end
        # create master variables
        @variable(subproblem3, master_x1 in Parameter(master_variables[:x1]))
        @variable(subproblem3, master_x2 in Parameter(master_variables[:x2]))
        @variable(subproblem3, master_x3 in Parameter(master_variables[:x3]))

        # set local variables
        @variable(subproblem3, 2.6 <= x1 <= 3.6, start = initial_guess[:x1])
        @variable(subproblem3, 0.7 <= x2 <= 0.8, start = initial_guess[:x2])
        @variable(subproblem3, 17  <= x3 <= 28,  start = initial_guess[:x3])
        @variable(subproblem3, 7.3 <= x5 <= 8.3, start = initial_guess[:x5])
        @variable(subproblem3, 5.0 <= x7 <= 5.5, start = initial_guess[:x7])

        # create lagrange multiplier parameters
        @variable(subproblem3, λ_x1 in Parameter(initial_multiplier))
        @variable(subproblem3, λ_x2 in Parameter(initial_multiplier))
        @variable(subproblem3, λ_x3 in Parameter(initial_multiplier))

        # create penalty weight parameters
        @variable(subproblem3, w_x1 in Parameter(initial_weight))
        @variable(subproblem3, w_x2 in Parameter(initial_weight))
        @variable(subproblem3, w_x3 in Parameter(initial_weight))

        # objective & constraints
        penalty = augmented_lagrangian_penalty(
            [master_x1, master_x2, master_x3],
            [x1, x2, x3],
            [λ_x1, λ_x2, λ_x3],
            [w_x1, w_x2, w_x3],
        )
        F3 = -1.5079 * x1 * x7^2;
        F5 = 7.477 * x7^3;
        F7 = 0.7854 * x5 * x7^2;
        @objective(subproblem3, Min, F3 + F5 + F7 + penalty)

        @constraint(subproblem3, g_2, (1 / (85 * x7^3)) * sqrt((745 * x5 / (x2 * x3))^2 + 1.575e8) - 1 <= 0)
        @constraint(subproblem3, g_4, (1.1 * x7 + 1.9) / x5 - 1 <= 0)
        @constraint(subproblem3, g_8, (1.93 * x5^3) / (x2 * x3 * x7^4) - 1 <= 0)
    end
    return master_variables, [subproblem1, subproblem2, subproblem3], variables_per_subproblem
end