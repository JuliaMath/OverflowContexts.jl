import Base: promote, neg_int, add_int, sub_int, mul_int, afoldl, BitInteger, @_inline_meta
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul,
    add_with_overflow, sub_with_overflow, mul_with_overflow,
    BrokenSignedInt, BrokenUnsignedInt, BrokenSignedIntMul, BrokenUnsignedIntMul,
    throw_overflowerr_binaryop, throw_overflowerr_negation

# convert multi-argument calls into nested two-argument calls
unchecked_add(a, b, c, xs...) = @unchecked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
unchecked_sub(a, b, c, xs...) = @unchecked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
unchecked_mul(a, b, c, xs...) = @unchecked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))

checked_add(a, b, c, xs...) = @checked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
checked_sub(a, b, c, xs...) = @checked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
checked_mul(a, b, c, xs...) = @checked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))


# passthrough for non-numbers
unchecked_neg(x) = -x
unchecked_add(x, y) = x + y
unchecked_sub(x, y) = x - y
unchecked_mul(x, y) = x * y

checked_neg(x) = -x
checked_add(x, y) = x + y
checked_sub(x, y) = x - y
checked_mul(x, y) = x * y

# promote unmatched number types to same type
unchecked_add(x::Number, y::Number) = unchecked_add(promote(x, y)...)
unchecked_sub(x::Number, y::Number) = unchecked_sub(promote(x, y)...)
unchecked_mul(x::Number, y::Number) = unchecked_mul(promote(x, y)...)

checked_add(x::Number, y::Number) = checked_add(promote(x, y)...)
checked_sub(x::Number, y::Number) = checked_sub(promote(x, y)...)
checked_mul(x::Number, y::Number) = checked_mul(promote(x, y)...)


# passthrough for same-type numbers that aren't integers
unchecked_add(x::T, y::T) where T <: Number = x + y
unchecked_sub(x::T, y::T) where T <: Number = x - y
unchecked_mul(x::T, y::T) where T <: Number = x * y

checked_add(x::T, y::T) where T <: Number = x + y
checked_sub(x::T, y::T) where T <: Number = x - y
checked_mul(x::T, y::T) where T <: Number = x * y


# core methods
unchecked_neg(x::T) where T <: BitInteger = neg_int(x)
unchecked_add(x::T, y::T) where T <: BitInteger = add_int(x, y)
unchecked_sub(x::T, y::T) where T <: BitInteger = sub_int(x, y)
unchecked_mul(x::T, y::T) where T <: BitInteger = mul_int(x, y)

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


# add @unchecked to necessary support methods
if BrokenSignedInt != Union{}
function checked_neg(x::T) where T <: BrokenSignedInt
    r = @unchecked -x
    (x<0) & (r<0) && throw_overflowerr_negation(x)
    r
end
end

add_with_overflow(x::Bool, y::Bool) = ((@unchecked x + y), false)
if BrokenSignedInt != Union{}
function add_with_overflow(x::T, y::T) where T <: BrokenSignedInt
    r = @unchecked x + y
    # x and y have the same sign, and the result has a different sign
    f = (x < 0) == (y < 0) != (r < 0)
    return r, f
end
end
if BrokenUnsignedInt != Union{}
function add_with_overflow(x::T, y::T) where T <: BrokenUnsignedInt
    # x + y > typemax(T)
    # Note: ~y == -y - 1
    return (@unchecked x + y), x > ~y
end
end

sub_with_overflow(x::Bool, y::Bool) = ((@unchecked x - y), false)
if BrokenSignedInt != Union{}
function sub_with_overflow(x::T, y::T) where T<:BrokenSignedInt
    r = @unchecked x - y
    # x and y have different signs, and the result has a different sign than x
    f = (x<0) != (y<0) == (r<0)
    r, f
end
end
if BrokenUnsignedInt != Union{}
function sub_with_overflow(x::T, y::T) where T<:BrokenUnsignedInt
    # x - y < 0
    (@unchecked x - y), x < y
end
end

mul_with_overflow(x::Bool, y::Bool) = ((@unchecked x * y), false)
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
        return (@unchecked x * y), f
    end
end
if UInt128 <: BrokenUnsignedIntMul
    # Avoid BigInt
    function mul_with_overflow(x::T, y::T) where T<:UInt128
        # x * y > typemax(T)
        return (@unchecked x * y), y > 0 && x > fld(typemax(T), y)
    end
end
