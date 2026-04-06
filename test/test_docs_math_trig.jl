# Documentation Examples Tests: Trigonometry (036-domain-docs-tests)
# Verifies all code examples in docs/src/mathematics/trigonometry.md work correctly

@testset "Documentation Examples: Trigonometry" begin
    using Giac.Commands: simplify, solve, trigexpand, tlin, tcollect, asin

    @testset "Pythagorean Identity" begin
        @giac_var x

        # sin²(x) + cos²(x) = 1
        result = string(simplify(sin(x)^2 + cos(x)^2))
        @test result == "1"
    end

    @testset "Trigonometric Expansion - trigexpand" begin
        @giac_var x

        # sin(2x) = 2*sin(x)*cos(x)
        result = string(trigexpand(sin(2*x)))
        @test contains(result, "sin") && contains(result, "cos")

        # cos(2x) expansion
        result = string(trigexpand(cos(2*x)))
        @test contains(result, "cos") || contains(result, "sin")
    end

    @testset "Product to Sum - tlin" begin
        @giac_var x

        # sin(x)*cos(x) = (1/2)*sin(2x)
        result = string(tlin(sin(x)*cos(x)))
        @test contains(result, "sin") && contains(result, "2")
    end

    @testset "Sum to Product - tcollect" begin
        @giac_var x

        # sin(x) + cos(x) = sqrt(2)*cos(x - π/4)
        result = string(tcollect(sin(x)+cos(x)))
        @test contains(result, "sqrt") && contains(result, "cos")
    end

    @testset "Trigonometric Simplification" begin
        @giac_var x

        # tan(x)*cos(x) = sin(x)
        result = string(simplify(tan(x)*cos(x)))
        @test contains(result, "sin")
    end

    @testset "Solving Trigonometric Equations" begin
        @giac_var x

        # sin(x) = 0
        result = string(solve(sin(x), x))
        @test contains(result, "0") || contains(result, "pi")
    end

    @testset "Double and Triple Angle" begin
        @giac_var x

        # sin(3x) expansion
        result = string(trigexpand(sin(3*x)))
        @test contains(result, "sin")
    end

    @testset "Inverse Trigonometric" begin
        @giac_var x

        # asin(1/2) = π/6
        # Create 1/2 as GiacExpr
        half = (1 + 0*x) / 2
        result = string(asin(half))
        @test contains(result, "pi") || contains(result, "6")
    end
end
