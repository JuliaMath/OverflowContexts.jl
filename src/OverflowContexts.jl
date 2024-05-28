module OverflowContexts

const SignedBitInteger = Union{Int8, Int16, Int32, Int64, Int128}
const UnsignedBitInteger = Union{UInt8, UInt16, UInt32, UInt64, UInt128}

include("macros.jl")
include("checked.jl")
include("unchecked.jl")
include("saturating.jl")
include("abstractarraymath_ext.jl")

export @default_checked, @default_unchecked, @default_saturating, @checked, @unchecked, @saturating

end # module
