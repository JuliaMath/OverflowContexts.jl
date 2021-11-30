import Base.Meta: isexpr

import CheckedArithmetic: replace_op!, @checked

"""
@default_checked

Redirect default integer math to overflow-checked operators. Only works at top-level.
"""
macro default_checked()
return quote
    Base.eval(:((Base.:-)(x::Base.BitInteger)                    = Base.Checked.checked_neg(x)))
    Base.eval(:((Base.:-)(x::T, y::T) where {T<:Base.BitInteger} = Base.Checked.checked_sub(x, y)))
    Base.eval(:((Base.:+)(x::T, y::T) where {T<:Base.BitInteger} = Base.Checked.checked_add(x, y)))
    Base.eval(:((Base.:*)(x::T, y::T) where {T<:Base.BitInteger} = Base.Checked.checked_mul(x, y)))
end
end

"""
@default_unchecked

Restore default integer math to overflow-permissive operations. Only works at top-level.
"""
macro default_unchecked()
return quote
    Base.eval(:((Base.:-)(x::Base.BitInteger)                    = Base.neg_int(x)))
    Base.eval(:((Base.:-)(x::T, y::T) where {T<:Base.BitInteger} = Base.sub_int(x, y)))
    Base.eval(:((Base.:+)(x::T, y::T) where {T<:Base.BitInteger} = Base.add_int(x, y)))
    Base.eval(:((Base.:*)(x::T, y::T) where {T<:Base.BitInteger} = Base.mul_int(x, y)))
end
end

"""
@unchecked expr

Perform all integer operations in `expr` using overflow-permissive arithmetic.
"""
macro unchecked(expr::Expr)
    isa(expr, Expr) || return expr
    expr = copy(expr)
    return esc(replace_op!(expr, op_unchecked))
end

const op_unchecked = Dict(
    Symbol("unary-") => :(Base.neg_int),
    :+ => :(unchecked_add),
    :- => :(unchecked_sub),
    :* => :(unchecked_mul),
)

# copied from CheckedArithmetic.jl and modified so that it doesn't traverse internal @checked/@unchecked blocks
function replace_op!(expr::Expr, op_map::Dict)
    if isexpr(expr, :call)
        f, len = expr.args[1], length(expr.args)
        op = isexpr(f, :.) ? f.args[2].value : f # handle module-scoped functions
        if op === :+ && len == 2                 # unary +
            # no action required
        elseif op === :- && len == 2             # unary -
            op = get(op_map, Symbol("unary-"), op)
            if isexpr(f, :.)
                f.args[2] = QuoteNode(op)
                expr.args[1] = f
            else
                expr.args[1] = op
            end
        else                                     # arbitrary call
            op = get(op_map, op, op)
            if isexpr(f, :.)
                f.args[2] = QuoteNode(op)
                expr.args[1] = f
            else
                expr.args[1] = op
            end
        end
        for a in Iterators.drop(expr.args, 1)
            if isa(a, Expr)
                replace_op!(a, op_map)
            end
        end
    elseif !isexpr(expr, :macrocall) || expr.args[1] ∉ (Symbol("@checked"), Symbol("@unchecked"))
        for a in expr.args
            if isa(a, Expr)
                replace_op!(a, op_map)
            end
        end
    end
    return expr
end
