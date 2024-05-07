import Base: BitInteger, promote, afoldl, @_inline_meta
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul, checked_abs,
    add_with_overflow, sub_with_overflow, mul_with_overflow

if VERSION ≥ v"1.11-alpha"
    import Base.Checked: checked_pow, pow_with_overflow
else
    import Base: throw_domerr_powbysq, to_power_type
    import Base.Checked: throw_overflowerr_binaryop
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

saturating_add(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
saturating_sub(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
saturating_mul(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))


# promote unmatched number types to same type
checked_add(x::Number, y::Number) = checked_add(promote(x, y)...)
checked_sub(x::Number, y::Number) = checked_sub(promote(x, y)...)
checked_mul(x::Number, y::Number) = checked_mul(promote(x, y)...)
checked_pow(x::Number, y::Number) = checked_pow(promote(x, y)...)

saturating_add(x::Number, y::Number) = saturating_add(promote(x, y)...)
saturating_sub(x::Number, y::Number) = saturating_sub(promote(x, y)...)
saturating_mul(x::Number, y::Number) = saturating_mul(promote(x, y)...)
saturating_pow(x::Number, y::Number) = saturating_pow(promote(x, y)...)


# fallback to `unchecked_` for `Number` types that don't have more specific `checked_` methods
checked_neg(x::T) where T <: Number = unchecked_neg(x)
checked_add(x::T, y::T) where T <: Number = unchecked_add(x, y)
checked_sub(x::T, y::T) where T <: Number = unchecked_sub(x, y)
checked_mul(x::T, y::T) where T <: Number = unchecked_mul(x, y)
checked_pow(x::T, y::T) where T <: Number = unchecked_pow(x, y)
checked_abs(x::T) where T <: Number = unchecked_abs(x)

saturating_neg(x::T) where T <: Number = unchecked_neg(x)
saturating_add(x::T, y::T) where T <: Number = unchecked_add(x, y)
saturating_sub(x::T, y::T) where T <: Number = unchecked_sub(x, y)
saturating_mul(x::T, y::T) where T <: Number = unchecked_mul(x, y)
saturating_pow(x::T, y::T) where T <: Number = unchecked_pow(x, y)
saturating_abs(x::T) where T <: Number = unchecked_abs(x)

# fallback to `unchecked_` for non-`Number` types
checked_neg(x) = unchecked_neg(x)
checked_add(x, y) = unchecked_add(x, y)
checked_sub(x, y) = unchecked_sub(x, y)
checked_mul(x, y) = unchecked_mul(x, y)
checked_pow(x, y) = unchecked_pow(x, y)
checked_abs(x) = unchecked_abs(x)


saturating_neg(x::T) where T <: BitInteger = saturating_sub(zero(T), x)
function saturating_add(x::T, y::T) where T <: BitInteger
    result, overflow_flag = add_with_overflow(x, y)
    if overflow_flag
        return sign(x) > 0 ?
            typemax(T) :
            typemin(T)
    end
    return result
end
function saturating_sub(x::T, y::T) where T <: BitInteger
    result, overflow_flag = sub_with_overflow(x, y)
    if overflow_flag
        return y > x ?
            typemin(T) :
            typemax(T)
    end
    return result
end
function saturating_mul(x::T, y::T) where T <: BitInteger
    result, overflow_flag = mul_with_overflow(x, y)
    if overflow_flag
        return sign(x) == sign(y) ?
            typemax(T) :
            typemin(T)
    end
    return result
end
function saturating_pow(x::T, y::S) where {T <: BitInteger, S <: BitInteger}
    result, overflow_flag = pow_with_overflow(x, y)
    if overflow_flag
        return sign(x) > 0 ?
            typemax(T) :
            typemin(T)
    end
    return result
end
const SignedBitInteger = Union{Int8, Int16, Int32, Int64, Int128}
saturating_abs(x::T) where T <: SignedBitInteger = x == typemin(T) ? typemax(T) : flipsign(x, x)

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
