module OverflowContexts

include("macros.jl")
include("base_ext.jl")

export @default_checked, @default_unchecked, @default_saturating, @checked, @unchecked, @saturating,
    checked_neg, checked_add, checked_sub, checked_mul, checked_pow, checked_negsub, checked_abs,
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub, unchecked_pow, unchecked_abs,
    saturating_neg, saturating_add, saturating_sub, saturating_mul, saturating_pow, saturating_negsub, saturating_abs

end # module
