# OverflowContexts.jl

This package conceptually extends `CheckedArithmetic.jl` to provide the following overall features:
1. Ability to set a Module-level default to overflow-checked or overflow-permissive operations.
2. Ability to specify whether a block of code should use overflow-checked or overflow-permissive operations regardless of the default.

Together, these provide checked and unchecked contexts, as in other languages like C#:
https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/checked-and-unchecked

`@default_checked` and `@default_unchecked` create shadow copies of the `+`, `-`, `*`, `^`, and `abs` functions that redirect to overflow-checked
or overflow-permissive operations, respectively, within the module it was executed in. All non-integer arguments are passed through to their
respective Base methods. **Important:** If you wish to use this feature, the first usage of this macro must occur earlier than the first usage of the affected Base functions. This is not necessary to use the expression-level macros.

The expression-level `@checked` and `@unchecked` rewrite instances of `+`, `-`, `*`, `^`, and `abs` functions, to functions specific to the
checked or permissive operation, and thus are not affected by switching the default. Symbols for the functions will also be replaced, to support
calls like `foldl(+, v)`. If these macros are nested, the lowest level takes precedence so that an unchecked context can be nested inside a checked
context and vice versa.

```julia
using OverflowContexts
@default_unchecked # Julia default, but need to place first so later usages will work for this example

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

If you are implementing your own numeric types, this package should just work for you so long as you extend the Base operators and the Base.Checked `checked_` methods.

## Related Packages

* [CheckedArithmetic.jl](https://github.com/JuliaMath/CheckedArithmetic.jl) - Predescessor to this package with more limited functionality, but also provides a utility to promote types for safer accumulators.
* [SaferIntegers.jl](https://github.com/JeffreySarnoff/SaferIntegers.jl) - Uses the type system to
enforce overflow checking even in code you don't control.
