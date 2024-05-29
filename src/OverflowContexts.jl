module OverflowContexts

const SignedBitInteger = Union{Int8, Int16, Int32, Int64, Int128}
const UnsignedBitInteger = Union{UInt8, UInt16, UInt32, UInt64, UInt128}

using Base: BitInteger, promote, afoldl, @_inline_meta
import Base: literal_pow
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul, checked_abs,
    checked_div, checked_fld, checked_cld, checked_mod, checked_rem
using Base.Checked: mul_with_overflow

if VERSION ≥ v"1.11-alpha"
    import Base: power_by_squaring
    import Base.Checked: checked_pow
else
    using Base: throw_domerr_powbysq, to_power_type
    using Base.Checked: throw_overflowerr_binaryop
end

include("macros.jl")
include("checked.jl")
include("unchecked.jl")
include("saturating.jl")
include("abstractarraymath_ext.jl")

export @default_checked, @default_unchecked, @default_saturating, @checked, @unchecked, @saturating

end # module
