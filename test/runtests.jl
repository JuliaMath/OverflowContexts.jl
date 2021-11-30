using Test

using OverflowContexts
x = typemax(Int)
x + 1 == typemin(Int)

@default_checked
@test_throws OverflowError x + 1

@test @unchecked x * 2 == -2

@unchecked begin
    @test x * 2 == -2
    @test_throws OverflowError @checked x + 1
end

@default_unchecked
@test x + 1 == typemin(Int)

d() = x + 1; c() = d(); b() = c(); a() = b();

@test a() == typemin(Int)
@test @checked a() == typemin(Int)

@default_checked
@test_throws OverflowError a()

@test_throws OverflowError @unchecked a()
@default_unchecked

@test a() == typemin(Int)
