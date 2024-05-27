import Base: BitInteger
import Base.Checked: mul_with_overflow

if VERSION ≤ v"1.11-alpha"
    import Base: power_by_squaring
end

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
    return @saturating d + (((x > 0) == (y > 0)) & (d * y != x))
end
function saturating_cld(x::T, y::T) where T <: UnsignedBitInteger
    d = saturating_div(x, y)
    return @saturating d + (d * y != x)
end

saturating_rem(x::T, y::T) where T <: SignedBitInteger =
    (y == zero(T)) ?
        x :
        (y == -one(T)) ?
            zero(T) :
            Base.srem_int(x, y)
saturating_rem(x::T, y::T) where T <: UnsignedBitInteger =
    (y == zero(T)) ?
        x :
        Base.urem_int(x, y)

saturating_mod(x::T, y::T) where T <: SignedBitInteger = @saturating x - fld(x, y) * y
saturating_mod(x::T, y::T) where T <: UnsignedBitInteger = @saturating rem(x, y)

saturating_divrem(x::T, y::T) where T <: BitInteger = @saturating div(x, y), rem(x, y)