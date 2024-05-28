module OverflowContexts

include("macros.jl")
include("base_ext.jl")
include("base_ext_sat.jl")
include("abstractarraymath_ext.jl")

export @default_checked, @default_unchecked, @default_saturating, @checked, @unchecked, @saturating,
    checked_neg, checked_add, checked_sub, checked_mul, checked_pow, checked_negsub, checked_abs, checked_div, checked_fld, checked_cld, checked_rem, checked_mod,
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub, unchecked_pow, unchecked_abs, unchecked_div, unchecked_fld, unchecked_cld, unchecked_rem, unchecked_mod,
    saturating_neg, saturating_add, saturating_sub, saturating_mul, saturating_pow, saturating_negsub, saturating_abs, saturating_div, saturating_fld, saturating_cld, saturating_rem, saturating_mod

end # module
