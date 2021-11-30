import Base.Checked: SignedInt, UnsignedInt, BrokenSignedInt, BrokenUnsignedInt, BrokenSignedIntMul, BrokenUnsignedIntMul,
    checked_abs, add_with_overflow, checked_neg, checked_add, sub_with_overflow, throw_overflowerr_negation, mul_with_overflow

# extended base functions to support switching between checked and unchecked

unchecked_add(x::Integer, y::Integer) = unchecked_add(promote(x,y)...)
unchecked_sub(x::Integer, y::Integer) = unchecked_sub(promote(x,y)...)
unchecked_mul(x::Integer, y::Integer) = unchecked_mul(promote(x,y)...)

unchecked_add(x::T, y::T) where T <: Integer = Base.add_int(x, y)
unchecked_sub(x::T, y::T) where T <: Integer = Base.sub_int(x, y)
unchecked_mul(x::T, y::T) where T <: Integer = Base.mul_int(x, y)
unchecked_abs(x::T) where T <: Signed = Base.flipsign_int(x, x)

# passthrough for non-integer math
checked_add(x::T, y::S) where {T <: Number, S <: Number} = x + y
checked_sub(x::T, y::S) where {T <: Number, S <: Number} = x - y
checked_mul(x::T, y::S) where {T <: Number, S <: Number} = x * y
checked_abs(x::T) where {T <: Number} = abs(x)
unchecked_add(x::T, y::S) where {T <: Number, S <: Number} = x + y
unchecked_sub(x::T, y::S) where {T <: Number, S <: Number} = x - y
unchecked_mul(x::T, y::S) where {T <: Number, S <: Number} = x * y
unchecked_abs(x::T) where {T <: Number} = abs(x)


for op in (:unchecked_add, :unchecked_mul)
    @eval begin
        ($op)(a, b, c, xs...) = Base.afoldl($op, ($op)(($op)(a,b),c), xs...)
    end
end

# Base.Checked
if BrokenSignedInt != Union{}
@unchecked function checked_neg(x::BrokenSignedInt)
    r = -x
    (x<0) & (r<0) && throw_overflowerr_negation(x)
    r
end
end

@inline @unchecked function checked_abs(x::SignedInt)
    r = ifelse(x<0, -x, x)
    r<0 && throw(OverflowError(string("checked arithmetic: cannot compute |x| for x = ", x, "::", typeof(x))))
    r
 end

 @unchecked add_with_overflow(x::Bool, y::Bool) = (x + y, false)

if BrokenSignedInt != Union{}
@unchecked function add_with_overflow(x::T, y::T) where T<:BrokenSignedInt
    r = x + y
    # x and y have the same sign, and the result has a different sign
    f = (x<0) == (y<0) != (r<0)
    r, f
end
end
if BrokenUnsignedInt != Union{}
@unchecked function add_with_overflow(x::T, y::T) where T<:BrokenUnsignedInt
    # x + y > typemax(T)
    # Note: ~y == -y-1
    x + y, x > ~y
end
end

checked_add(x::Bool) = Int(x)

@unchecked sub_with_overflow(x::Bool, y::Bool) = (x - y, false)

if BrokenSignedInt != Union{}
@unchecked function sub_with_overflow(x::T, y::T) where T<:BrokenSignedInt
    r = x - y
    # x and y have different signs, and the result has a different sign than x
    f = (x<0) != (y<0) == (r<0)
    r, f
end
end
if BrokenUnsignedInt != Union{}
@unchecked function sub_with_overflow(x::T, y::T) where T<:BrokenUnsignedInt
    # x - y < 0
    x - y, x < y
end
end

@unchecked mul_with_overflow(x::Bool, y::Bool) = (x * y, false)

if Int128 <: BrokenSignedIntMul
# Avoid BigInt
@unchecked function mul_with_overflow(x::T, y::T) where T<:Int128
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
    x * y, f
end
end
if UInt128 <: BrokenUnsignedIntMul
# Avoid BigInt
@unchecked function mul_with_overflow(x::T, y::T) where T<:UInt128
    # x * y > typemax(T)
    x * y, y > 0 && x > fld(typemax(T), y)
end
end
