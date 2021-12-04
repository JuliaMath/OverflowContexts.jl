# OverflowContexts.jl

This package conceptually extends `CheckedArithmetic.jl` to provide the following overall features:
1. Ability to set a Module-level default to overflow-checked or overflow-permissive operations.
2. Ability to specify whether a block of code should use overflow-checked or overflow-permissive operations regardless of the default.

Together, these provide checked and unchecked contexts, as in other languages like C#:
https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/checked-and-unchecked

`@default_checked` and `@default_unchecked` create shadow copies of the `+`, `-`, `*`, and `abs` functions that redirect to overflow-checked
or overflow-permissive operations, respectively, within the module it was executed in. All non-integer arguments are passed through to their
respective Base methods.

The expression-level `@checked` and `@unchecked` rewrite instances of `+`, `-`, and `*`, and `abs` functions, to functions specific to the
checked or permissive operation, and thus are not affected by switching the default. Symbols for the functions will also be replaced, to support
calls like `foldl(+, v)`. If these macros are nested, the lowest level takes precedence so that an unchecked context can be nested inside a checked
context and vice versa.

```julia
using OverflowContexts
x = typemax(Int) # 9223372036854775807
x + 1 # -9223372036854775808

@default_checked
x + 1 # ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64

@unchecked x * 2 # -2

@unchecked begin
    x * 2 # -2
    @checked x + 1 # ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64
end

@default_unchecked
x + 1 # -9223372036854775808

d() = x + 1; c() = d(); b() = c(); a() = b();

a() #-9223372036854775808
@checked a() # doesn't cross function boundary; no OverflowError

@default_checked
a() # ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64

@unchecked a() # doesn't cross function boundary; still throws OverflowError
@default_unchecked

a()  # -9223372036854775808

# rewrite a symbol
@checked foldl(+, (typemax(Int), 1))

# assignment operators
a = typemax(Int)
@checked a += 1
```
