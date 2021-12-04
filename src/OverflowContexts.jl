module OverflowContexts
__precompile__(false)

using Requires

include("macros.jl")
include("base_ext.jl")
include("unchecked_compat.jl")

function __init__()
    @require SHA = "ea8e919c-243c-51af-8825-aaa63cd721ce" include("SHA_compat.jl")
    @require Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c" include("Random_compat.jl")
    @require Revise = "295af30f-e4ad-537b-8983-00126c2a3abe" include("Revise_compat.jl")
end

export @default_checked, @default_unchecked, @checked, @unchecked,
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub, unchecked_abs,
    checked_neg, checked_add, checked_sub, checked_mul, checked_negsub, checked_abs,
    SignedBitInteger

end # module
