# resolve ambiguity when `-` used as symbol
unchecked_negsub(x) = unchecked_neg(x)
unchecked_negsub(x, y) = unchecked_sub(x, y)

# The Base methods have unchecked semantics, so just pass through
unchecked_neg(x...) = Base.:-(x...)
unchecked_add(x...) = Base.:+(x...)
unchecked_sub(x...) = Base.:-(x...)
unchecked_mul(x...) = Base.:*(x...)
unchecked_pow(x...) = Base.:^(x...)
unchecked_abs(x...) = Base.abs(x...)

# fallback to `checked_` div methods for non-`Number` types
unchecked_div(x, y) = checked_div(x, y)
unchecked_fld(x, y) = checked_fld(x, y)
unchecked_cld(x, y) = checked_cld(x, y)
unchecked_rem(x, y) = checked_rem(x, y)
unchecked_mod(x, y) = checked_mod(x, y)
unchecked_divrem(x, y) = checked_divrem(x, y)

# unchecked div implementations
# integer division is so slow that these branches don't seem to matter?
# We're making integer division unchecked by letting `÷ -1` just be negated unchecked,
# and `÷ 0` be 0.
unchecked_div(x::T, y::T) where T <: SignedBitInteger =
    (y == zero(T)) ?
        zero(T) :
        (y == -one(T)) ?
            -x :
            Base.sdiv_int(x, y)
unchecked_div(x::T, y::T) where T <: UnsignedBitInteger =
    (y == zero(T)) ?
        zero(T) :
        Base.udiv_int(x, y)

function unchecked_fld(x::T, y::T) where T <: SignedBitInteger
    d = unchecked_div(x, y)
    return y == 0 ?
        d :
        d - (signbit(x ⊻ y) & (d * y != x))
end
unchecked_fld(x::T, y::T) where T <: UnsignedBitInteger = unchecked_div(x, y)

function unchecked_cld(x::T, y::T) where T <: SignedBitInteger
    d = unchecked_div(x, y)
    return x == typemin(T) && y == -1 || y == 0 ?
        d :
        d + (((x > 0) == (y > 0)) & (d * y != x))
end
function unchecked_cld(x::T, y::T) where T <: UnsignedBitInteger
    d = unchecked_div(x, y)
    return y == 0 ?
        d :
        d + (d * y != x)
end

unchecked_rem(x::T, y::T) where T <: SignedBitInteger =
    (y == zero(T)) ?
        x :
        (y == -one(T)) ?
            zero(T) :
            Base.srem_int(x, y)
unchecked_rem(x::T, y::T) where T <: UnsignedBitInteger =
    (y == zero(T)) ?
        x :
        Base.urem_int(x, y)

unchecked_mod(x::T, y::T) where T <: SignedBitInteger = x - unchecked_fld(x, y) * y
unchecked_mod(x::T, y::T) where T <: UnsignedBitInteger = unchecked_rem(x, y)
