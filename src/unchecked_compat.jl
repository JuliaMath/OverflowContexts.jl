import Base: hash_64_64, hash_64_32, hash_32_32, hash_uint, hash_uint64, hash, memhash, memhash_seed,
    indexed_iterate, max_values, bitcast, tuplehash_seed, match, compile, PCRE, unitrange_last
import Base.PCRE: exec_r_data, free_match_data, ovec_length, ovec_ptr

# fix base methods that require overflow/underflow
hash(@nospecialize(x), h::UInt) = hash_uint(@unchecked 3h - objectid(x))

@unchecked function hash_64_64(n::UInt64)
    a::UInt64 = n
    a = ~a + a << 21
    a =  a ⊻ a >> 24
    a =  a + a << 3 + a << 8
    a =  a ⊻ a >> 14
    a =  a + a << 2 + a << 4
    a =  a ⊻ a >> 28
    a =  a + a << 31
    return a
end

@unchecked function hash_64_32(n::UInt64)
    a::UInt64 = n
    a = ~a + a << 18
    a =  a ⊻ a >> 31
    a =  a * 21
    a =  a ⊻ a >> 11
    a =  a + a << 6
    a =  a ⊻ a >> 22
    return a % UInt32
end

@unchecked function hash_32_32(n::UInt32)
    a::UInt32 = n
    a = a + 0x7ed55d16 + a << 12
    a = a ⊻ 0xc761c23c ⊻ a >> 19
    a = a + 0x165667b1 + a << 5
    a = a + 0xd3a2646c ⊻ a << 9
    a = a + 0xfd7046c5 + a << 3
    a = a ⊻ 0xb55a4f09 ⊻ a >> 16
    return a
end

hash(x::Int64,  h::UInt) = @unchecked hash_uint64(bitcast(UInt64, x)) - 3h
hash(x::UInt64, h::UInt) = @unchecked hash_uint64(x) - 3h

if UInt === UInt64
    hash(x::Expr, h::UInt) = hash(x.args, hash(x.head, @unchecked h + 0x83c7900696d26dc6))
    hash(x::QuoteNode, h::UInt) = hash(x.value, @unchecked h + 0x2c97bf8b3de87020)
else
    hash(x::Expr, h::UInt) = hash(x.args, hash(x.head, @unchecked h + 0x96d26dc6))
    hash(x::QuoteNode, h::UInt) = hash(x.value, @unchecked h + 0x469d72af)
end

@unchecked function hash(s::String, h::UInt)
    h += memhash_seed
    ccall(memhash, UInt, (Ptr{UInt8}, Csize_t, UInt32), s, sizeof(s), h % UInt32) + h
end

@inline @unchecked indexed_iterate(t::Tuple, i::Int, state=1) = (getfield(t, i), i + 1)
@inline @unchecked indexed_iterate(a::Array, i::Int, state=1) = (a[i], i + 1)

@unchecked function max_values(T::Union)
    a = max_values(T.a)::Int
    b = max_values(T.b)::Int
    return max(a, b, a + b)
end

# regex.jl
@unchecked function match(re::Regex, str::Union{SubString{String}, String}, idx::Integer, add_opts::UInt32=UInt32(0))
    compile(re)
    opts = re.match_options | add_opts
    matched, data = PCRE.exec_r_data(re.regex, str, idx-1, opts)
    if !matched
        PCRE.free_match_data(data)
        return nothing
    end
    n = div(PCRE.ovec_length(data), 2) - 1
    p = PCRE.ovec_ptr(data)
    mat = SubString(str, unsafe_load(p, 1)+1, prevind(str, unsafe_load(p, 2)+1))
    cap = Union{Nothing,SubString{String}}[unsafe_load(p,2i+1) == PCRE.UNSET ? nothing :
                                SubString(str, unsafe_load(p,2i+1)+1,
                                        prevind(str, unsafe_load(p,2i+2)+1)) for i=1:n]
    off = Int[ unsafe_load(p,2i+1)+1 for i=1:n ]
    result = RegexMatch(mat, cap, unsafe_load(p,1)+1, off, re)
    PCRE.free_match_data(data)
    return result
end

# tuple.jl
hash(::Tuple{}, h::UInt) = @unchecked h + tuplehash_seed

if VERSION ≥ v"1.7"
function hash(t::Base.Any32, h::UInt)
    out = @unchecked h + tuplehash_seed
    for i = length(t):-1:1
        out = hash(t[i], out)
    end
    return out
end
end

#range.jl
@unchecked unitrange_last(start::T, stop::T) where {T<:Integer} =
    stop >= start ? stop : convert(T,start-oneunit(start-stop))
@unchecked unitrange_last(start::T, stop::T) where {T} =
    stop >= start ? convert(T,start+floor(stop-start)) :
                    convert(T,start-oneunit(stop-start))
