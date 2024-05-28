import Base: BitInteger
import Base.Checked: mul_with_overflow

if VERSION ≤ v"1.11-alpha"
    import Base: power_by_squaring
end

# resolve ambiguity when `-` used as symbol
saturating_negsub(x) = saturating_neg(x)
saturating_negsub(x, y) = saturating_sub(x, y)

# convert multi-argument calls into nested two-argument calls
saturating_add(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
saturating_sub(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
saturating_mul(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))

# promote unmatched number types to same type
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

# saturating implementations
saturating_neg(x::T) where T <: BitInteger = saturating_sub(zero(T), x)

if VERSION ≥ v"1.5"
    using Base: llvmcall

    # These intrinsics were added in LLVM 8, which was first supported with Julia 1.5
    @generated function saturating_add(x::T, y::T) where T <: BitInteger
        llvm_su = T <: Signed ? "s" : "u"
        llvm_t = "i" * string(8sizeof(T))
        llvm_intrinsic = "llvm.$(llvm_su)add.sat.$llvm_t"
        :(ccall($llvm_intrinsic, llvmcall, $T, ($T, $T), x, y))
    end

    @generated function saturating_sub(x::T, y::T) where T <: BitInteger
        llvm_su = T <: Signed ? "s" : "u"
        llvm_t = "i" * string(8sizeof(T))
        llvm_intrinsic = "llvm.$(llvm_su)sub.sat.$llvm_t"
        :(ccall($llvm_intrinsic, llvmcall, $T, ($T, $T), x, y))
    end

else
    import Base.Checked: add_with_overflow, sub_with_overflow

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
end

function saturating_mul(x::T, y::T) where T <: BitInteger
    result, overflow_flag = mul_with_overflow(x, y)
    return overflow_flag ?
        (sign(x) == sign(y) ?
            typemax(T) :
            typemin(T)) :
        result
end

saturating_pow(x_::T, p::S) where {T <: BitInteger, S <: BitInteger} =
    power_by_squaring(x_, p; mul = saturating_mul)

function saturating_abs(x::T) where T <: SignedBitInteger 
    result = flipsign(x, x)
    return result < 0 ? typemax(T) : result
end

# for saturating, letting `÷ -1` be negated with saturation, and `÷ 0` be the type min,
# 0, or max based on the sign of the dividend
function saturating_div(x::T, y::T) where T <: SignedBitInteger
    return (y == zero(T)) ?
        ((x == zero(T)) ?
            zero(T) :
            saturating_mul(-sign(x), typemin(T))) :
        (y == -one(T)) ?
            saturating_neg(x) :
            Base.sdiv_int(x, y)
end
saturating_div(x::T, y::T) where T <: UnsignedBitInteger =
    (y == zero(T)) ?
        (x == zero(T) ?
            zero(T) :
            typemax(T)) :
        Base.udiv_int(x, y)

function saturating_fld(x::T, y::T) where T <: SignedBitInteger
    d = saturating_div(x, y)
    return @saturating d - (signbit(x ⊻ y) & (d * y != x))
end
saturating_fld(x::T, y::T) where T <: UnsignedBitInteger = saturating_div(x, y)

function saturating_cld(x::T, y::T) where T <: SignedBitInteger
    d = saturating_div(x, y)
    return x == typemin(T) && y == -1 || y == 0 ?
        d :
        d + (((x > 0) == (y > 0)) & (d * y != x))
end
function saturating_cld(x::T, y::T) where T <: UnsignedBitInteger
    d = saturating_div(x, y)
    return y == 0 ?
        d :
        d + (d * y != x)
end

saturating_rem(x::T, y::T) where T <: SignedBitInteger =
    (y == zero(T) || y == -one(T)) ?
        zero(T) :
        Base.srem_int(x, y)
saturating_rem(x::T, y::T) where T <: UnsignedBitInteger =
    (y == zero(T)) ?
        zero(T) :
        Base.urem_int(x, y)

function saturating_mod(x::T, y::T) where T <: SignedBitInteger
    return x == typemin(T) && y == -1 || y == 0 ?
        (@saturating rem(x, y)) :
        @saturating x - fld(x, y) * y
end

saturating_mod(x::T, y::T) where T <: UnsignedBitInteger = @saturating rem(x, y)
