using Base: BitInteger, promote, afoldl, @_inline_meta
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul, checked_abs,
    checked_div, checked_fld, checked_cld, checked_mod, checked_rem
using Base.Checked: mul_with_overflow

if VERSION ≥ v"1.11-alpha"
    import Base: power_by_squaring
    import Base.Checked: checked_pow
else
    using Base: throw_domerr_powbysq, to_power_type
    using Base.Checked: throw_overflowerr_binaryop
end

const SignedBitInteger = Union{Int8, Int16, Int32, Int64, Int128}
const UnsignedBitInteger = Union{UInt8, UInt16, UInt32, UInt64, UInt128}

# The Base methods have unchecked semantics, so just pass through
unchecked_neg(x...) = Base.:-(x...)
unchecked_add(x...) = Base.:+(x...)
unchecked_sub(x...) = Base.:-(x...)
unchecked_mul(x...) = Base.:*(x...)
unchecked_pow(x...) = Base.:^(x...)
unchecked_abs(x...) = Base.abs(x...)

# The Base div methods have checked semantics, so just pass through
checked_div(x...) = Base.:÷(x...)
checked_fld(x...) = Base.fld(x...)
checked_cld(x...) = Base.cld(x...)
checked_rem(x...) = Base.rem(x...)
checked_mod(x...) = Base.:%(x...)
checked_divrem(x...) = Base.divrem(x...)

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

saturating_div(x::Number, y::Number) = saturating_div(promote(x, y)...)
saturating_fld(x::Number, y::Number) = saturating_fld(promote(x, y)...)
saturating_cld(x::Number, y::Number) = saturating_cld(promote(x, y)...)
saturating_rem(x::Number, y::Number) = saturating_rem(promote(x, y)...)
saturating_mod(x::Number, y::Number) = saturating_mod(promote(x, y)...)
saturating_divrem(x::Number, y::Number) = saturating_divrem(promote(x, y)...)


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

saturating_div(x::T, y::T) where T <: Number = saturating_div(x, y)
saturating_fld(x::T, y::T) where T <: Number = saturating_fld(x, y)
saturating_cld(x::T, y::T) where T <: Number = saturating_cld(x, y)
saturating_rem(x::T, y::T) where T <: Number = saturating_rem(x, y)
saturating_mod(x::T, y::T) where T <: Number = saturating_mod(x, y)
saturating_divrem(x::T, y::T) where T <: Number = saturating_divrem(x, y)


# fallback to `unchecked_` for non-`Number` types
checked_neg(x) = unchecked_neg(x)
checked_add(x, y) = unchecked_add(x, y)
checked_sub(x, y) = unchecked_sub(x, y)
checked_mul(x, y) = unchecked_mul(x, y)
checked_pow(x, y) = unchecked_pow(x, y)
checked_abs(x) = unchecked_abs(x)


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
    return d - (signbit(x ⊻ y) & (d * y != x))
end
unchecked_fld(x::T, y::T) where T <: UnsignedBitInteger = unchecked_div(x, y)

function unchecked_cld(x::T, y::T) where T <: SignedBitInteger
    d = unchecked_div(x, y)
    return d + (((x > 0) == (y > 0)) & (d * y != x))
end
function unchecked_cld(x::T, y::T) where T <: UnsignedBitInteger
    d = unchecked_div(x, y)
    return d + (d * y != x)
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

unchecked_divrem(x::T, y::T) where T <: BitInteger = unchecked_div(x, y), unchecked_rem(x, y)


if VERSION < v"1.11"
# Base.Checked only gained checked powers in 1.11

checked_pow(x_::T, p::S) where {T <: BitInteger, S <: BitInteger} =
    power_by_squaring(x_, p; mul = checked_mul)

# Base.@assume_effects :terminates_locally # present in Julia 1.11 code, but only supported from 1.8 on
function power_by_squaring(x_, p::Integer; mul=*)
    x = to_power_type(x_)
    if p == 1
        return copy(x)
    elseif p == 0
        return one(x)
    elseif p == 2
        return mul(x, x)
    elseif p < 0
        isone(x) && return copy(x)
        isone(-x) && return iseven(p) ? one(x) : copy(x)
        throw_domerr_powbysq(x, p)
    end
    t = trailing_zeros(p) + 1
    p >>= t
    while (t -= 1) > 0
        x = mul(x, x)
    end
    y = x
    while p > 0
        t = trailing_zeros(p) + 1
        p >>= t
        while (t -= 1) >= 0
            x = mul(x, x)
        end
        y = mul(y, x)
    end
    return y
end

end
