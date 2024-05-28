module OverflowContexts

include("macros.jl")
include("base_ext.jl")
include("base_ext_sat.jl")
include("abstractarraymath_ext.jl")

export @default_checked, @default_unchecked, @default_saturating, @checked, @unchecked, @saturating

end # module
