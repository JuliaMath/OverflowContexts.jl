import Base: promote, neg_int, add_int, sub_int, mul_int, afoldl, @_inline_meta
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul, checked_abs,
    add_with_overflow, sub_with_overflow, mul_with_overflow, SignedInt,
    throw_overflowerr_binaryop

# convert multi-argument calls into nested two-argument calls
unchecked_add(a, b, c, xs...) = @unchecked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
unchecked_sub(a, b, c, xs...) = @unchecked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
unchecked_mul(a, b, c, xs...) = @unchecked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))

checked_add(a, b, c, xs...) = @checked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
checked_sub(a, b, c, xs...) = @checked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
checked_mul(a, b, c, xs...) = @checked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))


# passthrough for non-numbers
unchecked_neg(x) = Base.:-(x)
unchecked_add(x, y) = Base.:+(x, y)
unchecked_sub(x, y) = Base.:-(x, y)
unchecked_mul(x, y) = Base.:*(x, y)
unchecked_abs(x) = Base.abs(x)

checked_neg(x) = Base.:-(x)
checked_add(x, y) = Base.:+(x, y)
checked_sub(x, y) = Base.:-(x, y)
checked_mul(x, y) = Base.:*(x, y)
checked_abs(x) = Base.abs(x)

# promote unmatched number types to same type
unchecked_add(x::Number, y::Number) = unchecked_add(promote(x, y)...)
unchecked_sub(x::Number, y::Number) = unchecked_sub(promote(x, y)...)
unchecked_mul(x::Number, y::Number) = unchecked_mul(promote(x, y)...)

checked_add(x::Number, y::Number) = checked_add(promote(x, y)...)
checked_sub(x::Number, y::Number) = checked_sub(promote(x, y)...)
checked_mul(x::Number, y::Number) = checked_mul(promote(x, y)...)


# passthrough for same-type numbers that aren't integers
unchecked_add(x::T, y::T) where T <: Number = Base.:+(x, y)
unchecked_sub(x::T, y::T) where T <: Number = Base.:-(x, y)
unchecked_mul(x::T, y::T) where T <: Number = Base.:*(x, y)

checked_add(x::T, y::T) where T <: Number = Base.:+(x, y)
checked_sub(x::T, y::T) where T <: Number = Base.:-(x, y)
checked_mul(x::T, y::T) where T <: Number = Base.:*(x, y)


# core methods
unchecked_neg(x::T) where T <: BitInteger = neg_int(x)
unchecked_add(x::T, y::T) where T <: BitInteger = add_int(x, y)
unchecked_sub(x::T, y::T) where T <: BitInteger = sub_int(x, y)
unchecked_mul(x::T, y::T) where T <: BitInteger = mul_int(x, y)
unchecked_abs(x::T) where T <: SignedBitInteger = flipsign(x, x)

checked_neg(x::T) where T <: BitInteger = @checked T(0) - x
function checked_add(x::T, y::T) where T <: BitInteger
    @_inline_meta
    z, b = add_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:+, x, y)
    z
end
function checked_sub(x::T, y::T) where T <: BitInteger
    @_inline_meta
    z, b = sub_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:-, x, y)
    z
end
function checked_mul(x::T, y::T) where T <: BitInteger
    @_inline_meta
    z, b = mul_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:*, x, y)
    z
end
function checked_abs(x::SignedBitInteger)
    @_inline_meta
    r = @unchecked ifelse(x < 0, -x, x)
    r < 0 && throw(OverflowError(string("checked arithmetic: cannot compute |x| for x = ", x, "::", typeof(x))))
    r
 end
