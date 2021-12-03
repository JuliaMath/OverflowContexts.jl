import Base: promote, add_int, sub_int, mul_int, afoldl, BitInteger
import Base.Checked: checked_add, add_with_overflow, sub_with_overflow, mul_with_overflow,
    BrokenSignedInt, BrokenUnsignedInt, throw_overflowerr_binaryop, BrokenSignedIntMul, BrokenUnsignedIntMul

# convert multi-argument calls into nested two-argument calls
unchecked_add(a, b, c, xs...) = @unchecked afoldl(+, (+)((+)(a, b), c), xs...)
unchecked_sub(a, b, c, xs...) = @unchecked afoldl(-, (-)((-)(a, b), c), xs...)
unchecked_mul(a, b, c, xs...) = @unchecked afoldl(*, (*)((*)(a, b), c), xs...)

checked_add(a, b, c, xs...) = @checked afoldl(+, (+)((+)(a, b), c), xs...)
checked_sub(a, b, c, xs...) = @checked afoldl(-, (-)((-)(a, b), c), xs...)
checked_mul(a, b, c, xs...) = @checked afoldl(*, (*)((*)(a, b), c), xs...)


# passthrough for non-numbers
unchecked_add(x, y) = x + y
unchecked_sub(x, y) = x - y
unchecked_mul(x, y) = x * y

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
unchecked_add(x::T, y::T) where T <: BitInteger = add_int(x, y)
unchecked_sub(x::T, y::T) where T <: BitInteger = sub_int(x, y)
unchecked_mul(x::T, y::T) where T <: BitInteger = mul_int(x, y)

function checked_add(x::T, y::T) where T <: BitInteger
    z, b = add_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:+, x, y)
    z
end
function checked_sub(x::T, y::T) where T <: BitInteger
    z, b = sub_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:-, x, y)
    z
end
function checked_mul(x::T, y::T) where T <: BitInteger
    z, b = mul_with_overflow(x, y)
    b && throw_overflowerr_binaryop(:*, x, y)
    z
end


# add @unchecked to necessary support methods
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
    
