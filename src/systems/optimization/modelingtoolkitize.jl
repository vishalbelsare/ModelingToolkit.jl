"""
$(TYPEDSIGNATURES)

Generate `OptimizationSystem`, dependent variables, and parameters from an `OptimizationProblem`.
"""
function modelingtoolkitize(prob::DiffEqBase.OptimizationProblem; num_cons = 0, kwargs...)
    if prob.p isa Tuple || prob.p isa NamedTuple
        p = [x for x in prob.p]
    else
        p = prob.p
    end

    vars = reshape([variable(:x, i) for i in eachindex(prob.u0)], size(prob.u0))
    params = p isa DiffEqBase.NullParameters ? [] :
             reshape([variable(:α, i) for i in eachindex(p)], size(Array(p)))

    eqs = prob.f(vars, params)

    if DiffEqBase.isinplace(prob) && !isnothing(prob.f.cons)
        lhs = Array{Num}(undef, num_cons)
        prob.f.cons(lhs, vars, params)

        if !isnothing(prob.lcons) && !isnothing(prob.ucons)
            cons = prob.lcons .≲ lhs .≲ prob.ucons
        else
            cons = lhs .~ 0.0
        end
    elseif !isnothing(prob.f.cons)
        cons = prob.f.cons(vars, params)
    else
        cons = []
    end

    de = OptimizationSystem(eqs, vec(vars), vec(params);
                            name = gensym(:MTKizedOpt),
                            constraints = cons,
                            kwargs...)
    de
end
