# Tests for CommonSolve.solve integration (PR #7 by @jverzani)
# Verifies that Giac.Commands.solve and CommonSolve.solve refer to the same
# generic function, so Giac plays well with the broader Julia "solve" verb
# ecosystem (DifferentialEquations.jl, NLsolve.jl, Symbolics.jl, …).

using CommonSolve

@testset "CommonSolve integration" begin

    @testset "solve identity: Giac.Commands.solve === CommonSolve.solve" begin
        @test Giac.Commands.solve === CommonSolve.solve
    end

    @testset "solve dispatches Giac methods through CommonSolve" begin
        @giac_var x

        # Calling CommonSolve.solve on a GiacExpr equation routes to Giac's
        # auto-generated solve method (added to CommonSolve.solve via Julia's
        # extend-imported-function mechanism).
        result = CommonSolve.solve(x^2 - 1, x)
        @test result isa GiacExpr

        result_str = string(result)
        @test occursin("-1", result_str)
        @test occursin("1", result_str)
    end

    @testset "solve via Giac.Commands and via CommonSolve produce equal results" begin
        using Giac.Commands: solve as gsolve
        @giac_var x y

        # Single equation
        @test string(gsolve(x^2 - 4, x))         == string(CommonSolve.solve(x^2 - 4, x))

        # System of equations
        @test string(gsolve([x + y ~ 3, x - y ~ 1], [x, y])) ==
              string(CommonSolve.solve([x + y ~ 3, x - y ~ 1], [x, y]))
    end

    @testset "GiacMatrix path also extends CommonSolve.solve" begin
        # The auto-generator emits a GiacMatrix overload for every command, so
        # CommonSolve.solve(::GiacMatrix, …) should dispatch the same way.
        @giac_var x
        # `solve` on a matrix isn't a typical use case, but the method must
        # exist for dispatch consistency.
        @test hasmethod(CommonSolve.solve, Tuple{GiacMatrix, Vararg{Any}})
    end

    @testset "init / solve! are NOT extended by Giac" begin
        # Giac is a symbolic CAS (non-iterative), so only CommonSolve.solve is
        # integrated. CommonSolve.init and CommonSolve.solve! must remain
        # un-shadowed by anything in Giac so packages implementing the
        # iterative-solver protocol can extend them without conflict.
        @giac_var x

        # No Giac method on init or solve! for symbolic inputs.
        @test !hasmethod(CommonSolve.init,   Tuple{GiacExpr, Vararg{Any}})
        @test !hasmethod(CommonSolve.solve!, Tuple{GiacExpr, Vararg{Any}})

        # And the bindings themselves are not aliased by Giac (they live in
        # CommonSolve only).
        @test parentmodule(CommonSolve.init)   === CommonSolve
        @test parentmodule(CommonSolve.solve!) === CommonSolve
    end
end
