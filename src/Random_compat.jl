import .Random: rand, Xoshiro, SamplerType, TaskLocalRNG

@inline function rand(rng::Xoshiro, ::SamplerType{UInt64})
    s0, s1, s2, s3 = rng.s0, rng.s1, rng.s2, rng.s3
    tmp = @unchecked s0 + s3
    res = @unchecked ((tmp << 23) | (tmp >> 41)) + s0
    t = s1 << 17
    s2 = xor(s2, s0)
    s3 = xor(s3, s1)
    s1 = xor(s1, s2)
    s0 = xor(s0, s3)
    s2 = xor(s2, t)
    s3 = s3 << 45 | s3 >> 19
    rng.s0, rng.s1, rng.s2, rng.s3 = s0, s1, s2, s3
    res
end

@inline function rand(::TaskLocalRNG, ::SamplerType{UInt64})
    task = current_task()
    s0, s1, s2, s3 = task.rngState0, task.rngState1, task.rngState2, task.rngState3
    tmp = @unchecked s0 + s3
    res = @unchecked ((tmp << 23) | (tmp >> 41)) + s0
    t = s1 << 17
    s2 = xor(s2, s0)
    s3 = xor(s3, s1)
    s1 = xor(s1, s2)
    s0 = xor(s0, s3)
    s2 = xor(s2, t)
    s3 = s3 << 45 | s3 >> 19
    task.rngState0, task.rngState1, task.rngState2, task.rngState3 = s0, s1, s2, s3
    res
end
