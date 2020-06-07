using FunctionBarrier
using Test

@testset "FunctionBarrier.jl" begin
    a, b = 1, 2
    @barrier begin
        c = a + b
        d = c + 1
        c, d
    end
    @test c == a + b
    @test d == c + 1
    @test @barrier a * b == a * b
end
