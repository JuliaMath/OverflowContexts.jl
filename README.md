# OverflowContexts.jl

```
using OverflowContexts
x = 2^63 - 1 # 9223372036854775807
x  + 1 # -9223372036854775808

@checked
x + 1 # ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64
@unchecked
x + 1 # -9223372036854775808

d() = x + 1; c() = d(); b() = c(); a() = b();

a() #-9223372036854775808

@checked
a() # ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64
@unchecked

a()  # -9223372036854775808
```

It only works at top-level. I'm sure there are plenty of landmines where Julia could blow up. If you find a faulty method that depends on overflow math, make a PR with an overflow-allowed version that can be added.
