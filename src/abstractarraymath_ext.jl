import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul
if VERSION ≥ v"1.11-alpha"
    import Base.Checked: checked_pow
end

checked_neg(A::AbstractArray) = Base.broadcast_preserving_zero_d(checked_neg, A)
for f in (:checked_add, :checked_sub)
    @eval function ($f)(A::AbstractArray, B::AbstractArray)
        promote_shape(A, B) # check size compatibility
        Base.broadcast_preserving_zero_d($f, A, B)
    end
end
checked_mul(A::Number, B::AbstractArray) = Base.broadcast_preserving_zero_d(checked_mul, B, A)
checked_mul(A::AbstractArray, B::Number) = Base.broadcast_preserving_zero_d(checked_mul, A, B)
checked_mul(A::AbstractArray, B::AbstractArray) = error("Checked matrix multiplication is not available")

checked_pow(A::AbstractArray, B::Number) = error("Checked matrix multiplication is not available")

if VERSION < v"1.2"
    # Compatibility with Julia 1.0 and 1.1
    @inline function broadcast_preserving_zero_d(f, As...)
        bc = Base.broadcasted(f, As...)
        r = Base.materialize(bc)
        return length(axes(bc)) == 0 ? fill!(similar(bc, typeof(r)), r) : r
    end
end
