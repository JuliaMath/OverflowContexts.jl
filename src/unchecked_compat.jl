import Base: hash_64_64, hash_64_32, hash_32_32, hash_uint, hash_uint64, hash, memhash, memhash_seed,
    indexed_iterate, max_values, bitcast, tuplehash_seed, match, compile, PCRE, unitrange_last,
    split_sign
import Base.PCRE: exec_r_data, free_match_data, ovec_length, ovec_ptr
import Base.Ryu: reduce_shortest, uinttype, significand_mask, exponent_mask, significand_bits, exponent_bias,
    log10pow5, pow5bits, pow5_bitcount, mulshiftsplit, qbound, pow2, writeshortest, append_sign, decimallength,
    DIGIT_TABLE, memcpy, memmove, mulshiftmod1e9, umul256_hi

# fix base methods that require overflow/underflow
split_sign(n::Integer) = unsigned(@unchecked abs(n)), n < 0


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

@inline indexed_iterate(t::Tuple, i::Int, state=1) = (getfield(t, i), @unchecked i + 1)
@inline indexed_iterate(a::Array, i::Int, state=1) = (a[i], @unchecked i + 1)

@unchecked function max_values(T::Union)
    a = max_values(T.a)::Int
    b = max_values(T.b)::Int
    return max(a, b, a + b)
end

@unchecked function hash(s::SubString{String}, h::UInt)
    h += memhash_seed
    ccall(memhash, UInt, (Ptr{UInt8}, Csize_t, UInt32), s, sizeof(s), h % UInt32) + h
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

# ryu.jl
@inline @unchecked function reduce_shortest(f::T, maxsignif=nothing) where {T}
    U = uinttype(T)
    uf = reinterpret(U, f)
    m = uf & significand_mask(T)
    e = ((uf & exponent_mask(T)) >> significand_bits(T)) % Int

    ## Step 1
    #  mf * 2^ef == f
    mf = (one(U) << significand_bits(T)) | m
    ef = e - exponent_bias(T) - significand_bits(T)
    f_isinteger = mf & ((one(U) << -ef) - one(U)) == 0

    if ef > 0 || ef < -Base.significand_bits(T) || !f_isinteger
        # fixup subnormals
        if e == 0
            ef = 1 - exponent_bias(T) - significand_bits(T)
            mf = m
        end

        ## Step 2
        #  u * 2^e2 == (f + prevfloat(f))/2
        #  v * 2^e2 == f
        #  w * 2^e2 == (f + nextfloat(f))/2
        e2 = ef - 2
        mf_iseven = iseven(mf) # trailing bit of significand is zero

        v = U(4) * mf
        w = v + U(2)
        u_shift_half = m == 0 && e > 1 # if first element of binade, other than first normal one
        u = v - U(2) + u_shift_half

        ## Step 3
        #  a == floor(u * 2^e2 / 10^e10), exact if a_allzero
        #  b == floor(v * 2^e2 / 10^e10), exact if b_allzero
        #  c == floor(w * 2^e2 / 10^e10)
        a_allzero = false
        b_allzero = false
        b_lastdigit = 0x00
        if e2 >= 0
            q = log10pow2(e2) - (T == Float64 ? (e2 > 3) : 0)
            e10 = q
            k = pow5_inv_bitcount(T) + pow5bits(q) - 1
            i = -e2 + q + k
            a, b, c = mulshiftinvsplit(T, u, v, w, q, i)
            if T == Float32 || T == Float16
                if q != 0 && div(c - 1, 10) <= div(a, 10)
                    l = pow5_inv_bitcount(T) + pow5bits(q - 1) - 1
                    mul = pow5invsplit_lookup(T, q-1)
                    b_lastdigit = (mulshift(v, mul, -e2 + q - 1 + l) % 10) % UInt8
                end
            end
            if q <= qinvbound(T)
                if ((v % UInt32) - 5 * div(v, 5)) == 0
                    b_allzero = pow5(v, q)
                elseif mf_iseven
                    a_allzero = pow5(u, q)
                else
                    c -= pow5(w, q)
                end
            end
        else
            q = log10pow5(-e2) - (T == Float64 ? (-e2 > 1) : 0)
            e10 = q + e2
            i = -e2 - q
            k = pow5bits(i) - pow5_bitcount(T)
            j = q - k
            a, b, c = mulshiftsplit(T, u, v, w, i, j)
            if T == Float32 || T == Float16
                if q != 0 && div(c - 1, 10) <= div(a, 10)
                    j = q - 1 - (pow5bits(i + 1) - pow5_bitcount(T))
                    mul = pow5split_lookup(T, i+1)
                    b_lastdigit = (mulshift(v, mul, j) % 10) % UInt8
                end
            end
            if q <= 1
                b_allzero = true
                if mf_iseven
                    a_allzero = !u_shift_half
                else
                    c -= 1
                end
            elseif q < qbound(T)
                b_allzero = pow2(v, q - (T != Float64))
            end
        end

        ## Step 4: reduction
        if a_allzero || b_allzero
            # a) slow loop
            while true
                c_div10 = div(c, 10)
                a_div10 = div(a, 10)
                if c_div10 <= a_div10
                    break
                end
                a_mod10 = (a % UInt32) - UInt32(10) * (a_div10 % UInt32)
                b_div10 = div(b, 10)
                b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
                a_allzero &= a_mod10 == 0
                b_allzero &= b_lastdigit == 0
                b_lastdigit = b_mod10 % UInt8
                b = b_div10
                c = c_div10
                a = a_div10
                e10 += 1
            end
            if a_allzero
                while true
                    a_div10 = div(a, 10)
                    a_mod10 = (a % UInt32) - UInt32(10) * (a_div10 % UInt32)
                    if a_mod10 != 0 && (maxsignif === nothing || b < maxsignif)
                        break
                    end
                    c_div10 = div(c, 10)
                    b_div10 = div(b, 10)
                    b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
                    b_allzero &= b_lastdigit == 0
                    b_lastdigit = b_mod10 % UInt8
                    b = b_div10
                    c = c_div10
                    a = a_div10
                    e10 += 1
                end
            end
            if b_allzero && b_lastdigit == 5 && iseven(b)
                b_lastdigit = UInt8(4)
            end
            roundup = (b == a && (!mf_iseven || !a_allzero)) || b_lastdigit >= 5
        else
            # b) specialized for common case (99% Float64, 96% Float32)
            roundup = b_lastdigit >= 5
            c_div100 = div(c, 100)
            a_div100 = div(a, 100)
            if c_div100 > a_div100
                b_div100 = div(b, 100)
                b_mod100 = (b % UInt32) - UInt32(100) * (b_div100 % UInt32)
                roundup = b_mod100 >= 50
                b = b_div100
                c = c_div100
                a = a_div100
                e10 += 2
            end
            while true
                c_div10 = div(c, 10)
                a_div10 = div(a, 10)
                if c_div10 <= a_div10
                    break
                end
                b_div10 = div(b, 10)
                b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
                roundup = b_mod10 >= 5
                b = b_div10
                c = c_div10
                a = a_div10
                e10 += 1
            end
            roundup = (b == a || roundup)
        end
        if maxsignif !== nothing && b > maxsignif
            # reduce to max significant digits
            while true
                b_div10 = div(b, 10)
                b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
                if b <= maxsignif
                    break
                end
                b = b_div10
                roundup = (b_allzero && iseven(b)) ? b_mod10 > 5 : b_mod10 >= 5
                b_allzero &= b_mod10 == 0
                e10 += 1
            end
            b = b + roundup

            # remove trailing zeros
            while true
                b_div10 = div(b, 10)
                b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
                if b_mod10 != 0
                    break
                end
                b = b_div10
                e10 += 1
            end
        else
            b = b + roundup
        end
    else
        # c) specialized f an integer < 2^53
        b = mf >> -ef
        e10 = 0

        if maxsignif !== nothing && b > maxsignif
            b_allzero = true
            # reduce to max significant digits
            while true
                b_div10 = div(b, 10)
                b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
                if b <= maxsignif
                    break
                end
                b = b_div10
                roundup = (b_allzero && iseven(b)) ? b_mod10 > 5 : b_mod10 >= 5
                b_allzero &= b_mod10 == 0
                e10 += 1
            end
            b = b + roundup
        end
        while true
            b_div10 = div(b, 10)
            b_mod10 = (b % UInt32) - UInt32(10) * (b_div10 % UInt32)
            if b_mod10 != 0
                break
            end
            b = b_div10
            e10 += 1
        end
    end
    return b, e10
end

@unchecked function writeshortest(buf::Vector{UInt8}, pos, x::T,
                       plus=false, space=false, hash=true,
                       precision=-1, expchar=UInt8('e'), padexp=false, decchar=UInt8('.'),
                       typed=false, compact=false) where {T}
    @assert 0 < pos <= length(buf)
    # special cases
    if x == 0
        if typed && x isa Float16
            buf[pos] = UInt8('F')
            buf[pos + 1] = UInt8('l')
            buf[pos + 2] = UInt8('o')
            buf[pos + 3] = UInt8('a')
            buf[pos + 4] = UInt8('t')
            buf[pos + 5] = UInt8('1')
            buf[pos + 6] = UInt8('6')
            buf[pos + 7] = UInt8('(')
            pos += 8
        end
        pos = append_sign(x, plus, space, buf, pos)
        buf[pos] = UInt8('0')
        pos += 1
        if hash
            buf[pos] = decchar
            pos += 1
        end
        if precision == -1
            buf[pos] = UInt8('0')
            pos += 1
            if typed && x isa Float32
                buf[pos] = UInt8('f')
                buf[pos + 1] = UInt8('0')
                pos += 2
            end
            if typed && x isa Float16
                buf[pos] = UInt8(')')
                pos += 1
            end
            return pos
        end
        while hash && precision > 1
            buf[pos] = UInt8('0')
            pos += 1
            precision -= 1
        end
        if typed && x isa Float32
            buf[pos] = UInt8('f')
            buf[pos + 1] = UInt8('0')
            pos += 2
        end
        if typed && x isa Float16
            buf[pos] = UInt8(')')
            pos += 1
        end
        return pos
    elseif isnan(x)
        pos = append_sign(x, plus, space, buf, pos)
        buf[pos] = UInt8('N')
        buf[pos + 1] = UInt8('a')
        buf[pos + 2] = UInt8('N')
        if typed
            if x isa Float32
                buf[pos + 3] = UInt8('3')
                buf[pos + 4] = UInt8('2')
            elseif x isa Float16
                buf[pos + 3] = UInt8('1')
                buf[pos + 4] = UInt8('6')
            end
        end
        return pos + 3 + (typed && x isa Union{Float32, Float16} ? 2 : 0)
    elseif !isfinite(x)
        pos = append_sign(x, plus, space, buf, pos)
        buf[pos] = UInt8('I')
        buf[pos + 1] = UInt8('n')
        buf[pos + 2] = UInt8('f')
        if typed
            if x isa Float32
                buf[pos + 3] = UInt8('3')
                buf[pos + 4] = UInt8('2')
            elseif x isa Float16
                buf[pos + 3] = UInt8('1')
                buf[pos + 4] = UInt8('6')
            end
        end
        return pos + 3 + (typed && x isa Union{Float32, Float16} ? 2 : 0)
    end

    output, nexp = reduce_shortest(x, compact ? 999_999 : nothing)

    if typed && x isa Float16
        buf[pos] = UInt8('F')
        buf[pos + 1] = UInt8('l')
        buf[pos + 2] = UInt8('o')
        buf[pos + 3] = UInt8('a')
        buf[pos + 4] = UInt8('t')
        buf[pos + 5] = UInt8('1')
        buf[pos + 6] = UInt8('6')
        buf[pos + 7] = UInt8('(')
        pos += 8
    end
    pos = append_sign(x, plus, space, buf, pos)

    olength = decimallength(output)
    exp_form = true
    pt = nexp + olength
    if -4 < pt <= (precision == -1 ? (T == Float16 ? 3 : 6) : precision) &&
        !(pt >= olength && abs(mod(x + 0.05, 10^(pt - olength)) - 0.05) > 0.05)
        exp_form = false
        if pt <= 0
            buf[pos] = UInt8('0')
            pos += 1
            buf[pos] = decchar
            pos += 1
            for _ = 1:abs(pt)
                buf[pos] = UInt8('0')
                pos += 1
            end
            # elseif pt >= olength
            # nothing to do at this point
            # else
            # nothing to do at this point
        end
    else
        pos += 1
    end
    i = 0
    ptr = pointer(buf)
    ptr2 = pointer(DIGIT_TABLE)
    if (output >> 32) != 0
        q = output ÷ 100000000
        output2 = (output % UInt32) - UInt32(100000000) * (q % UInt32)
        output = q

        c = output2 % UInt32(10000)
        output2 = div(output2, UInt32(10000))
        d = output2 % UInt32(10000)
        c0 = (c % 100) << 1
        c1 = (c ÷ 100) << 1
        d0 = (d % 100) << 1
        d1 = (d ÷ 100) << 1
        memcpy(ptr, pos + olength - 2, ptr2, c0 + 1, 2)
        memcpy(ptr, pos + olength - 4, ptr2, c1 + 1, 2)
        memcpy(ptr, pos + olength - 6, ptr2, d0 + 1, 2)
        memcpy(ptr, pos + olength - 8, ptr2, d1 + 1, 2)
        i += 8
    end
    output2 = output % UInt32
    while output2 >= 10000
        c = output2 % UInt32(10000)
        output2 = div(output2, UInt32(10000))
        c0 = (c % 100) << 1
        c1 = (c ÷ 100) << 1
        memcpy(ptr, pos + olength - i - 2, ptr2, c0 + 1, 2)
        memcpy(ptr, pos + olength - i - 4, ptr2, c1 + 1, 2)
        i += 4
    end
    if output2 >= 100
        c = (output2 % UInt32(100)) << 1
        output2 = div(output2, UInt32(100))
        memcpy(ptr, pos + olength - i - 2, ptr2, c + 1, 2)
        i += 2
    end
    if output2 >= 10
        c = output2 << 1
        buf[pos + 1] = DIGIT_TABLE[c + 2]
        buf[pos - exp_form] = DIGIT_TABLE[c + 1]
    else
        buf[pos - exp_form] = UInt8('0') + (output2 % UInt8)
    end

    if !exp_form
        if pt <= 0
            pos += olength
            precision -= olength
            while hash && precision > 0
                buf[pos] = UInt8('0')
                pos += 1
                precision -= 1
            end
        elseif pt >= olength
            pos += olength
            precision -= olength
            for _ = 1:nexp
                buf[pos] = UInt8('0')
                pos += 1
                precision -= 1
            end
            if hash
                buf[pos] = decchar
                pos += 1
                if precision < 0
                    buf[pos] = UInt8('0')
                    pos += 1
                end
                while precision > 0
                    buf[pos] = UInt8('0')
                    pos += 1
                    precision -= 1
                end
            end
        else
            pointoff = olength - abs(nexp)
            memmove(ptr, pos + pointoff + 1, ptr, pos + pointoff, olength - pointoff + 1)
            buf[pos + pointoff] = decchar
            pos += olength + 1
            precision -= olength
            while hash && precision > 0
                buf[pos] = UInt8('0')
                pos += 1
                precision -= 1
            end
        end
        if typed && x isa Float32
            buf[pos] = UInt8('f')
            buf[pos + 1] = UInt8('0')
            pos += 2
        end
    else
        if olength > 1 || hash
            buf[pos] = decchar
            pos += olength
            precision -= olength
        end
        if hash && olength == 1
            buf[pos] = UInt8('0')
            pos += 1
        end
        while hash && precision > 0
            buf[pos] = UInt8('0')
            pos += 1
            precision -= 1
        end

        buf[pos] = expchar
        pos += 1
        exp2 = nexp + olength - 1
        if exp2 < 0
            buf[pos] = UInt8('-')
            pos += 1
            exp2 = -exp2
        elseif padexp
            buf[pos] = UInt8('+')
            pos += 1
        end

        if exp2 >= 100
            c = exp2 % 10
            memcpy(ptr, pos, ptr2, 2 * div(exp2, 10) + 1, 2)
            buf[pos + 2] = UInt8('0') + (c % UInt8)
            pos += 3
        elseif exp2 >= 10
            memcpy(ptr, pos, ptr2, 2 * exp2 + 1, 2)
            pos += 2
        else
            if padexp
                buf[pos] = UInt8('0')
                pos += 1
            end
            buf[pos] = UInt8('0') + (exp2 % UInt8)
            pos += 1
        end
    end
    if typed && x isa Float16
        buf[pos] = UInt8(')')
        pos += 1
    end

    return pos
end

@inline @unchecked function mulshiftmod1e9(m, mula, mulb, mulc, j)
    b0 = UInt128(m) * mula
    b1 = UInt128(m) * mulb
    b2 = UInt128(m) * mulc
    mid = b1 + ((b0 >> 64) % UInt64)
    s1 = b2 + ((mid >> 64) % UInt64)
    v = s1 >> (j - 128)
    multiplied = umul256_hi(v, 0x89705F4136B4A597, 0x31680A88F8953031)
    shifted = (multiplied >> 29) % UInt32
    return (v % UInt32) - UInt32(1000000000) * shifted
end
