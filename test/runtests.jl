using Test
using OverflowContexts

@testset "checked expressions" begin
    @test_throws OverflowError @checked -typemin(Int)
    @test_throws OverflowError @checked -UInt(1)

    @test_throws OverflowError @checked typemax(Int) + 1
    @test_throws OverflowError @checked typemax(UInt) + 1
    
    @test_throws OverflowError @checked typemin(Int) - 1
    @test_throws OverflowError @checked typemin(UInt) - 1

    @test_throws OverflowError @checked typemax(Int) * 2
    @test_throws OverflowError @checked typemin(Int) * 2
    @test_throws OverflowError @checked typemax(UInt) * 2

    @test_throws OverflowError @checked typemax(Int) ^ 2
    @test_throws OverflowError @checked typemin(Int) ^ 2
    @test_throws OverflowError @checked typemax(UInt) ^ 2

    @test_throws OverflowError @checked abs(typemin(Int))
end

@testset "unchecked expressions" begin
    @test @unchecked -typemin(Int) == typemin(Int)
    @test @unchecked -UInt(1) == typemax(UInt)

    @test @unchecked typemax(Int) + 1 == typemin(Int)
    @test @unchecked typemax(UInt) + 1 == typemin(UInt)

    @test @unchecked typemin(Int) - 1 == typemax(Int)
    @test @unchecked typemin(UInt) - 1 == typemax(UInt)

    @test @unchecked typemax(Int) * 2 == -2
    @test @unchecked typemin(Int) * 2 == 0
    @test @unchecked typemax(UInt) * 2 == typemax(UInt) - 1

    @test @unchecked typemax(Int) ^ 2 == 1
    @test @unchecked typemin(Int) ^ 2 == 0
    @test @unchecked typemax(UInt) ^ 2 == UInt(1)

    @test @unchecked abs(typemin(Int)) == typemin(Int)
end

@testset "lowest-level macro takes priority" begin
    @checked begin
        @test @unchecked typemax(Int) + 1 == typemin(Int)
    end
    @unchecked begin
        @test_throws OverflowError @checked typemax(Int) + 1
    end
end

@testset "non-integer math still works" begin
    @test @checked -1.0 == -1
    @test @unchecked -1.0 == -1
    @test @checked 1.0 + 3.0 == 4.0
    @test @unchecked 1.0 + 3.0 == 4.0
    @test @checked 1 + 3.0 == 4.0
    @test @unchecked 1 + 3.0 == 4.0
    @test @checked 1.0 - 3.0 == -2.0
    @test @unchecked 1.0 - 3.0 == -2.0
    @test @checked 1 - 3.0 == -2.0
    @test @unchecked 1 - 3.0 == -2.0
    @test @checked 1.0 * 3.0 == 3.0
    @test @unchecked 1.0 * 3.0 == 3.0
    @test @checked 1 * 3.0 == 3.0
    @test @unchecked 1 * 3.0 == 3.0
    @test @checked 1.0 ^ 3.0 == 1.0
    @test @unchecked 1.0 ^ 3.0 == 1.0
    @test @checked 1 ^ 3.0 == 1.0
    @test @unchecked 1 ^ 3.0 == 1.0
    @test @checked abs(-1.0) == 1.0
    @test @unchecked abs(-1.0) == 1.0
end

@testset "symbol replacement" begin
    expr = @macroexpand @checked foldl(+, [])
    @test expr.args[2] == :checked_add

    expr = @macroexpand @unchecked foldl(+, [])
    @test expr.args[2] == :unchecked_add

    expr = @macroexpand @checked foldl(-, [])
    @test expr.args[2] == :checked_negsub

    expr = @macroexpand @unchecked foldl(-, [])
    @test expr.args[2] == :unchecked_negsub

    expr = @macroexpand @checked foldl(*, [])
    @test expr.args[2] == :checked_mul

    expr = @macroexpand @unchecked foldl(*, [])
    @test expr.args[2] == :unchecked_mul

    expr = @macroexpand @checked foldl(^, [])
    @test expr.args[2] == :checked_pow

    expr = @macroexpand @unchecked foldl(^, [])
    @test expr.args[2] == :unchecked_pow

    expr = @macroexpand @checked foldl(:abs, [])
    @test expr.args[2] == :checked_abs

    expr = @macroexpand @unchecked foldl(:abs, [])
    @test expr.args[2] == :unchecked_abs
end

@testset "negsub helper methods dispatch correctly" begin
    @test unchecked_negsub(1) == -1
    @test unchecked_negsub(1, 2) == 1 - 2
end

@testset "in-place assignement" begin
    a = typemax(Int)
    @test_throws OverflowError @checked a += 1
    @unchecked a += 1
    @test a == typemin(Int)

    a = typemin(Int)
    @test_throws OverflowError @checked a -= 1
    @unchecked a -= 1
    @test a == typemax(Int)

    a = typemax(Int)
    @test_throws OverflowError @checked a *= 2
    @unchecked a *= 2
    @test a == -2

    a = typemax(Int)
    @test_throws OverflowError @checked a ^= 2
    @unchecked a ^= 2
    @test a == 1
end

module CheckedModule
    using OverflowContexts, Test
    @default_checked
    testfunc() = @test_throws OverflowError typemax(Int) + 1

    module NestedUncheckedModule
        using OverflowContexts, Test
        @default_unchecked
        testfunc() = @test typemax(Int) + 1 == typemin(Int)
    end
end

module UncheckedModule
    using OverflowContexts, Test
    @default_unchecked
    testfunc() = @test typemax(Int) + 1 == typemin(Int)
    module NestedCheckedModule
        using OverflowContexts, Test
        @default_checked
        testfunc() = @test_throws OverflowError typemax(Int) + 1
    end
end

@testset "module-specific contexts" begin
    CheckedModule.testfunc()
    CheckedModule.NestedUncheckedModule.testfunc()
    UncheckedModule.testfunc()
    UncheckedModule.NestedCheckedModule.testfunc()
    
    # Trying to set a default after referencing the operator should error
    module BadCheckedModule
        using OverflowContexts, Test
        x = 1 + 1
        @test_throws ErrorException @default_checked
        @test -(typemin(Int)) == typemin(Int) # checked methods reversed to Base on error
    end
    module BadUncheckedModule
        using OverflowContexts, Test
        x = 1 + 1
        @test_throws ErrorException @default_unchecked
    end
end

@testset "ensure pow methods don't promote on the power" begin
    @test typeof(@unchecked 3 ^ UInt(4)) == Int
    @test typeof(@checked 3 ^ UInt(4)) == Int
end
