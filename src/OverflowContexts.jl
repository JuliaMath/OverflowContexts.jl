module OverflowContexts
__precompile__(false)

using Requires

include("macros.jl")
include("base_ext.jl")
include("unchecked_compat.jl")

function __init__()
    @require SHA = "ea8e919c-243c-51af-8825-aaa63cd721ce" include("SHA_compat.jl")
end

export @default_checked, @default_unchecked, @checked, @unchecked,
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub,
    checked_neg, checked_add, checked_sub, checked_mul, checked_negsub#, unchecked_abs

end # module
