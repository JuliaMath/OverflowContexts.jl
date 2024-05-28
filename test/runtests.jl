using OverflowContexts
using OverflowContexts: checked_neg, checked_add, checked_sub, checked_mul, checked_pow, checked_negsub, checked_abs,
    unchecked_neg, unchecked_add, unchecked_sub, unchecked_mul, unchecked_negsub, unchecked_pow, unchecked_abs,
    saturating_neg, saturating_add, saturating_sub, saturating_mul, saturating_pow, saturating_negsub, saturating_abs
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

@testset "saturating expressions" begin
    @test @saturating(-typemin(Int)) == typemax(Int)
    @test @saturating(-UInt(1)) == typemin(UInt)

    @test @saturating(typemax(Int) + 1) == typemax(Int)
    @test @saturating(typemax(UInt) + 1) == typemax(UInt)

    @test @saturating(typemin(Int) - 1) == typemin(Int)
    @test @saturating(typemin(UInt) - 1) == typemin(UInt)

    @test @saturating(typemax(Int) * 2) == typemax(Int)
    @test @saturating(typemin(Int) * 2) == typemin(Int)
    @test @saturating(typemax(UInt) * 2) == typemax(UInt)

    @test @saturating(typemax(Int) ^ 2) == typemax(Int)
    @test @saturating(typemin(Int) ^ 2) == typemax(Int)
    @test @saturating(typemax(UInt) ^ 2) == typemax(UInt)

    @test @saturating(abs(typemin(Int))) == typemax(Int)
end

@testset "juxtaposed multiplication works" begin
    @test_throws OverflowError @checked 2typemax(Int)
    @test_throws OverflowError @checked 2typemin(Int)
    @test_throws OverflowError @checked 2typemax(UInt)
    @test @unchecked(2typemax(Int)) == -2
    @test @unchecked(2typemin(Int)) == 0
    @test @unchecked(2typemax(UInt)) == typemax(UInt) - 1
    @test @saturating(2typemax(Int)) == typemax(Int)
    @test @saturating(2typemin(Int)) == typemin(Int)
    @test @saturating(2typemax(UInt)) == typemax(UInt)
end

@testset "division methods" begin
    @test_throws DivideError @checked typemin(Int) ÷ -1
    @test_throws DivideError @checked -2 ÷ 0
    @test_throws DivideError @checked 0 ÷ 0
    @test_throws DivideError @checked 2 ÷ 0
    @test_throws DivideError @checked 0x00 ÷ 0x00
    @test_throws DivideError @checked 0x02 ÷ 0x00

    @test @unchecked(typemin(Int) ÷ -1) == typemin(Int)
    @test @unchecked(-2 ÷ 0) == 0
    @test @unchecked(0 ÷ 0) == 0
    @test @unchecked(2 ÷ 0) == 0
    @test @unchecked(UInt(0) ÷ UInt(0)) == 0x00
    @test @unchecked(UInt(2) ÷ UInt(0)) == 0x00

    @test @saturating(typemin(Int) ÷ -1) == typemax(Int)
    @test @saturating(-2 ÷ 0) == typemin(Int)
    @test @saturating(0 ÷ 0) == 0
    @test @saturating(2 ÷ 0) == typemax(Int)
    @test @saturating(UInt(0) ÷ UInt(0)) == UInt(0)
    @test @saturating(UInt(2) ÷ UInt(0)) == typemax(UInt)


    @test_throws DivideError @checked div(typemin(Int), -1)
    @test_throws DivideError @checked div(-2, 0)
    @test_throws DivideError @checked div(0, 0)
    @test_throws DivideError @checked div(2, 0)
    @test_throws DivideError @checked div(0x00, 0x00)
    @test_throws DivideError @checked div(0x02, 0x00)

    @test @unchecked(div(typemin(Int), -1)) == typemin(Int)
    @test @unchecked(div(-2, 0)) == 0
    @test @unchecked(div(0, 0)) == 0
    @test @unchecked(div(2, 0)) == 0
    @test @unchecked(div(UInt(0), UInt(0))) == 0x00
    @test @unchecked(div(UInt(2), UInt(0))) == 0x00

    @test @saturating(div(typemin(Int), -1)) == typemax(Int)
    @test @saturating(div(-2, 0)) == typemin(Int)
    @test @saturating(div(0, 0)) == 0
    @test @saturating(div(2, 0)) == typemax(Int)
    @test @saturating(div(UInt(0), UInt(0))) == UInt(0)
    @test @saturating(div(UInt(2), UInt(0))) == typemax(UInt)


    @test_throws DivideError @checked fld(typemin(Int), -1)
    @test_throws DivideError @checked fld(-2, 0)
    @test_throws DivideError @checked fld(0, 0)
    @test_throws DivideError @checked fld(2, 0)
    @test_throws DivideError @checked fld(0x00, 0x00)
    @test_throws DivideError @checked fld(0x02, 0x00)

    @test @unchecked(fld(typemin(Int), -1)) == typemin(Int)
    @test @unchecked(fld(-2, 0)) == 0
    @test @unchecked(fld(0, 0)) == 0
    @test @unchecked(fld(2, 0)) == 0
    @test @unchecked(fld(UInt(0), UInt(0))) == 0x00
    @test @unchecked(fld(UInt(2), UInt(0))) == 0x00

    @test @saturating(fld(typemin(Int), -1)) == typemax(Int)
    @test @saturating(fld(-2, 0)) == typemin(Int)
    @test @saturating(fld(0, 0)) == 0
    @test @saturating(fld(2, 0)) == typemax(Int)
    @test @saturating(fld(UInt(0), UInt(0))) == UInt(0)
    @test @saturating(fld(UInt(2), UInt(0))) == typemax(UInt)


    @test_throws DivideError @checked cld(typemin(Int), -1)
    @test_throws DivideError @checked cld(-2, 0)
    @test_throws DivideError @checked cld(0, 0)
    @test_throws DivideError @checked cld(2, 0)
    @test_throws DivideError @checked cld(0x00, 0x00)
    @test_throws DivideError @checked cld(0x02, 0x00)

    @test @unchecked(cld(typemin(Int), -1)) == typemin(Int)
    @test @unchecked(cld(-2, 0)) == 0
    @test @unchecked(cld(0, 0)) == 0
    @test @unchecked(cld(2, 0)) == 0
    @test @unchecked(cld(UInt(0), UInt(0))) == 0x00
    @test @unchecked(cld(UInt(2), UInt(0))) == 0x00

    @test @saturating(cld(typemin(Int), -1)) == typemax(Int)
    @test @saturating(cld(-2, 0)) == typemin(Int)
    @test @saturating(cld(0, 0)) == 0
    @test @saturating(cld(2, 0)) == typemax(Int)
    @test @saturating(cld(UInt(0), UInt(0))) == UInt(0)
    @test @saturating(cld(UInt(2), UInt(0))) == typemax(UInt)


    @test @checked(typemin(Int) % -1) == 0 # The intrinsic provides the correct result rather than erroring
    @test_throws DivideError @checked -2 % 0
    @test_throws DivideError @checked 0 % 0
    @test_throws DivideError @checked 2 % 0
    @test_throws DivideError @checked 0x00 % 0x00
    @test_throws DivideError @checked 0x02 % 0x00

    @test @unchecked(typemin(Int) % -1) == 0
    @test @unchecked(-2 % 0) == -2
    @test @unchecked(0 % 0) == 0
    @test @unchecked(2 % 0) == 2
    @test @unchecked(UInt(0) % UInt(0)) == 0x00
    @test @unchecked(UInt(2) % UInt(0)) == 0x02

    @test @saturating(typemin(Int) % -1) == 0
    @test @saturating(-2 % 0) == 0
    @test @saturating(0 % 0) == 0
    @test @saturating(2 % 0) == 0
    @test @saturating(UInt(0) % UInt(0)) == 0x00
    @test @saturating(UInt(2) % UInt(0)) == 0x00


    @test @checked(rem(typemin(Int), -1)) == 0
    @test_throws DivideError @checked rem(-2, 0)
    @test_throws DivideError @checked rem(0, 0)
    @test_throws DivideError @checked rem(2, 0)
    @test_throws DivideError @checked rem(0x00, 0x00)
    @test_throws DivideError @checked rem(0x02, 0x00)

    @test @unchecked(rem(typemin(Int), -1)) == 0
    @test @unchecked(rem(-2, 0)) == -2
    @test @unchecked(rem(0, 0)) == 0
    @test @unchecked(rem(2, 0)) == 2
    @test @unchecked(rem(UInt(0), UInt(0))) == 0x00
    @test @unchecked(rem(UInt(2), UInt(0))) == 0x02

    @test @saturating(rem(typemin(Int), -1)) == 0
    @test @saturating(rem(-2, 0)) == 0
    @test @saturating(rem(0, 0)) == 0
    @test @saturating(rem(2, 0)) == 0
    @test @saturating(rem(UInt(0), UInt(0))) == 0x00
    @test @saturating(rem(UInt(2), UInt(0))) == 0x00


    @test @checked(mod(typemin(Int), -1)) == 0
    @test_throws DivideError @checked mod(-2, 0)
    @test_throws DivideError @checked mod(0, 0)
    @test_throws DivideError @checked mod(2, 0)
    @test_throws DivideError @checked mod(0x00, 0x00)
    @test_throws DivideError @checked mod(0x02, 0x00)

    @test @unchecked(mod(typemin(Int), -1)) == 0
    @test @unchecked(mod(-2, 0)) == -2
    @test @unchecked(mod(0, 0)) == 0
    @test @unchecked(mod(2, 0)) == 2
    @test @unchecked(mod(UInt(0), UInt(0))) == 0x00
    @test @unchecked(mod(UInt(2), UInt(0))) == 0x02

    @test @saturating(mod(typemin(Int), -1)) == 0
    @test @saturating(mod(-2, 0)) == 0
    @test @saturating(mod(0, 0)) == 0
    @test @saturating(mod(2, 0)) == 0
    @test @saturating(mod(UInt(0), UInt(0))) == 0x00
    @test @saturating(mod(UInt(2), UInt(0))) == 0x00
end

@testset "exhaustive checks over 16 bit math" begin
    for T ∈ (Int16, UInt16)
        if T <: Signed
            @testset "$T negation" begin
                for i ∈ typemin(T) + T(1):typemax(T)
                    @test @checked(-i) == @unchecked(-i) == @saturating(-i) == -i
                end
            end
        end
        @testset "$T addition" begin
            for i ∈ typemin(T):typemax(T) - T(1)
                @test @checked(i + T(1)) == @unchecked(i + T(1)) == @saturating(i + T(1)) == i + T(1)
            end
        end
        @testset "$T subtraction" begin
            for i ∈ typemin(T) + T(1):typemax(T)
                @test @checked(i - T(1)) == @unchecked(i - T(1)) == @saturating(i - T(1)) == i - T(1)
            end
        end
        @testset "$T multiplication" begin
            for i ∈ typemin(T) ÷ T(2):typemax(T) ÷ T(2)
                @test @checked(2i) == @unchecked(2i) == @saturating(2i) == 2i
            end
        end
        @testset "$T power" begin
            if T <: Signed
                for i ∈ ceil(T, -√(typemax(T))):floor(T, √(typemax(T)))
                    @test @checked(i ^ 2) == @unchecked(i ^ 2) == @saturating(i ^ 2) == i ^ 2
                end
            else
                for i ∈ T(0):floor(T, √(typemax(T)))
                    @test @checked(i ^ 2) == @unchecked(i ^ 2) == @saturating(i ^ 2) == i ^ 2
                end
            end
        end
        @testset "$T abs" begin
            for i ∈ typemin(T) + T(1):typemax(T)
                @test @checked(abs(i)) == @unchecked(abs(i)) == @saturating(abs(i)) == abs(i)
            end
        end
        @testset "$T div" begin
            for i ∈ typemin(T):typemax(T)
                for j ∈ (typemin(T) ÷ T(4), T(0) - T(1), typemax(T) ÷ T(4))
                    j != 0 && (T <: Unsigned || i > typemin(T) || j != -1) || continue
                    @test @checked(i ÷ j) == @unchecked(i ÷ j) == @saturating(i ÷ j) == i ÷ j
                end
            end
            for i ∈ typemin(T):typemax(T)
                for j ∈ (typemin(T) ÷ T(4), T(0) - T(1), T(0), T(1), typemax(T) ÷ T(4))
                    j != 0 && (T <: Unsigned || i > typemin(T) || j != -1) || continue
                    @test @checked(div(i, j)) == @unchecked(div(i, j)) == @saturating(div(i, j)) == div(i, j)
                end
            end
        end
        @testset "$T fld" begin
            for i ∈ typemin(T):typemax(T)
                for j ∈ (typemin(T) ÷ T(4), T(0) - T(1), T(0), T(1), typemax(T) ÷ T(4))
                    j != 0 && (T <: Unsigned || i > typemin(T) || j != -1) || continue
                    @test @checked(fld(i, j)) == @unchecked(fld(i, j)) == @saturating(fld(i, j)) == fld(i, j)
                end
            end
        end
        @testset "$T cld" begin
            for i ∈ typemin(T):typemax(T)
                for j ∈ (typemin(T) ÷ T(4), T(0) - T(1), T(0), T(1), typemax(T) ÷ T(4))
                    j != 0 && (T <: Unsigned || i > typemin(T) || j != -1) || continue
                    @test @checked(cld(i, j)) == @unchecked(cld(i, j)) == @saturating(cld(i, j)) == cld(i, j)
                end
            end
        end
        @testset "$T rem" begin
            for i ∈ typemin(T):typemax(T)
                for j ∈ (typemin(T) ÷ T(4), T(0) - T(1), T(0), T(1), typemax(T) ÷ T(4))
                    j != 0 && (T <: Unsigned || i > typemin(T) || j != -1) || continue
                    @test @checked(rem(i, j)) == @unchecked(rem(i, j)) == @saturating(rem(i, j)) == rem(i, j)
                end
            end
        end
        @testset "$T mod" begin
            for i ∈ typemin(T):typemax(T)
                for j ∈ (typemin(T) ÷ T(4), T(0) - T(1), T(0), T(1), typemax(T) ÷ T(4))
                    j != 0 && (T <: Unsigned || i > typemin(T) || j != -1) || continue
                    @test @checked(i % j) == @unchecked(i % j) == @saturating(i % j) == i % j
                end
            end
        end
    end
end

@testset "lowest-level macro takes priority" begin
    @checked begin
        @test @unchecked(typemax(Int) + 1) == typemin(Int)
        @test @saturating(typemax(Int) + 1) == typemax(Int)
    end
    @unchecked begin
        @test_throws OverflowError @checked typemax(Int) + 1
        @test @saturating(typemax(Int) + 1) == typemax(Int)
    end
    @saturating begin
        @test @unchecked(typemax(Int) + 1) == typemin(Int)
        @test_throws OverflowError @checked typemax(Int) + 1
    end
end

@testset "literals passthrough" begin
    @test @checked(-1) == -1
    @test @unchecked(-1) == -1
    @test @saturating(-1) == -1
end

@testset "non-integer math still works" begin
    @test @checked(-1.0) == -1
    @test @unchecked(-1.0) == -1
    @test @saturating(-1.0) == -1
    @test @checked(1.0 + 3.0) == 4.0
    @test @unchecked(1.0 + 3.0) == 4.0
    @test @saturating(1.0 + 3.0) == 4.0
    @test @checked(1 + 3.0) == 4.0
    @test @unchecked(1 + 3.0) == 4.0
    @test @saturating(1 + 3.0) == 4.0
    @test @checked(1.0 - 3.0) == -2.0
    @test @unchecked(1.0 - 3.0) == -2.0
    @test @saturating(1.0 - 3.0) == -2.0
    @test @checked(1 - 3.0) == -2.0
    @test @unchecked(1 - 3.0) == -2.0
    @test @saturating(1 - 3.0) == -2.0
    @test @checked(1.0 * 3.0) == 3.0
    @test @unchecked(1.0 * 3.0) == 3.0
    @test @saturating(1.0 * 3.0) == 3.0
    @test @checked(1 * 3.0) == 3.0
    @test @unchecked(1 * 3.0) == 3.0
    @test @saturating(1 * 3.0) == 3.0
    @test @checked(1.0 ^ 3.0) == 1.0
    @test @unchecked(1.0 ^ 3.0) == 1.0
    @test @saturating(1.0 ^ 3.0) == 1.0
    @test @checked(1 ^ 3.0) == 1.0
    @test @unchecked(1 ^ 3.0) == 1.0
    @test @saturating(1 ^ 3.0) == 1.0
    @test @checked(abs(-1.0)) == 1.0
    @test @unchecked(abs(-1.0)) == 1.0
    @test @saturating(abs(-1.0)) == 1.0
end

@testset "symbol replacement" begin
    expr = @macroexpand @checked foldl(-, [])
    @test expr.args[2] == :(OverflowContexts.checked_negsub)
    expr = @macroexpand @checked foldl(+, [])
    @test expr.args[2] == :(OverflowContexts.checked_add)
    expr = @macroexpand @checked foldl(*, [])
    @test expr.args[2] == :(OverflowContexts.checked_mul)
    expr = @macroexpand @checked foldl(^, [])
    @test expr.args[2] == :(OverflowContexts.checked_pow)
    expr = @macroexpand @checked foldl(÷, [])
    @test expr.args[2] == :(OverflowContexts.checked_div)
    expr = @macroexpand @checked foldl(div, [])
    @test expr.args[2] == :(OverflowContexts.checked_div)
    expr = @macroexpand @checked foldl(fld, [])
    @test expr.args[2] == :(OverflowContexts.checked_fld)
    expr = @macroexpand @checked foldl(cld, [])
    @test expr.args[2] == :(OverflowContexts.checked_cld)
    expr = @macroexpand @checked foldl(%, [])
    @test expr.args[2] == :(OverflowContexts.checked_rem)
    expr = @macroexpand @checked foldl(rem, [])
    @test expr.args[2] == :(OverflowContexts.checked_rem)
    expr = @macroexpand @checked foldl(mod, [])
    @test expr.args[2] == :(OverflowContexts.checked_mod)
    
    expr = @macroexpand @unchecked foldl(-, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_negsub)
    expr = @macroexpand @unchecked foldl(+, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_add)
    expr = @macroexpand @unchecked foldl(*, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_mul)
    expr = @macroexpand @unchecked foldl(^, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_pow)
    expr = @macroexpand @unchecked foldl(÷, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_div)
    expr = @macroexpand @unchecked foldl(div, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_div)
    expr = @macroexpand @unchecked foldl(fld, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_fld)
    expr = @macroexpand @unchecked foldl(cld, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_cld)
    expr = @macroexpand @unchecked foldl(%, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_rem)
    expr = @macroexpand @unchecked foldl(rem, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_rem)
    expr = @macroexpand @unchecked foldl(mod, [])
    @test expr.args[2] == :(OverflowContexts.unchecked_mod)

    expr = @macroexpand @saturating foldl(-, [])
    @test expr.args[2] == :(OverflowContexts.saturating_negsub)
    expr = @macroexpand @saturating foldl(+, [])
    @test expr.args[2] == :(OverflowContexts.saturating_add)
    expr = @macroexpand @saturating foldl(*, [])
    @test expr.args[2] == :(OverflowContexts.saturating_mul)
    expr = @macroexpand @saturating foldl(^, [])
    @test expr.args[2] == :(OverflowContexts.saturating_pow)
    expr = @macroexpand @saturating foldl(÷, [])
    @test expr.args[2] == :(OverflowContexts.saturating_div)
    expr = @macroexpand @saturating foldl(div, [])
    @test expr.args[2] == :(OverflowContexts.saturating_div)
    expr = @macroexpand @saturating foldl(fld, [])
    @test expr.args[2] == :(OverflowContexts.saturating_fld)
    expr = @macroexpand @saturating foldl(cld, [])
    @test expr.args[2] == :(OverflowContexts.saturating_cld)
    expr = @macroexpand @saturating foldl(%, [])
    @test expr.args[2] == :(OverflowContexts.saturating_rem)
    expr = @macroexpand @saturating foldl(rem, [])
    @test expr.args[2] == :(OverflowContexts.saturating_rem)
    expr = @macroexpand @saturating foldl(mod, [])
    @test expr.args[2] == :(OverflowContexts.saturating_mod)
end

@testset "negsub helper methods dispatch correctly" begin
    @test checked_negsub(1) == -1
    @test checked_negsub(1, 2) == 1 - 2
    @test unchecked_negsub(1) == -1
    @test unchecked_negsub(1, 2) == 1 - 2
    @test saturating_negsub(1) == -1
    @test saturating_negsub(1, 2) == 1 - 2
end

@testset "assignment operators" begin
    a = typemax(Int)
    @test_throws OverflowError @checked a += 1
    @saturating a += 1
    @test a == typemax(Int)
    @unchecked a += 1
    @test a == typemin(Int)

    a = typemin(Int)
    @test_throws OverflowError @checked a -= 1
    @saturating a -= 1
    @test a == typemin(Int)
    @unchecked a -= 1
    @test a == typemax(Int)

    a = typemax(Int)
    @test_throws OverflowError @checked a *= 2
    @saturating a *= 2
    @test a == typemax(Int)
    @unchecked a *= 2
    @test a == -2

    a = typemax(Int)
    @test_throws OverflowError @checked a ^= 2
    @saturating a ^= 2
    @test a == typemax(Int)
    @unchecked a ^= 2
    @test a == 1
end

@testset "div/rem assignment operators" begin
    a = typemin(Int)
    @test_throws DivideError @checked a ÷= -1
    @unchecked a ÷= -1
    @test a == typemin(Int)
    @saturating a ÷= -1
    @test a == typemax(Int)

    a = typemin(Int)
    @test_throws DivideError @checked a %= 0
    a = typemin(Int)
    @unchecked a %= 0
    @test a == typemin(Int)
    @saturating a %= 0
    @test a == 0
end

@checked begin
    checkplus(x, y) = x + y
    checkminus(x, y) = x - y
end

@saturating begin
    satplus(x, y) = x + y
    satminus(x, y) = x - y
end

@testset "rewrite inside block body" begin
    @test checkplus(0x10, 0x20) === 0x30
    @test_throws OverflowError checkplus(0xf0, 0x20)
    @test checkminus(0x30, 0x20) === 0x10
    @test_throws OverflowError checkminus(0x20, 0x30)
    
    @test satplus(0xf0, 0x20) === 0xff
    @test satminus(0x20, 0x30) === 0x00
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

    module NestedSaturatingModule
        using OverflowContexts, Test
        @default_saturating
        testfunc() = @test typemax(Int) + 1 == typemax(Int)
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

    module NestedSaturatingModule
        using OverflowContexts, Test
        @default_saturating
        testfunc() = @test typemax(Int) + 1 == typemax(Int)
    end
end

module SaturatingModule
    using OverflowContexts, Test
    @default_saturating
    testfunc() = @test typemax(Int) + 1 == typemax(Int)

    module NestedCheckedModule
        using OverflowContexts, Test
        @default_checked
        testfunc() = @test_throws OverflowError typemax(Int) + 1
    end

    module NestedUncheckedModule
        using OverflowContexts, Test
        @default_unchecked
        testfunc() = @test typemax(Int) + 1 == typemin(Int)
    end
end

@testset "module-specific contexts" begin
    CheckedModule.testfunc()
    CheckedModule.NestedUncheckedModule.testfunc()
    CheckedModule.NestedSaturatingModule.testfunc()
    UncheckedModule.testfunc()
    UncheckedModule.NestedCheckedModule.testfunc()
    UncheckedModule.NestedSaturatingModule.testfunc()
    SaturatingModule.testfunc()
    SaturatingModule.NestedCheckedModule.testfunc()
    SaturatingModule.NestedUncheckedModule.testfunc()
end

@testset "default methods error if Base symbol already resolved" begin
    x = 1 + 1
    @test_throws ErrorException @default_checked
    @test_throws ErrorException @default_unchecked
    @test_throws ErrorException @default_saturating
    
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
    
    (@__MODULE__).eval(:(
        module BadSaturatingModule
            using OverflowContexts, Test
            x = 1 + 1
            @test_throws ErrorException @default_saturating
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
    @test typeof(@checked 3 ^ UInt(4)) == Int
    @test typeof(@unchecked 3 ^ UInt(4)) == Int
    @test typeof(@saturating 3 ^ UInt(4)) == Int
end

@testset "multiargument methods" begin
    @test @checked(+(1, 4, 5)) == 10
    @test_throws OverflowError @checked(+(typemax(Int), 1, 4, 5))
    @test_throws OverflowError @checked(+(1, 4, 5, typemax(Int)))
    @test @checked(+(1.0, 4, 5, typemax(Int))) == 9.223372036854776e18
    
    @test @unchecked(+(1, 4, 5)) == 10
    @test @unchecked(+(typemax(Int), 1, 4, 5)) == 10 + typemax(Int)
    @test @unchecked(+(1, 4, 5, typemax(Int))) == 10 + typemax(Int)
    @test @unchecked(+(1.0, 4, 5, typemax(Int))) == 9.223372036854776e18

    @test @saturating(+(1, 4, 5)) == 10
    @test @saturating(+(typemax(Int), 1, 4, 5)) == typemax(Int)
    @test @saturating(+(1, 4, 5, typemax(Int))) == typemax(Int)
    @test @saturating(+(1.0, 4, 5, typemax(Int))) == 9.223372036854776e18
end

using SaferIntegers

@testset "Ensure SaferIntegers are still safer" begin
    @test_throws OverflowError typemax(SafeInt) + 1

    @test_throws OverflowError @unchecked typemax(SafeInt) + 1
    @test_throws OverflowError @saturating typemax(SafeInt) + 1

    (@__MODULE__).eval(:(
        module UncheckedDefaultSaferIntStillChecksModule
            using OverflowContexts, SaferIntegers, Test
            @default_unchecked
            @test_throws OverflowError typemax(SafeInt) + 1
        end))
    (@__MODULE__).eval(:(
        module SaturatingDefaultSaferIntStillChecksModule
            using OverflowContexts, SaferIntegers, Test
            @default_saturating
            @test_throws OverflowError typemax(SafeInt) + 1
        end))
end

@testset "Broadcasted operators replaced" begin
    aa = fill(typemax(Int), 2)
    cc = fill(typemin(Int), 2)

    @checked(.+cc) == cc
    @test_throws OverflowError @checked(.-cc)
    @test_throws OverflowError @checked aa .+ 2
    @test_throws OverflowError @checked cc .- 2
    @test_throws OverflowError @checked aa .* 2
    @test_throws OverflowError @checked aa .^ 2
    @test_throws OverflowError @checked abs.(cc)
    @test_throws DivideError @checked aa .÷ 0
    @test_throws DivideError @checked div.(aa, 0)
    @test_throws DivideError @checked fld.(aa, 0)
    @test_throws DivideError @checked cld.(aa, 0)
    @test_throws DivideError @checked aa .% 0
    @test_throws DivideError @checked rem.(aa, 0)
    @test_throws DivideError @checked mod.(aa, 0)

    @unchecked(.+cc) == cc
    @unchecked(.-cc) == cc
    @unchecked(aa .+ 2) == fill(typemin(Int) + 1, 2)
    @unchecked(cc .- 2) == fill(typemax(Int) - 1, 2)
    @unchecked(aa .* 2) == fill(-2, 2)
    @unchecked(aa .^ 2) == fill(1, 2)
    @unchecked(abs.(cc)) == cc
    @unchecked(aa .÷ 0) == fill(0, 2)
    @unchecked(div.(aa, 0)) == fill(0, 2)
    @unchecked(fld.(aa, 0)) == fill(0, 2)
    @unchecked(cld.(aa, 0)) == fill(0, 2)
    @unchecked(aa .% 0) == fill(0, 2)
    @unchecked(rem.(aa, 0)) == fill(0, 2)
    @unchecked(mod.(aa, 0)) == fill(0, 2)

    @saturating(.+cc) == cc
    @saturating(.-cc) == aa
    @saturating(aa .+ 2) == aa
    @saturating(cc .- 2) == cc
    @saturating(aa .* 2) == aa
    @saturating(aa .^ 2) == aa
    @saturating(abs.(cc)) == aa
    @saturating(aa .÷ 0) == aa
    @saturating(div.(aa, 0)) == aa
    @saturating(fld.(aa, 0)) == aa
    @saturating(cld.(aa, 0)) == aa
    @saturating(aa .% 0) == fill(0, 2)
    @saturating(rem.(aa, 0)) == fill(0, 2)
    @saturating(mod.(aa, 0)) == fill(0, 2)
end

@testset "Broadcasted assignment operators replaced" begin
    aa = fill(typemax(Int), 2)
    cc = fill(typemin(Int), 2)
    
    @test_throws OverflowError @checked aa .+= 2
    @test_throws OverflowError @checked aa .^= 2
    @test_throws OverflowError @checked cc .-= 2
    @test_throws OverflowError @checked aa .*= 2
    @test_throws DivideError @checked aa .÷= 0

    @unchecked(copy(aa) .+= 2) == fill(typemin(Int) + 1, 2)
    @unchecked(copy(cc) .-= 2) == fill(typemax(Int) - 1, 2)
    @unchecked(copy(aa) .*= 2) == fill(-2, 2)
    @unchecked(copy(aa) .^= 2) == fill(1, 2)
    @unchecked(copy(aa) .÷= 0) == fill(0, 2)
    @unchecked(copy(aa) .%= 0) == fill(0, 2)

    @saturating(copy(aa) .+= 2) == aa
    @saturating(copy(cc) .-= 2) == cc
    @saturating(copy(aa) .*= 2) == aa
    @saturating(copy(aa) .^= 2) == aa
    @saturating(copy(aa) .÷= 0) == aa
    @saturating(copy(aa) .%= 0) == fill(0, 2)
end

@testset "Elementwise array methods are replaced, and others throw" begin
    aa = fill(typemax(Int), 2)
    bb = fill(2, 2)
    cc = fill(typemin(Int), 2)
    dd = fill(typemax(Int), 2, 2)

    @checked(+cc) == cc
    @test_throws OverflowError @checked(-cc)
    @test_throws OverflowError @checked aa + bb
    @test_throws OverflowError @checked cc - bb
    @test_throws OverflowError @checked 2aa
    @test_throws OverflowError @checked aa * 2
    @test_throws ErrorException @checked aa * bb'
    @test_throws ErrorException @checked dd ^ 2

    @unchecked(+cc) == cc
    @unchecked(-cc) == cc
    @unchecked(aa + bb) == fill(typemin(Int) + 1, 2)
    @unchecked(cc - bb) == fill(typemax(Int) - 1, 2)
    @unchecked(2aa) == fill(-2, 2)
    @unchecked(aa * 2) == fill(-2, 2)
    @unchecked(aa * bb') == fill(-2, 2, 2)
    @unchecked(dd ^ 2) == fill(2, 2, 2)

    @saturating(+cc) == cc
    @saturating(-cc) == aa
    @saturating(aa + bb) == aa
    @saturating(cc - bb) == cc
    @saturating(2aa) == aa
    @saturating(aa * 2) == aa
    @test_throws ErrorException @saturating aa * bb'
    @test_throws ErrorException @saturating dd ^ 2
end
