import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul
if VERSION ≥ v"1.11-alpha"
    import Base.Checked: checked_pow
end
if VERSION ≥ v"1.2"
    using Base: broadcast_preserving_zero_d
end

checked_neg(A::AbstractArray) = broadcast_preserving_zero_d(checked_neg, A)
for f in (:checked_add, :checked_sub)
    @eval function ($f)(A::AbstractArray, B::AbstractArray)
        promote_shape(A, B) # check size compatibility
        broadcast_preserving_zero_d($f, A, B)
    end
end
checked_mul(A::Number, B::AbstractArray) = broadcast_preserving_zero_d(checked_mul, B, A)
checked_mul(A::AbstractArray, B::Number) = broadcast_preserving_zero_d(checked_mul, A, B)
checked_mul(A::AbstractArray, B::AbstractArray) = error("Checked matrix multiplication is not available")

checked_pow(A::AbstractArray, B::Number) = error("Checked matrix multiplication is not available")

saturating_neg(A::AbstractArray) = broadcast_preserving_zero_d(saturating_neg, A)
for f in (:saturating_add, :saturating_sub)
    @eval function ($f)(A::AbstractArray, B::AbstractArray)
        promote_shape(A, B) # check size compatibility
        broadcast_preserving_zero_d($f, A, B)
    end
end
saturating_mul(A::Number, B::AbstractArray) = broadcast_preserving_zero_d(saturating_mul, B, A)
saturating_mul(A::AbstractArray, B::Number) = broadcast_preserving_zero_d(saturating_mul, A, B)
saturating_mul(A::AbstractArray, B::AbstractArray) = error("Saturating matrix multiplication is not available")

saturating_pow(A::AbstractArray, B::Number) = error("Saturating matrix multiplication is not available")

# Compatibility with Julia 1.0 and 1.1
if VERSION < v"1.2"
    if VERSION < v"1.1"
        @inline materialize(bc::Base.Broadcast.Broadcasted) = copy(Base.Broadcast.instantiate(bc))
    else
        using Base.Broadcast: materialize
    end
    @inline function broadcast_preserving_zero_d(f, As...)
        bc = Base.Broadcast.broadcasted(f, As...)
        r = materialize(bc)
        return length(axes(bc)) == 0 ? fill!(similar(bc, typeof(r)), r) : r
    end
end
