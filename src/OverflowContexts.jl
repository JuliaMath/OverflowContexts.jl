module OverflowContexts

include("macros.jl")
include("base_ext.jl")
include("base_ext_sat.jl")
include("abstractarraymath_ext.jl")

export @default_checked, @default_unchecked, @default_saturating, @checked, @unchecked, @saturating,
    checked_div, checked_fld, checked_cld, checked_rem, checked_mod,
    unchecked_div, unchecked_fld, unchecked_cld, unchecked_rem, unchecked_mod,
    saturating_div, saturating_fld, saturating_cld, saturating_rem, saturating_mod

end # module
