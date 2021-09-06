using FunctionBarrier
using Test

@testset "FunctionBarrier.jl" begin
    a, b = 1, 2
    local c, d
    @barrier begin
        c = a + b
        d = c + 1
        c, d
    end
    @test c == a + b
    @test d == c + 1
    @test (@barrier a * b) == a * b
    x = [1, 2, 4]
    @test (@barrier x[end]) == x[end]
    @test (@barrier x[1]) == x[1]
end
