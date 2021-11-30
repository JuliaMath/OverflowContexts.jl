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

# Doesn't disrupt non-integer math
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
