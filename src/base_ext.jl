import Base: promote, afoldl, @_inline_meta
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul, checked_abs  

if VERSION ≥ v"1.11-alpha"
    import Base.Checked: checked_pow
else
    import Base: BitInteger, throw_domerr_powbysq, to_power_type
    import Base.Checked: mul_with_overflow, throw_overflowerr_binaryop
end

# The Base methods have unchecked semantics, so just pass through
unchecked_neg(x...) = Base.:-(x...)
unchecked_add(x...) = Base.:+(x...)
unchecked_sub(x...) = Base.:-(x...)
unchecked_mul(x...) = Base.:*(x...)
unchecked_pow(x...) = Base.:^(x...)
unchecked_abs(x...) = Base.abs(x...)


# convert multi-argument calls into nested two-argument calls
checked_add(a, b, c, xs...) = @checked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
checked_sub(a, b, c, xs...) = @checked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
checked_mul(a, b, c, xs...) = @checked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))


# promote unmatched number types to same type
checked_add(x::Number, y::Number) = checked_add(promote(x, y)...)
checked_sub(x::Number, y::Number) = checked_sub(promote(x, y)...)
checked_mul(x::Number, y::Number) = checked_mul(promote(x, y)...)
checked_pow(x::Number, y::Number) = checked_pow(promote(x, y)...)

unsafe_div(x::Number, y::Number, args...) = unsafe_div(promote(x, y)..., args...)
unsafe_fld(x::Number, y::Number) = unsafe_fld(promote(x, y)...)
unsafe_cld(x::Number, y::Number) = unsafe_cld(promote(x, y)...)
unsafe_rem(x::Number, y::Number, args...) = unsafe_rem(promote(x, y)..., args...)
unsafe_mod(x::Number, y::Number) = unsafe_mod(promote(x, y)...)
unsafe_divrem(x::Number, y::Number, args...) = unsafe_divrem(promote(x, y)..., args...)


# fallback to `unchecked_` for `Number` types that don't have more specific `checked_` methods
checked_neg(x::T) where T <: Number = unchecked_neg(x)
checked_add(x::T, y::T) where T <: Number = unchecked_add(x, y)
checked_sub(x::T, y::T) where T <: Number = unchecked_sub(x, y)
checked_mul(x::T, y::T) where T <: Number = unchecked_mul(x, y)
checked_pow(x::T, y::T) where T <: Number = unchecked_pow(x, y)
checked_abs(x::T) where T <: Number = unchecked_abs(x)

unsafe_div(x::T, y::T, args...) where T <: Number = unsafe_div(x, y, args...)
unsafe_fld(x::T, y::T) where T <: Number = unsafe_fld(x, y)
unsafe_cld(x::T, y::T) where T <: Number = unsafe_cld(x, y)
unsafe_rem(x::T, y::T, args...) where T <: Number = unsafe_rem(x, y, args...)
unsafe_mod(x::T, y::T) where T <: Number = unsafe_mod(x, y)
unsafe_divrem(x::T, y::T, args...) where T <: Number = unsafe_divrem(x, y, args...)

# fallback to `unchecked_` for non-`Number` types
checked_neg(x) = unchecked_neg(x)
checked_add(x, y) = unchecked_add(x, y)
checked_sub(x, y) = unchecked_sub(x, y)
checked_mul(x, y) = unchecked_mul(x, y)
checked_pow(x, y) = unchecked_pow(x, y)
checked_abs(x) = unchecked_abs(x)

unsafe_div(x, y, args...) = unsafe_div(x, y, args...)
unsafe_fld(x, y) = unsafe_fld(x, y)
unsafe_cld(x, y) = unsafe_cld(x, y)
unsafe_rem(x, y, args...) = unsafe_rem(x, y, args...)
unsafe_mod(x, y) = unsafe_mod(x, y)
unsafe_divrem(x, y, args...) = unsafe_divrem(x, y, args...)


# unsafe div implementations
unsafe_div(x::T, y::T) where T <: SignedBitInteger = Base.sdiv_int(x, y)
unsafe_div(x::T, y::T) where T <: UnsignedBitInteger = Base.udiv_int(x, y)
unsafe_div(a::T, b::T, ::typeof(RoundToZero)) where T <: BitInteger = unsafe_div(a, b)
unsafe_div(x::T, y::T, ::typeof(RoundDown)) where T <: UnsignedBitInteger = unsafe_div(x, y)
function unsafe_div(x::T, y::T, ::typeof(RoundDown)) where T<:BitInteger
    d = unsafe_div(x, y, RoundToZero)
    return d - (signbit(x ⊻ y) & (d * y != x))
end
function unsafe_div(x::T, y::T, ::typeof(RoundUp)) where T <: SignedBitInteger
    d = unsafe_div(x, y, RoundToZero)
    return d + (((x > 0) == (y > 0)) & (d * y != x))
end
function unsafe_div(x::T, y::T, ::typeof(RoundUp)) where T <: UnsignedBitInteger
    d = unsafe_div(x, y, RoundToZero)
    return d + (d * y != x)
end
unsafe_fld(a::T, b::T) where T <: BitInteger = unsafe_div(a, b, RoundDown)
unsafe_cld(a::T, b::T) where T <: BitInteger = unsafe_div(a, b, RoundUp)

if VERSION < v"1.11"
# Base.Checked only gained checked powers in 1.11

function checked_pow(x::T, y::S) where {T <: BitInteger, S <: BitInteger}
    @_inline_meta
    z, b = pow_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:^, x, y)
    z
end

function pow_with_overflow(x_, p::Integer)
    x = to_power_type(x_)
    if p == 1
        return (copy(x), false)
    elseif p == 0
        return (one(x), false)
    elseif p == 2
        return mul_with_overflow(x, x)
    elseif p < 0
        isone(x) && return (copy(x), false)
        isone(-x) && return (iseven(p) ? one(x) : copy(x), false)
        throw_domerr_powbysq(x, p)
    end
    t = trailing_zeros(p) + 1
    p >>= t
    b = false
    while (t -= 1) > 0
        x, b1 = mul_with_overflow(x, x)
        b |= b1
    end
    y = x
    while p > 0
        t = trailing_zeros(p) + 1
        p >>= t
        while (t -= 1) >= 0
            x, b1 = mul_with_overflow(x, x)
            b |= b1
        end
        y, b1 = mul_with_overflow(y, x)
        b |= b1
    end
    return y, b
end
pow_with_overflow(x::Bool, p::Unsigned) = ((p==0) | x, false)
function pow_with_overflow(x::Bool, p::Integer)
    p < 0 && !x && throw_domerr_powbysq(x, p)
    return (p==0) | x, false
end

end
