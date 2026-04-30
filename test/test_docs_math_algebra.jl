# Documentation Examples Tests: Algebra (036-domain-docs-tests)
# Verifies all code examples in docs/src/mathematics/algebra.md work correctly

@testset "Documentation Examples: Algebra" begin
    using Giac.Commands: factor, expand, simplify, solve, gcd, lcm, quo, rem, combine

    @testset "Polynomial Factorization" begin
        @giac_var x

        @test string(factor(x^2 - 1)) == "(x-1)*(x+1)"
        @test string(factor(x^2 - 4)) == "(x-2)*(x+2)"
        @test string(factor(x^2 + 2*x + 1)) == "(x+1)^2"
    end

    @testset "Polynomial Expansion" begin
        @giac_var x

        @test string(expand((x + 1)^2)) == "x^2+2*x+1"
        @test string(expand((x + 1)^3)) == "x^3+3*x^2+3*x+1"
        @test string(expand((x - 1) * (x + 1))) == "x^2-1"
    end

    @testset "Simplification" begin
        @giac_var x

        @test string(simplify((x^2-1)/(x-1))) == "x+1"
        @test string(simplify((x^3-x)/(x^2-1))) == "x"
    end

    @testset "Combine" begin
        @giac_var x
        @test combine(log(x) + 2log(x), log) == log(x*x^2)
        @test combine(log(x) + 2log(x), "log") == log(x*x^2)
        @test combine(log(x) + 2log(x), sin) == 3*log(x)
        @test combine(log(x) + 2log(x), "sin") == 3*log(x)
    end

    @testset "Equation Solving" begin
        @giac_var x

        result = string(solve(x^2 - 4, x))
        @test contains(result, "-2") && contains(result, "2")

        result = string(solve(x^2 - 1, x))
        @test contains(result, "-1") && contains(result, "1")
    end

    @testset "GCD and LCM" begin
        @giac_var x

        @test string(gcd(x^2 - 1, x - 1)) == "x-1"
        result = string(lcm(x - 1, x + 1))
        @test contains(result, "x-1") && contains(result, "x+1")
    end

    @testset "Polynomial Division" begin
        @giac_var x

        @test string(quo(x^3 - 1, x - 1)) == "x^2+x+1"
        @test string(rem(x^3, x - 1)) == "1"
    end

    @testset "Systems of Equations" begin
        @giac_var x y

        result = string(solve([x + y ~ 1, x - y ~ 0], [x, y]))
        @test contains(result, "1/2")
    end

end
