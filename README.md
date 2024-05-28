# OverflowContexts.jl

OverflowContexts provides easy manipulation of (integer) arithmetic modes.

By default, Julia generally uses overflowing (unchecked) integer math (other than division methods), which silently wraps around from the maximum to the minimum value when it gets too large or small, respectively. This choice is because checking for overflow is slower and means that any integer arithmetic could throw an exception, which the compiler would need to account for.

With base Julia, if a user wishes to use checked arithmetic, they would need to bring in `Base.Checked` and explicitly use e.g., `checked_add(x, y)` rather than the natural operator.

Using the macros in OverflowContexts, an expression or code block can be rewritten to replace operators and certain methods (`+`, `-`, `*`, `^`, `abs`) on the fly with appropriate method calls:
```julia
@checked -typemin(Int64)
# Expands to `OverflowContexts.checked_neg(typemin(Int64))`
# Throws `ERROR: OverflowError: 0 - -9223372036854775808 overflowed for type Int64`

@checked typemax(Int64) + 1
# Expands to `OverflowContexts.checked_add(typemax(Int64), 1)`
# Throws `ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64`

@checked typemin(Int64) - 1
# Expands to `OverflowContexts.checked_sub(typemin(Int64), 1)`
# Throws `ERROR: OverflowError: -9223372036854775807 + 1 overflowed for type Int64`

@checked typemax(Int64) * 2
# Expands to `OverflowContexts.checked_mul(typemax(Int64), 2)`
# Throws `ERROR: OverflowError: 9223372036854775807 * 2 overflowed for type Int64`

@checked typemax(Int64) ^ 2
# Expands to `OverflowContexts.checked_pow(typemax(Int64), 2)`
# Throws `ERROR: OverflowError: 9223372036854775807 * 9223372036854775807overflowed for type Int64`

@checked abs(typemin(Int64))
# Expands to `OverflowContexts.checked_abs(typemin(Int64))`
# Throws `ERROR: OverflowError: checked arithmetic: cannot compute |x| for x = -9223372036854775808::Int64`
```

Code blocks can also be nested, with the innermost block taking priority:
```julia
@checked begin
    @unchecked typemax(Int64) * 2
end
# Expands to `OverflowContexts.unchecked_mul(typemax(Int64), 2)`
# Evaluates to `-2`
```

This package also adds a saturating mode, where values accumulate at the maximum and minimum for the type:
```julia
@saturating -typemin(Int64)
# Expands to `OverflowContexts.saturating_neg(typemin(Int64))`
# Evaluates to `typemax(Int64)`

@saturating typemax(Int64) + 1
# Expands to `OverflowContexts.saturating_add(typemax(Int64), 1)`
# Evaluates to `typemax(Int64)`

@saturating typemin(Int64) - 1
# Expands to `OverflowContexts.saturating_sub(typemin(Int64), 1)`
# Evaluates to `typemin(Int64)`

@saturating typemax(Int64) * 2
# Expands to `OverflowContexts.saturating_mul(typemax(Int64), 2)`
# Evaluates to `typemax(Int64)`

@saturating typemax(Int64) ^ 2
# Expands to `OverflowContexts.saturating_pow(typemax(Int64), 2)`
# Evaluates to `typemax(Int64)`

@saturating abs(typemin(Int64))
# Expands to `OverflowContexts.checked_abs(typemin(Int64))`
# Throws `ERROR: OverflowError: checked arithmetic: cannot compute |x| for x = -9223372036854775808::Int64`
```

Broadcasted operators/methods and elementwise array operators, and assignment operators are also rewritten:
```julia
@checked .-fill(typemin(Int64), 2)
# Expands to `OverflowContexts.checked_neg.(fill(typemin(Int64), 2))`
# Throws `ERROR: OverflowError: 0 - -9223372036854775808 overflowed for type Int64`

@checked fill(typemax(Int64), 2) + fill(1, 2)
# Expands to `OverflowContexts.checked_add(fill(typemax(Int64), 2), fill(1, 2))`
# Throws `ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64`

a = fill(1, 2)
@saturating a += fill(typemax(Int64), 2)
# Expands to `a = OverflowContexts.saturating_add(a, fill(typemax(Int64), 2))`
# Evaluates to `[typemax(Int64), typemax(Int64)]`
```

Functions passed as an argument are also rewritten:
```julia
@saturating map(-, fill(typemin(Int64), 2))
# Expands to `map(OverflowContexts.saturating_neg, fill(typemin(Int64), 2))`
# Evaluates to `[typemax(Int64), typemax(Int64)]`
```

Division-related operators and methods (`÷`, `div`, `fld`, `cld`, `%`, `rem`, `mod`), in contrast, are checked by default in Julia. This is primarily because the LLVM compiler deems division by 0, or `-typemin(T) ÷ -one(T)` to be undefined behavior. Also, integer division on CPUs are generally quite slow and so this choice doesn't make much difference for performance. This package provides unchecked and saturating variants of these methods. The main benefit of the unchecked methods is that they are guaranteed to not throw an exception, however the result of a bad division should not be relied on. The saturating variant defines division by zero by treating `typemin(T)` and `typemax(T)` as saturating towards infinity, and returning `0` for `0 ÷ 0`. The saturating remainder methods produce complementary values.

Julia has a more complex `div` API than is supported here (e.g. supporting rounding modes) but this package just covers the two-argument methods available inside `Base.Checked`.

If you are writing a module and desire to set the default type of arithemtic for the module, place e.g., `@default_unchecked`, `@default_checked`, `@default_saturating` at the top of the module. This macro defines module-local copies of all of the supported arithemtic operators and methods, mapping them to the appropriate `checked_` or `saturating_` methods. The defaults do not affect anything inside the expression/block-level macros. These defaults may also be used on the REPL to switch between modes, although keep in mind that it will also cause previous methods defined on the REPL (in the `Main` module) to be recompiled with the new default.
```julia
module Foo
    using OverflowContexts
    @default_checked
    bar(x, y) = x + y
    baz(x, y) = @saturating x + y
end
Foo.bar(typemax(Int64), 1)
# Throws `ERROR: OverflowError: 9223372036854775807 + 1 overflowed for type Int64`
Foo.baz(typemax(Int64), 1)
# Returns `typemax(Int64)`
```

If you are implementing your own `Number` types, this package should just work for you so long as you extend the Base operators and the Base.Checked `checked_` methods. For `saturating_`, your package will need to either take OverflowContexts as a dependency or a weak dependency in order to import the `saturating_` methods, until/unless Julia implements them directly.

## Related Packages

* [CheckedArithmetic.jl](https://github.com/JuliaMath/CheckedArithmetic.jl) - Predescessor to this package with more limited functionality, but also provides a utility to promote types for safer accumulators.
* [SaferIntegers.jl](https://github.com/JeffreySarnoff/SaferIntegers.jl) - Uses the type system to enforce overflow checking even in code you don't control. OverflowContexts does not override this behavior, so they can work together well.
