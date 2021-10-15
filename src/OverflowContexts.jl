module OverflowContexts
__precompile__(false)

import Base: hash_64_64, hash_64_32, hash_32_32, hash_uint, hash_uint64, hash, memhash, memhash_seed,
    indexed_iterate, add_int, sub_int, neg_int, mul_int, max_values, bitcast
import Base.Checked: SignedInt, UnsignedInt, BrokenSignedInt, BrokenUnsignedInt, BrokenSignedIntMul, BrokenUnsignedIntMul,
    checked_abs, add_with_overflow, checked_neg, checked_add, sub_with_overflow, throw_overflowerr_negation, mul_with_overflow

import CheckedArithmetic: replace_op!

export @checked, @unchecked

"""
    @checked

Redirect all integer math to overflow-checked operators. Only works at top-level.
"""
macro checked()
    return quote
        Base.eval(:((Base.:-)(x::Base.BitInteger)                    = Base.Checked.checked_neg(x)))
        Base.eval(:((Base.:-)(x::T, y::T) where {T<:Base.BitInteger} = Base.Checked.checked_sub(x, y)))
        Base.eval(:((Base.:+)(x::T, y::T) where {T<:Base.BitInteger} = Base.Checked.checked_add(x, y)))
        Base.eval(:((Base.:*)(x::T, y::T) where {T<:Base.BitInteger} = Base.Checked.checked_mul(x, y)))
    end
end



"""
    @unchecked

Restore all integer math to overflow-permissive operations. Only works at top-level.
"""
macro unchecked()
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
    :+ => (Base.add_int),
    :- => (Base.sub_int),
    :* => (Base.mul_int)
)


# fix base methods that require overflow/underflow
hash(@nospecialize(x), h::UInt) = hash_uint(sub_int(mul_int(UInt(3), h), objectid(x)))

function hash_64_64(n::UInt64)
    a::UInt64 = n
    a = add_int(~a, a << 21)
    a =  a ⊻ a >> 24
    a =  add_int(add_int(a, a << 3), a << 8)
    a =  a ⊻ a >> 14
    a =  add_int(add_int(a, a << 2), a << 4)
    a =  a ⊻ a >> 28
    a =  add_int(a, a << 31)
    return a
end

function hash_64_32(n::UInt64)
    a::UInt64 = n
    a = add_int(~a, a << 18)
    a =  a ⊻ a >> 31
    a =  a * 21
    a =  a ⊻ a >> 11
    a =  add_int(a, a << 6)
    a =  a ⊻ a >> 22
    return a % UInt32
end

function hash_32_32(n::UInt32)
    a::UInt32 = n
    a = add_int(add_int(a, 0x7ed55d16), a << 12)
    a = a ⊻ 0xc761c23c ⊻ a >> 19
    a = add_int(add_int(a, 0x165667b1), a << 5)
    a = add_int(a, 0xd3a2646c) ⊻ a << 9
    a = add_int(add_int(a, 0xfd7046c5), a << 3)
    a = a ⊻ 0xb55a4f09 ⊻ a >> 16
    return a
end

hash(x::Int64,  h::UInt) = sub_int(hash_uint64(bitcast(UInt64, x)), mul_int(UInt(3), h))
hash(x::UInt64, h::UInt) = sub_int(hash_uint64(x), mul_int(UInt(3), h))

if UInt === UInt64
    hash(x::Expr, h::UInt) = hash(x.args, hash(x.head, add_int(h, 0x83c7900696d26dc6)))
    hash(x::QuoteNode, h::UInt) = hash(x.value, add_int(h, 0x2c97bf8b3de87020))
else
    hash(x::Expr, h::UInt) = hash(x.args, hash(x.head, add_int(h, 0x96d26dc6)))
    hash(x::QuoteNode, h::UInt) = hash(x.value, add_int(h, 0x469d72af))
end

function hash(s::String, h::UInt)
    h += memhash_seed
    add_int(ccall(memhash, UInt, (Ptr{UInt8}, Csize_t, UInt32), s, sizeof(s), h % UInt32), h)
end



@inline indexed_iterate(t::Tuple, i::Int, state=1) = (getfield(t, i), add_int(i, 1))
@inline indexed_iterate(a::Array, i::Int, state=1) = (a[i], add_int(i, 1))



function max_values(T::Union)
    a = max_values(T.a)::Int
    b = max_values(T.b)::Int
    return max(a, b, add_int(a, b))
end




# Base.Checked
if BrokenSignedInt != Union{}
function checked_neg(x::BrokenSignedInt)
    r = neg_int(x)
    (x<0) & (r<0) && throw_overflowerr_negation(x)
    r
end
end

@inline function checked_abs(x::SignedInt)
    r = ifelse(x<0, neg_int(x), x)
    r<0 && throw(OverflowError(string("checked arithmetic: cannot compute |x| for x = ", x, "::", typeof(x))))
    r
 end

add_with_overflow(x::Bool, y::Bool) = (add_int(x, y), false)

if BrokenSignedInt != Union{}
function add_with_overflow(x::T, y::T) where T<:BrokenSignedInt
    r = add_int(x, y)
    # x and y have the same sign, and the result has a different sign
    f = (x<0) == (y<0) != (r<0)
    r, f
end
end
if BrokenUnsignedInt != Union{}
function add_with_overflow(x::T, y::T) where T<:BrokenUnsignedInt
    # x + y > typemax(T)
    # Note: ~y == -y-1
    add_int(x, y), x > ~y
end
end

checked_add(x::Bool) = Int(x)

sub_with_overflow(x::Bool, y::Bool) = (sub_int(x, y), false)

if BrokenSignedInt != Union{}
function sub_with_overflow(x::T, y::T) where T<:BrokenSignedInt
    r = sub_int(x, y)
    # x and y have different signs, and the result has a different sign than x
    f = (x<0) != (y<0) == (r<0)
    r, f
end
end
if BrokenUnsignedInt != Union{}
function sub_with_overflow(x::T, y::T) where T<:BrokenUnsignedInt
    # x - y < 0
    sub_int(x, y), x < y
end
end

mul_with_overflow(x::Bool, y::Bool) = (mul_int(x, y), false)

if Int128 <: BrokenSignedIntMul
# Avoid BigInt
function mul_with_overflow(x::T, y::T) where T<:Int128
    f = if y > 0
        # x * y > typemax(T)
        # x * y < typemin(T)
        x > fld(typemax(T), y) || x < cld(typemin(T), y)
    elseif y < 0
        # x * y > typemax(T)
        # x * y < typemin(T)
        # y == -1 can overflow fld
        x < cld(typemax(T), y) || y != -1 && x > fld(typemin(T), y)
    else
        false
    end
    mul_int(x, y), f
end
end
if UInt128 <: BrokenUnsignedIntMul
# Avoid BigInt
function mul_with_overflow(x::T, y::T) where T<:UInt128
    # x * y > typemax(T)
    mul_int(x, y), y > 0 && x > fld(typemax(T), y)
end
end

end # module
