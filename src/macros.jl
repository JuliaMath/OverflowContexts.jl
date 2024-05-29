using Base.Meta: isexpr

const op_method_symbols = (:+, :-, :*, :^, :abs, :÷, :div, :cld, :fld, :%, :rem, :mod)

const op_checked = Dict(
    Symbol("unary-") => :(OverflowContexts.checked_neg),
    Symbol("ambig-") => :(OverflowContexts.checked_negsub),
    :+ => :(OverflowContexts.checked_add),
    :- => :(OverflowContexts.checked_sub),
    :* => :(OverflowContexts.checked_mul),
    :^ => :(OverflowContexts.checked_pow),
    :abs => :(OverflowContexts.checked_abs),
    :÷ => :(OverflowContexts.checked_div),
    :div => :(OverflowContexts.checked_div),
    :fld => :(OverflowContexts.checked_fld),
    :cld => :(OverflowContexts.checked_cld),
    :% => :(OverflowContexts.checked_rem),
    :rem => :(OverflowContexts.checked_rem),
    :mod => :(OverflowContexts.checked_mod)
)

const op_unchecked = Dict(
    Symbol("unary-") => :(OverflowContexts.unchecked_neg),
    Symbol("ambig-") => :(OverflowContexts.unchecked_negsub),
    :+ => :(OverflowContexts.unchecked_add),
    :- => :(OverflowContexts.unchecked_sub),
    :* => :(OverflowContexts.unchecked_mul),
    :^ => :(OverflowContexts.unchecked_pow),
    :abs => :(OverflowContexts.unchecked_abs),
    :÷ => :(OverflowContexts.unchecked_div),
    :div => :(OverflowContexts.unchecked_div),
    :fld => :(OverflowContexts.unchecked_fld),
    :cld => :(OverflowContexts.unchecked_cld),
    :% => :(OverflowContexts.unchecked_rem),
    :rem => :(OverflowContexts.unchecked_rem),
    :mod => :(OverflowContexts.unchecked_mod)
)

const op_saturating = Dict(
    Symbol("unary-") => :(OverflowContexts.saturating_neg),
    Symbol("ambig-") => :(OverflowContexts.saturating_negsub),
    :+ => :(OverflowContexts.saturating_add),
    :- => :(OverflowContexts.saturating_sub),
    :* => :(OverflowContexts.saturating_mul),
    :^ => :(OverflowContexts.saturating_pow),
    :abs => :(OverflowContexts.saturating_abs),
    :÷ => :(OverflowContexts.saturating_div),
    :div => :(OverflowContexts.saturating_div),
    :fld => :(OverflowContexts.saturating_fld),
    :cld => :(OverflowContexts.saturating_cld),
    :% => :(OverflowContexts.saturating_rem),
    :rem => :(OverflowContexts.saturating_rem),
    :mod => :(OverflowContexts.saturating_mod)
)

const broadcast_op_map = Dict(
    :.+ => :+,
    :.- => :-,
    :.* => :*,
    :.^ => :^,
    :.÷ => :÷,
    :.% => :%
)

const assignment_op_map = Dict(
    :+= => :+,
    :-= => :-,
    :*= => :*,
    :^= => :^,
    :÷= => :÷,
    :%= => :%,
    :.+= => :.+,
    :.-= => :.-,
    :.*= => :.*,
    :.^= => :.^,
    :.÷= => :.÷,
    :.%= => :.%
)

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
        (@__MODULE__).eval(:(-(x) = OverflowContexts.checked_neg(x)))
        (@__MODULE__).eval(:(+(x...) = OverflowContexts.checked_add(x...)))
        (@__MODULE__).eval(:(-(x...) = OverflowContexts.checked_sub(x...)))
        (@__MODULE__).eval(:(*(x...) = OverflowContexts.checked_mul(x...)))
        (@__MODULE__).eval(:(^(x...) = OverflowContexts.checked_pow(x...)))
        (@__MODULE__).eval(:(abs(x) = OverflowContexts.checked_abs(x)))
        (@__MODULE__).eval(:(÷(x...) = OverflowContexts.checked_div(x...)))
        (@__MODULE__).eval(:(div(x) = OverflowContexts.checked_div(x)))
        (@__MODULE__).eval(:(fld(x) = OverflowContexts.checked_fld(x)))
        (@__MODULE__).eval(:(cld(x) = OverflowContexts.checked_cld(x)))
        (@__MODULE__).eval(:(%(x...) = OverflowContexts.checked_mod(x...)))
        (@__MODULE__).eval(:(rem(x) = OverflowContexts.checked_rem(x)))
        (@__MODULE__).eval(:(mod(x) = OverflowContexts.checked_mod(x)))
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
        (@__MODULE__).eval(:(-(x) = OverflowContexts.unchecked_neg(x)))
        (@__MODULE__).eval(:(+(x...) = OverflowContexts.unchecked_add(x...)))
        (@__MODULE__).eval(:(-(x...) = OverflowContexts.unchecked_sub(x...)))
        (@__MODULE__).eval(:(*(x...) = OverflowContexts.unchecked_mul(x...)))
        (@__MODULE__).eval(:(^(x...) = OverflowContexts.unchecked_pow(x...)))
        (@__MODULE__).eval(:(abs(x) = OverflowContexts.unchecked_abs(x)))
        (@__MODULE__).eval(:(÷(x...) = OverflowContexts.unchecked_div(x...)))
        (@__MODULE__).eval(:(div(x) = OverflowContexts.unchecked_div(x)))
        (@__MODULE__).eval(:(fld(x) = OverflowContexts.unchecked_fld(x)))
        (@__MODULE__).eval(:(cld(x) = OverflowContexts.unchecked_cld(x)))
        (@__MODULE__).eval(:(%(x...) = OverflowContexts.unchecked_mod(x...)))
        (@__MODULE__).eval(:(rem(x) = OverflowContexts.unchecked_rem(x)))
        (@__MODULE__).eval(:(mod(x) = OverflowContexts.unchecked_mod(x)))
        (@__MODULE__).eval(:(__OverflowContextDefaultSet = true))
        nothing
    end
end

"""
    @default_saturating

Redirect default integer math to saturating operators for the current module. Only works at top-level.
"""
macro default_saturating()
    quote
        if !isdefined(@__MODULE__, :__OverflowContextDefaultSet)
            any(Base.isbindingresolved.(Ref(@__MODULE__), op_method_symbols)) &&
                error("A default context may only be set before any reference to the affected methods (+, -, *, ^, abs) in the target module.")
        else
            @warn "A previous default was set for this module. Previously defined methods in this module will be recompiled with this new default."
        end
        (@__MODULE__).eval(:(-(x) = OverflowContexts.saturating_neg(x)))
        (@__MODULE__).eval(:(+(x...) = OverflowContexts.saturating_add(x...)))
        (@__MODULE__).eval(:(-(x...) = OverflowContexts.saturating_sub(x...)))
        (@__MODULE__).eval(:(*(x...) = OverflowContexts.saturating_mul(x...)))
        (@__MODULE__).eval(:(^(x...) = OverflowContexts.saturating_pow(x...)))
        (@__MODULE__).eval(:(abs(x) = OverflowContexts.saturating_abs(x)))
        (@__MODULE__).eval(:(÷(x...) = OverflowContexts.saturating_div(x...)))
        (@__MODULE__).eval(:(div(x) = OverflowContexts.saturating_div(x)))
        (@__MODULE__).eval(:(fld(x) = OverflowContexts.saturating_fld(x)))
        (@__MODULE__).eval(:(cld(x) = OverflowContexts.saturating_cld(x)))
        (@__MODULE__).eval(:(%(x...) = OverflowContexts.saturating_mod(x...)))
        (@__MODULE__).eval(:(rem(x) = OverflowContexts.saturating_rem(x)))
        (@__MODULE__).eval(:(mod(x) = OverflowContexts.saturating_mod(x)))
        (@__MODULE__).eval(:(__OverflowContextDefaultSet = true))
        nothing
    end
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
    @saturating expr

Perform all integer operations in `expr` using saturating arithmetic.
"""
macro saturating(expr)
    isa(expr, Expr) || return expr
    expr = copy(expr)
    return esc(replace_op!(expr, op_saturating))
end

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
        elseif op ∈ keys(broadcast_op_map)        # broadcast operators
            op = get(broadcast_op_map, op, op)
            if length(expr.args) == 2 # unary operator
                if op == :-
                    expr.head = :.
                    expr.args = [
                        get(op_map, Symbol("unary-"), op),
                        Expr(:tuple, expr.args[2])]
                end
                # no action required for .+
            else
                expr.head = :.
                expr.args = [
                    get(op_map, op, op),
                    Expr(:tuple, expr.args[2:end]...)]
            end
        else                                      # arbitrary call
            op_orig = op
            op = get(op_map, op, op)
            if isexpr(f, :.)
                f.args[2] = QuoteNode(op)
                expr.args[1] = f
            else
                expr.args[1] = op
                if op_orig == :^ && expr.args[3] isa Integer
                    # literal_pow transformation
                    pushfirst!(expr.args, :(Base.literal_pow))
                    expr.args[4] = :(Val($(expr.args[4])))
                end
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
    elseif isexpr(expr, keys(assignment_op_map))   # assignment operators
        target = expr.args[1]
        arg = expr.args[2]
        op = expr.head
        op = get(assignment_op_map, op, op)
        expr.head = startswith(string(op), ".") ? :.= : :(=) # is there a better test?
        expr.args[2] = replace_op!(Expr(:call, op, target, arg), op_map)
    elseif isexpr(expr, :.) # broadcast function
        op = expr.args[1]
        expr.args[1] = get(op_map, op, op)
    elseif !isexpr(expr, :macrocall) || expr.args[1] ∉ (Symbol("@checked"), Symbol("@unchecked"), Symbol("@saturating"))
        for a in expr.args
            if isa(a, Expr)
                replace_op!(a, op_map)
            end
        end
    end
    return expr
end

if VERSION < v"1.6"
    import Base.Meta: isexpr
    isexpr(expr, heads) = isexpr(expr, collect(heads))
end
