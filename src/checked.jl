# resolve ambiguity when `-` used as symbol
checked_negsub(x) = checked_neg(x)
checked_negsub(x, y) = checked_sub(x, y)

# The Base div methods have checked semantics, so just pass through
checked_div(x...) = Base.:÷(x...)
checked_fld(x...) = Base.fld(x...)
checked_cld(x...) = Base.cld(x...)
checked_rem(x...) = Base.:%(x...) # Yes, % is `rem`, not `mod`
checked_mod(x...) = Base.mod(x...)
checked_divrem(x...) = Base.divrem(x...)

# convert multi-argument calls into nested two-argument calls
checked_add(a, b, c, xs...) = @checked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
checked_sub(a, b, c, xs...) = @checked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
checked_mul(a, b, c, xs...) = @checked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))

# promote unmatched number types to same type
checked_add(x::Number, y::Number) = checked_add(promote(x, y)...)
checked_sub(x::Number, y::Number) = checked_sub(promote(x, y)...)
checked_mul(x::Number, y::Number) = checked_mul(promote(x, y)...)
checked_pow(x::Number, y::Number) = checked_pow(promote(x, y)...)

# fallback to `unchecked_` for `Number` types that don't have more specific `checked_` methods
checked_neg(x::T) where T <: Number = unchecked_neg(x)
checked_add(x::T, y::T) where T <: Number = unchecked_add(x, y)
checked_sub(x::T, y::T) where T <: Number = unchecked_sub(x, y)
checked_mul(x::T, y::T) where T <: Number = unchecked_mul(x, y)
checked_pow(x::T, y::T) where T <: Number = unchecked_pow(x, y)
checked_abs(x::T) where T <: Number = unchecked_abs(x)

# fallback to `unchecked_` for non-`Number` types
checked_neg(x) = unchecked_neg(x)
checked_add(x, y) = unchecked_add(x, y)
checked_sub(x, y) = unchecked_sub(x, y)
checked_mul(x, y) = unchecked_mul(x, y)
checked_pow(x, y) = unchecked_pow(x, y)
checked_abs(x) = unchecked_abs(x)

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

# adapted from Base intfuncs.jl; negative literal powers promote to floating point
@inline literal_pow(::typeof(checked_pow), x::BitInteger, ::Val{0}) = one(x)
@inline literal_pow(::typeof(checked_pow), x::BitInteger, ::Val{1}) = x
@inline literal_pow(::typeof(checked_pow), x::BitInteger, ::Val{2}) = @checked x * x
@inline literal_pow(::typeof(checked_pow), x::BitInteger, ::Val{3}) = @checked x * x * x
@inline literal_pow(::typeof(checked_pow), x::BitInteger, ::Val{-1}) = literal_pow(^, x, Val(-1))
@inline literal_pow(::typeof(checked_pow), x::BitInteger, ::Val{-2}) = literal_pow(^, x, Val(-2))

@inline function literal_pow(f::typeof(checked_pow), x, ::Val{p}) where {p}
    if p < 0
        literal_pow(^, x, Val(p))
    else
        f(x, p)
    end
end
