import Base.Meta: isexpr

const op_method_symbols = (:+, :-, :*, :^, :abs)

"""
    @default_checked

Redirect default integer math to overflow-checked operators for the current module. Only works at top-level.
"""
macro default_checked()
    quote
        if !isdefined(@__MODULE__, :__OverflowContextDefaultSet)
            any(Base.isbindingresolved.(Ref(@__MODULE__), op_method_symbols)) &&
                error("A default context may only be set before any reference to the affected methods (+, -, *, ^, abs) in the target module.")
        else
            @warn "A previous default was set for this module. Previously defined methods in this module will be recompiled with this new default."
        end
        (@__MODULE__).eval(:(-(x) = checked_neg(x)))
        (@__MODULE__).eval(:(+(x...) = checked_add(x...)))
        (@__MODULE__).eval(:(-(x...) = checked_sub(x...)))
        (@__MODULE__).eval(:(*(x...) = checked_mul(x...)))
        (@__MODULE__).eval(:(^(x...) = checked_pow(x...)))
        (@__MODULE__).eval(:(abs(x) = checked_abs(x)))
        (@__MODULE__).eval(:(__OverflowContextDefaultSet = true))
        nothing
    end
end

"""
    @default_unchecked

Restore default integer math to overflow-permissive operators for the current module. Only works at top-level.
"""
macro default_unchecked()
    quote
        if !isdefined(@__MODULE__, :__OverflowContextDefaultSet)
            any(Base.isbindingresolved.(Ref(@__MODULE__), op_method_symbols)) &&
                error("A default context may only be set before any reference to the affected methods (+, -, *, ^, abs) in the target module.")
        else
            @warn "A previous default was set for this module. Previously defined methods in this module will be recompiled with this new default."
        end
        (@__MODULE__).eval(:(-(x) = unchecked_neg(x)))
        (@__MODULE__).eval(:(+(x...) = unchecked_add(x...)))
        (@__MODULE__).eval(:(-(x...) = unchecked_sub(x...)))
        (@__MODULE__).eval(:(*(x...) = unchecked_mul(x...)))
        (@__MODULE__).eval(:(^(x...) = unchecked_pow(x...)))
        (@__MODULE__).eval(:(abs(x) = unchecked_abs(x)))
        (@__MODULE__).eval(:(__OverflowContextDefaultSet = true))
        nothing
    end
end

"""
    @unchecked expr

Perform all integer operations in `expr` using overflow-permissive arithmetic.
"""
macro unchecked(expr)
    isa(expr, Expr) || return expr
    expr = copy(expr)
    return esc(replace_op!(expr, op_unchecked))
end

"""
    @checked expr

Perform all integer operations in `expr` using overflow-checked arithmetic.
"""
macro checked(expr)
    isa(expr, Expr) || return expr
    expr = copy(expr)
    return esc(replace_op!(expr, op_checked))
end

const op_checked = Dict(
    Symbol("unary-") => :(checked_neg),
    Symbol("ambig-") => :(checked_negsub),
    :+ => :(checked_add),
    :- => :(checked_sub),
    :* => :(checked_mul),
    :^ => :(checked_pow),
    :+= => :(checked_add),
    :-= => :(checked_sub),
    :*= => :(checked_mul),
    :^= => :(checked_pow),
    :abs => :(checked_abs),
)

const op_unchecked = Dict(
    Symbol("unary-") => :(unchecked_neg),
    Symbol("ambig-") => :(unchecked_negsub),
    :+ => :(unchecked_add),
    :- => :(unchecked_sub),
    :* => :(unchecked_mul),
    :^ => :(unchecked_pow),
    :+= => :(unchecked_add),
    :-= => :(unchecked_sub),
    :*= => :(unchecked_mul),
    :^= => :(unchecked_pow),
    :abs => :(unchecked_abs)
)

const broadcast_op_map = Dict(
    :.+ => :+,
    :.- => :-,
    :.* => :*,
    :.^ => :^
)

# resolve ambiguity when `-` used as symbol
unchecked_negsub(x) = unchecked_neg(x)
unchecked_negsub(x, y) = unchecked_sub(x, y)
checked_negsub(x) = checked_neg(x)
checked_negsub(x, y) = checked_sub(x, y)

# copied from CheckedArithmetic.jl and modified it
function replace_op!(expr::Expr, op_map::Dict)
    if isexpr(expr, :call)
        f, len = expr.args[1], length(expr.args)
        op = isexpr(f, :.) ? f.args[2].value : f  # handle module-scoped functions
        if op === :+ && len == 2                  # unary +
            # no action required
        elseif op === :- && len == 2              # unary -
            op = get(op_map, Symbol("unary-"), op)
            if isexpr(f, :.)
                f.args[2] = QuoteNode(op)
                expr.args[1] = f
            else
                expr.args[1] = op
            end
        elseif op ∈ (:.+, :.-, :.*, :.^) # broadcast operators
            op = get(broadcast_op_map, op, op)
            expr.head = :.
            expr.args = [
                get(op_map, op, op),
                Expr(:tuple, expr.args[2:end]...)]
        else                                      # arbitrary call
            op = get(op_map, op, op)
            if isexpr(f, :.)
                f.args[2] = QuoteNode(op)
                expr.args[1] = f
            else
                expr.args[1] = op
            end
        end
        for i in 2:length(expr.args)
            a = expr.args[i]
            if isa(a, Expr)
                replace_op!(a, op_map)
            elseif isa(a, Symbol)                  # operator as symbol function argument, e.g. `fold(+, ...)`
                op = if a == :-
                    get(op_map, Symbol("ambig-"), a)
                else
                    get(op_map, a, a)
                end
                expr.args[i] = op
            elseif isa(a, QuoteNode)
                op = get(op_map, a.value, a.value)
                expr.args[i] = op
            end
        end
    elseif isexpr(expr, (:+=, :-=, :*=, :^=))      # assignment operators
        target = expr.args[1]
        arg = expr.args[2]
        op = expr.head
        op = get(op_map, op, op)
        expr.head = :(=)
        expr.args[2] = Expr(:call, op, target, arg)
    elseif !isexpr(expr, :macrocall) || expr.args[1] ∉ (Symbol("@checked"), Symbol("@unchecked"))
        for a in expr.args
            if isa(a, Expr)
                replace_op!(a, op_map)
            end
        end
    end
    return expr
end
