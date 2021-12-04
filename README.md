# OverflowContexts.jl

This package conceptually extends `CheckedArithmetic.jl` to provide the following overall features:
1. Ability to set the global default to overflow-checked or overflow-permissive operations.
2. Ability to specify whether a block of code should use overflow-checked or overflow-permissive operations regardless of the default.

Together, these provide checked and unchecked contexts, as in other languages like C#:
https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/checked-and-unchecked

It's important to know how these interact with Julia. When you set a default through `@default_checked` and `@default_unchecked`, the function definitions
for the `+`, `-`, and `*` operators, and `abs` function, are being redirected. As those methods are new, all methods that are eligible for being recompiled will do so to
incorporate the new method definitions. Some methods may not be recompiled, and may not adopt the new methods. This may also cause a long delay when running
code the first time after these are set. Thus, I recommended that you only rarely change the default context.

The expression-level `@checked` and `@unchecked` work by rewriting the `+`, `-`, and `*` operators to methods specific to the checked or permissive operation,
and thus are not affected by switching the default.

**NOTE:** If you set `@default_checked`, some operations that expect the Julia default of unchecked arithmetic may not work. Particularly hash functions.
I've included here a number of such core Julia functions and applied the `@unchecked` macro to them so that they still work. If you encouter an error in
Julia running in a checked context, please report it as an Issue to this repository so the function can be included here. If the error is in a package,
you may need to provide your own patch locally. Unless it is a commonly used package, in which case I can conditionally load it here.

Ideally, if this model were to be adopted by Julia itself, such packages could be updated to include functions annotated with `@unchecked` for compatibility
with the default set to do overflow checking.

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
```
