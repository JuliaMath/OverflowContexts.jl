module OverflowContexts

include("macros.jl")
include("base_ext.jl")

export @default_checked, @default_unchecked, @checked, @unchecked, @unsafe_div
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub, unchecked_pow, unchecked_abs,
    unsafe_div, unsafe_fld, unsafe_cld, unsafe_rem, unsafe_mod, unsafe_divrem,
    checked_neg, checked_add, checked_sub, checked_mul, checked_pow, checked_negsub, checked_abs

end # module
