"""Miscellaneous functions"""


function cat(a::Symbol, b::Symbol)
    return Symbol(string(a), string(b))
end


function dict_to_sorted_tuple(A::Dict)
    keys_sorted = Symbol.(sort(string.(collect(keys(A)))))
    sorted_pairs = []
    for key in keys_sorted
        push!(sorted_pairs, key => A[key])
    end
    return tuple(sorted_pairs...)
end