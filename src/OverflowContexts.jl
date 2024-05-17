module OverflowContexts

include("macros.jl")
include("base_ext.jl")
include("abstractarraymath_ext.jl")

export @default_checked, @default_unchecked, @checked, @unchecked,
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub, unchecked_pow, unchecked_abs,
    checked_neg, checked_add, checked_sub, checked_mul, checked_pow, checked_negsub, checked_abs

end # module
