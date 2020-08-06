module FunctionBarrier

using Base.Meta

export @barrier

struct Var
    name::Symbol
    num_esc::Int
end

function makelet(v::Var)
    ex = v.name
    for i=1:v.num_esc
        ex = esc(ex)
    end
    return ex
end

# Wrap `barrier_expression` in a `function` block to improve efficiency.
function wrap_barrier(module_, barrier_expression)
    ex = macroexpand(module_, barrier_expression)
    bound_vars, captured_vars = [Var(:end, 0), Var(:begin, 0)], Var[]
    find_var_uses!(captured_vars, bound_vars, ex, 0)
    fname = gensym()
    lastex = ex.args[end]
    args = map(makelet, captured_vars)
    if !(lastex isa Expr) || last isa Expr &&
        lastex.head == :tuple &&
        all(a -> a isa Symbol, lastex.args)
        retvar = lastex
    else
        retvar = gensym()
    end
    quote
        function $fname($(args...))
            $barrier_expression
        end
        $retvar = $fname($(args...))
    end
end

macro barrier(ex)
    esc(wrap_barrier(__module__, ex))
end

function find_var_uses!(varlist, bound_vars, ex, num_esc)
    if isa(ex, Symbol)
        var = Var(ex,num_esc)
        if !(var in bound_vars)
            var ∈ varlist || push!(varlist, var)
        end
        return varlist
    elseif isa(ex, Expr)
        if ex.head == :quote || ex.head == :line || ex.head == :inbounds
            return varlist
        end
        if ex.head == :(=)
            find_var_uses_lhs!(varlist, bound_vars, ex.args[1], num_esc)
            find_var_uses!(varlist, bound_vars, ex.args[2], num_esc)
        elseif ex.head == :kw
            find_var_uses!(varlist, bound_vars, ex.args[2], num_esc)
        elseif ex.head == :for || ex.head == :while || ex.head == :comprehension || ex.head == :let
            # New scopes
            inner_bindings = copy(bound_vars)
            find_var_uses!(varlist, inner_bindings, ex.args, num_esc)
        elseif ex.head == :try
            # New scope + ex.args[2] is a new binding
            find_var_uses!(varlist, copy(bound_vars), ex.args[1], num_esc)
            catch_bindings = copy(bound_vars)
            !isa(ex.args[2], Symbol) || push!(catch_bindings, Var(ex.args[2],num_esc))
            find_var_uses!(varlist,catch_bindings,ex.args[3], num_esc)
            if length(ex.args) > 3
                finally_bindings = copy(bound_vars)
                find_var_uses!(varlist,finally_bindings,ex.args[4], num_esc)
            end
        elseif ex.head == :call
            find_var_uses!(varlist, bound_vars, ex.args[2:end], num_esc)
        elseif ex.head == :local
            foreach(ex.args) do e
                if !isa(e, Symbol)
                    find_var_uses!(varlist, bound_vars, e, num_esc)
                end
            end
        elseif ex.head == :(::)
            find_var_uses_lhs!(varlist, bound_vars, ex, num_esc)
        elseif ex.head == :escape
            find_var_uses!(varlist, bound_vars, ex.args[1], num_esc+1)
        else
            find_var_uses!(varlist, bound_vars, ex.args, num_esc)
        end
    end
    varlist
end

find_var_uses!(varlist, bound_vars, exs::Vector, num_esc) =
    foreach(e->find_var_uses!(varlist, bound_vars, e, num_esc), exs)

function find_var_uses_lhs!(varlist, bound_vars, ex, num_esc)
    if isa(ex, Symbol)
        var = Var(ex,num_esc)
        var ∈ bound_vars || push!(bound_vars, var)
    elseif isa(ex, Expr)
        if ex.head == :tuple
            find_var_uses_lhs!(varlist, bound_vars, ex.args, num_esc)
        elseif ex.head == :(::)
            find_var_uses!(varlist, bound_vars, ex.args[2], num_esc)
            find_var_uses_lhs!(varlist, bound_vars, ex.args[1], num_esc)
        else
            find_var_uses!(varlist, bound_vars, ex.args, num_esc)
        end
    end
end

find_var_uses_lhs!(varlist, bound_vars, exs::Vector, num_esc) = foreach(e->find_var_uses_lhs!(varlist, bound_vars, e, num_esc), exs)

end
