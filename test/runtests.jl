using Test
using OverflowContexts

for i ∈ (1, 2)
    if i == 1
        testname = "checked default"
        @default_checked
        
        @testset "$testname" begin
            @test_throws OverflowError typemax(Int) + 1
            @test_throws OverflowError typemin(Int) - 1
            @test_throws OverflowError typemax(UInt) + 1
            @test_throws OverflowError typemin(UInt) - 1

            @test_throws OverflowError typemax(Int) * 2
            @test_throws OverflowError typemin(Int) * 2
            @test_throws OverflowError typemax(UInt) * 2

            # @test_throws OverflowError typemax(Int) ^ 2
            # @test_throws OverflowError typemin(Int) ^ 2
            # @test_throws OverflowError typemax(UInt) ^ 2

            @test_throws OverflowError abs(typemin(Int))
        end
    else
        testname = "unchecked default"
        @default_unchecked

        @testset "$testname" begin
            @test typemax(Int) + 1 == typemin(Int)
            @test typemin(Int) - 1 == typemax(Int)
            @test typemax(UInt) + 1 == typemin(UInt)
            @test typemin(UInt) - 1 == typemax(UInt)

            @test typemax(Int) * 2 == -2
            @test typemin(Int) * 2 == 0
            @test typemax(UInt) * 2 == 0xfffffffffffffffe

            # @test typemax(Int) ^ 2 == 1
            # @test typemin(Int) ^ 2 == 0
            # @test typemax(UInt) ^ 2 == 0x0000000000000001

            @test abs(typemin(Int)) == typemin(Int)
        end
    end

    @testset "$testname with expressions" begin
        @testset "checked expressions" begin
            @test_throws OverflowError @checked typemax(Int) + 1
            @test_throws OverflowError @checked typemin(Int) - 1
            @test_throws OverflowError @checked typemax(UInt) + 1
            @test_throws OverflowError @checked typemin(UInt) - 1
    
            @test_throws OverflowError @checked typemax(Int) * 2
            @test_throws OverflowError @checked typemin(Int) * 2
            @test_throws OverflowError @checked typemax(UInt) * 2
    
            # @test_throws OverflowError @checked typemax(Int) ^ 2
            # @test_throws OverflowError @checked typemin(Int) ^ 2
            # @test_throws OverflowError @checked typemax(UInt) ^ 2
    
            @test_throws OverflowError @checked abs(typemin(Int))
        end
    
        @testset "unchecked expressions" begin
            @test @unchecked typemax(Int) + 1 == typemin(Int)
            @test @unchecked typemin(Int) - 1 == typemax(Int)
            @test @unchecked typemax(UInt) + 1 == typemin(UInt)
            @test @unchecked typemin(UInt) - 1 == typemax(UInt)
    
            @test @unchecked typemax(Int) * 2 == -2
            @test @unchecked typemin(Int) * 2 == 0
            @test @unchecked typemax(UInt) * 2 == 0xfffffffffffffffe
    
            # @test @unchecked typemax(Int) ^ 2 == 1
            # @test @unchecked typemin(Int) ^ 2 == 0
            # @test @unchecked typemax(UInt) ^ 2 == 0x0000000000000001
    
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
        end
    end
end

@default_unchecked # reset to Julia default

