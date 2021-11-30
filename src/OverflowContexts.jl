module OverflowContexts
__precompile__(false)

include("macros.jl")
include("base_ext.jl")
include("unchecked_compat.jl")

export @default_checked, @default_unchecked, @checked, @unchecked, unchecked_add, unchecked_sub, unchecked_mul

end # module
