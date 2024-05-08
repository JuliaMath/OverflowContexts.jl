# saturating implementations

saturating_neg(x::T) where T <: BitInteger = saturating_sub(zero(T), x)

using Base: llvmcall
if VERSION ≥ v"1.5"
    # These intrinsics were added in LLVM 8, which was first supported with Julia 1.5
    saturating_add(x::Int8, y::Int8) =
        ccall("llvm.sadd.sat.i8", llvmcall, Int8, (Int8, Int8), x, y)
    saturating_add(x::Int16, y::Int16) =
        ccall("llvm.sadd.sat.i16", llvmcall, Int16, (Int16, Int16), x, y)
    saturating_add(x::Int32, y::Int32) =
        ccall("llvm.sadd.sat.i32", llvmcall, Int32, (Int32, Int32), x, y)
    saturating_add(x::Int64, y::Int64) =
        ccall("llvm.sadd.sat.i64", llvmcall, Int64, (Int64, Int64), x, y)
    saturating_add(x::Int128, y::Int128) =
        ccall("llvm.sadd.sat.i128", llvmcall, Int128, (Int128, Int128), x, y)
    saturating_add(x::UInt8, y::UInt8) =
        ccall("llvm.uadd.sat.i8", llvmcall, UInt8, (UInt8, UInt8), x, y)
    saturating_add(x::UInt16, y::UInt16) =
        ccall("llvm.uadd.sat.i16", llvmcall, UInt16, (UInt16, UInt16), x, y)
    saturating_add(x::UInt32, y::UInt32) =
        ccall("llvm.uadd.sat.i32", llvmcall, UInt32, (UInt32, UInt32), x, y)
    saturating_add(x::UInt64, y::UInt64) =
        ccall("llvm.uadd.sat.i64", llvmcall, UInt64, (UInt64, UInt64), x, y)
    saturating_add(x::UInt128, y::UInt128) =
        ccall("llvm.uadd.sat.i128", llvmcall, UInt128, (UInt128, UInt128), x, y)

    saturating_sub(x::Int8, y::Int8) =
        ccall("llvm.ssub.sat.i8", llvmcall, Int8, (Int8, Int8), x, y)
    saturating_sub(x::Int16, y::Int16) =
        ccall("llvm.ssub.sat.i16", llvmcall, Int16, (Int16, Int16), x, y)
    saturating_sub(x::Int32, y::Int32) =
        ccall("llvm.ssub.sat.i32", llvmcall, Int32, (Int32, Int32), x, y)
    saturating_sub(x::Int64, y::Int64) =
        ccall("llvm.ssub.sat.i64", llvmcall, Int64, (Int64, Int64), x, y)
    saturating_sub(x::Int128, y::Int128) =
        ccall("llvm.ssub.sat.i128", llvmcall, Int128, (Int128, Int128), x, y)
    saturating_sub(x::UInt8, y::UInt8) =
        ccall("llvm.usub.sat.i8", llvmcall, UInt8, (UInt8, UInt8), x, y)
    saturating_sub(x::UInt16, y::UInt16) =
        ccall("llvm.usub.sat.i16", llvmcall, UInt16, (UInt16, UInt16), x, y)
    saturating_sub(x::UInt32, y::UInt32) =
        ccall("llvm.usub.sat.i32", llvmcall, UInt32, (UInt32, UInt32), x, y)
    saturating_sub(x::UInt64, y::UInt64) =
        ccall("llvm.usub.sat.i64", llvmcall, UInt64, (UInt64, UInt64), x, y)
    saturating_sub(x::UInt128, y::UInt128) =
        ccall("llvm.usub.sat.i128", llvmcall, UInt128, (UInt128, UInt128), x, y)
else
    import Base.Checked: add_with_overflow, sub_with_overflow, mul_with_overflow

    function saturating_add(x::T, y::T) where T <: Union{Int128, UInt128}
        result, overflow_flag = add_with_overflow(x, y)
        if overflow_flag
            return sign(x) > 0 ?
                typemax(T) :
                typemin(T)
        end
        return result
    end

    function saturating_sub(x::T, y::T) where T <: Union{Int128, UInt128}
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
function saturating_pow(x_::T, p::S) where {T <: BitInteger, S <: BitInteger}
    result, overflow_flag = power_by_squaring(x_, p; mul = saturating_mul)
    if overflow_flag
        return sign(x_) > 0 ?
            typemax(T) :
            typemin(T)
    end
    return result
end
const SignedBitInteger = Union{Int8, Int16, Int32, Int64, Int128}
function saturating_abs(x::T) where T <: SignedBitInteger 
    result = flipsign(x, x)
    return result < 0 ? typemax(T) : result
end
