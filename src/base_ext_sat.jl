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
    if overflow_flag
        return sign(x) == sign(y) ?
            typemax(T) :
            typemin(T)
    end
    return result
end
saturating_pow(x_::T, p::S) where {T <: BitInteger, S <: BitInteger} =
    power_by_squaring(x_, p; mul = saturating_mul)
const SignedBitInteger = Union{Int8, Int16, Int32, Int64, Int128}
function saturating_abs(x::T) where T <: SignedBitInteger 
    result = flipsign(x, x)
    return result < 0 ? typemax(T) : result
end
