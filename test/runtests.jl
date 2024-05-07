using OverflowContexts
using Test

@test isempty(detect_ambiguities(OverflowContexts, Base, Core))

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
    @test @unchecked(-typemin(Int)) == typemin(Int)
    @test @unchecked(-UInt(1)) == typemax(UInt)

    @test @unchecked(typemax(Int) + 1) == typemin(Int)
    @test @unchecked(typemax(UInt) + 1) == typemin(UInt)

    @test @unchecked(typemin(Int) - 1) == typemax(Int)
    @test @unchecked(typemin(UInt) - 1) == typemax(UInt)

    @test @unchecked(typemax(Int) * 2) == -2
    @test @unchecked(typemin(Int) * 2) == 0
    @test @unchecked(typemax(UInt) * 2) == typemax(UInt) - 1

    @test @unchecked(typemax(Int) ^ 2) == 1
    @test @unchecked(typemin(Int) ^ 2) == 0
    @test @unchecked(typemax(UInt) ^ 2) == UInt(1)

    @test @unchecked(abs(typemin(Int))) == typemin(Int)
end

@testset "juxtaposed multiplication works" begin
    @test_throws OverflowError @checked 2typemax(Int)
    @test_throws OverflowError @checked 2typemin(Int)
    @test_throws OverflowError @checked 2typemax(UInt)
    @test @unchecked(2typemax(Int)) == -2
    @test @unchecked(2typemin(Int)) == 0
    @test @unchecked(2typemax(UInt)) == typemax(UInt) - 1
end

@testset "exhaustive checks over 16 bit math" begin
    for T ∈ (Int16, UInt16)
        if T <: Signed
            @testset "$T negation" begin
                for i ∈ typemin(T) + T(1):typemax(T)
                    @test @checked(-i) == @unchecked(-i) == -i
                end
            end
        end
        @testset "$T addition" begin
            for i ∈ typemin(T):typemax(T) - T(1)
                @test @checked(i + T(1)) == @unchecked(i + T(1)) == i + T(1)
            end
        end
        @testset "$T subtraction" begin
            for i ∈ typemin(T) + T(1):typemax(T)
                @test @checked(i - T(1)) == @unchecked(i - T(1)) == i - T(1)
            end
        end
        @testset "$T multiplication" begin
            for i ∈ typemin(T) ÷ T(2):typemax(T) ÷ T(2)
                @test @checked(2i) == @unchecked(2i) == 2i
            end
        end
        @testset "$T power" begin
            if T <: Signed
                for i ∈ ceil(T, -√(typemax(T))):floor(T, √(typemax(T)))
                    @test @checked(i ^ 2) == @unchecked(i ^ 2) == i ^ 2
                end
            else
                for i ∈ T(0):floor(T, √(typemax(T)))
                    @test @checked(i ^ 2) == @unchecked(i ^ 2) == i ^ 2
                end
            end
        end
        @testset "$T abs" begin
            for i ∈ typemin(T) + T(1):typemax(T)
                @test @checked(abs(i)) == @unchecked(abs(i)) == abs(i)
            end
        end
    end
end

@testset "lowest-level macro takes priority" begin
    @checked begin
        @test @unchecked(typemax(Int) + 1) == typemin(Int)
    end
    @unchecked begin
        @test_throws OverflowError @checked typemax(Int) + 1
    end
end

@testset "literals passthrough" begin
    @test @checked(-1) == -1
    @test @unchecked(-1) == -1
end

@testset "non-integer math still works" begin
    @test @checked(-1.0) == -1
    @test @unchecked(-1.0) == -1
    @test @checked(1.0 + 3.0) == 4.0
    @test @unchecked(1.0 + 3.0) == 4.0
    @test @checked(1 + 3.0) == 4.0
    @test @unchecked(1 + 3.0) == 4.0
    @test @checked(1.0 - 3.0) == -2.0
    @test @unchecked(1.0 - 3.0) == -2.0
    @test @checked(1 - 3.0) == -2.0
    @test @unchecked(1 - 3.0) == -2.0
    @test @checked(1.0 * 3.0) == 3.0
    @test @unchecked(1.0 * 3.0) == 3.0
    @test @checked(1 * 3.0) == 3.0
    @test @unchecked(1 * 3.0) == 3.0
    @test @checked(1.0 ^ 3.0) == 1.0
    @test @unchecked(1.0 ^ 3.0) == 1.0
    @test @checked(1 ^ 3.0) == 1.0
    @test @unchecked(1 ^ 3.0) == 1.0
    @test @checked(abs(-1.0)) == 1.0
    @test @unchecked(abs(-1.0)) == 1.0
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

@testset "assignment operators" begin
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

@checked begin
    checkplus(x, y) = x + y
    checkminus(x, y) = x - y
end

@testset "rewrite inside block body" begin
    @test checkplus(0x10, 0x20) === 0x30
    @test_throws OverflowError checkplus(0xf0, 0x20)
    @test checkminus(0x30, 0x20) === 0x10
    @test_throws OverflowError checkminus(0x20, 0x30)
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
end

@testset "default methods error if Base symbol already resolved" begin
    x = 1 + 1
    @test_throws ErrorException @default_checked
    @test_throws ErrorException @default_unchecked
    
    (@__MODULE__).eval(:(
        module BadCheckedModule
            using OverflowContexts, Test
            x = 1 + 1
            @test_throws ErrorException @default_checked
        end))

    (@__MODULE__).eval(:(
        module BadUncheckedModule
            using OverflowContexts, Test
            x = 1 + 1
            @test_throws ErrorException @default_unchecked
        end))
end

@testset "default methods warn if default is changed" begin    
    (@__MODULE__).eval(:(
        module WarnOnDefaultChangedCheckedModule
            using OverflowContexts, Test
            @default_unchecked
            @test_logs (:warn, "A previous default was set for this module. Previously defined methods in this module will be recompiled with this new default.") @default_checked
        end))
    
    (@__MODULE__).eval(:(
        module WarnOnDefaultChangedUncheckedModule
            using OverflowContexts, Test
            @default_unchecked
            @test_logs (:warn, "A previous default was set for this module. Previously defined methods in this module will be recompiled with this new default.") @default_checked
        end))
end

@testset "ensure pow methods don't promote on the power" begin
    @test typeof(@unchecked 3 ^ UInt(4)) == Int
    @test typeof(@checked 3 ^ UInt(4)) == Int
end

@testset "multiargument methods" begin
    @test @checked(1 + 4 + 5) == 10
    @test_throws OverflowError @checked(typemax(Int) + 1 + 4 + 5)
    @test_throws OverflowError @checked(1 + 4 + 5 + typemax(Int))
    @test @checked(1.0 + 4 + 5 + typemax(Int)) == 9.223372036854776e18
    
    @test @unchecked(1 + 4 + 5) == 10
    @test @unchecked(typemax(Int) + 1 + 4 + 5) == 10 + typemax(Int)
    @test @unchecked(1 + 4 + 5 + typemax(Int)) == 10 + typemax(Int)
    @test @checked(1.0 + 4 + 5 + typemax(Int)) == 9.223372036854776e18
end
