# Documentation Examples Tests: Differential Equations (036-domain-docs-tests)
# Verifies all code examples in docs/src/mathematics/differential_equations.md work correctly

@testset "Documentation Examples: Differential Equations" begin
    using Giac.Commands: desolve

    @testset "D Operator Basics" begin
        @giac_var t u(t)

        # D(u) creates a derivative expression
        @test D(u) isa Giac.DerivativeExpr

        # D(u, 2) creates second derivative
        @test D(u, 2) isa Giac.DerivativeExpr
    end

    @testset "First-Order ODE" begin
        @giac_var t u(t) tau U0

        # Solve τu' + u = U₀ with u(0) = 1
        ode = tau * D(u) + u ~ U0
        initial = u(0) ~ 1
        result = string(desolve([ode, initial], t, :u))
        @test contains(result, "U0") && contains(result, "exp")
    end

    @testset "Second-Order ODE - Harmonic Oscillator" begin
        @giac_var t u(t)

        # Solve u'' + u = 0 with u(0) = 1, u'(0) = 0
        ode = D(D(u)) + u ~ 0
        u0 = u(0) ~ 1
        du0 = D(u)(0) ~ 0
        result = string(desolve([ode, u0, du0], t, :u))
        @test contains(result, "cos")
    end

    @testset "Second-Order ODE - Alternative Syntax" begin
        @giac_var t u(t)

        # Same ODE using D(u, 2) syntax
        ode = D(u, 2) + u ~ 0
        result = string(desolve([ode, u(0) ~ 1, D(u)(0) ~ 0], t, :u))
        @test contains(result, "cos")
    end

    @testset "Damped Oscillator" begin
        @giac_var t u(t) zeta omega0

        # Solve u'' + 2ζω₀u' + ω₀²u = 0
        ode = D(u, 2) + 2*zeta*omega0*D(u) + omega0^2*u ~ 0
        result = string(desolve([ode, u(0) ~ 1, D(u)(0) ~ 0], t, :u))
        @test contains(result, "exp")
    end

    @testset "Third-Order ODE" begin
        @giac_var t y(t)

        # Solve y''' - y = 0 with y(0) = 1, y'(0) = 1, y''(0) = 1
        ode = D(y, 3) - y ~ 0
        y0 = y(0) ~ 1
        dy0 = D(y)(0) ~ 1
        d2y0 = D(y, 2)(0) ~ 1
        result = string(desolve([ode, y0, dy0, d2y0], t, :y))
        @test contains(result, "exp")
    end

    @testset "RC Circuit ODE" begin
        @giac_var t V(t) R C Vs

        # RC circuit: RC·V' + V = Vs with V(0) = 0
        ode = R * C * D(V) + V ~ Vs
        initial = V(0) ~ 0
        result = string(desolve([ode, initial], t, :V))
        @test contains(result, "Vs") && contains(result, "exp")
    end

    @testset "D Operator with Arithmetic" begin
        @giac_var t u(t) a b c

        # Build ODE expressions with arithmetic
        ode_expr = D(D(u)) + a*D(u) + b*u
        @test ode_expr isa GiacExpr

        # With forcing function (~ creates equation as GiacExpr)
        forcing = sin(t)
        ode_with_forcing = D(D(u)) + u ~ forcing
        @test ode_with_forcing isa GiacExpr
    end

    @testset "Physics Examples - Exponential Decay" begin
        @giac_var t N(t) lambda

        # Radioactive decay: dN/dt = -λN
        ode = D(N) + lambda * N ~ 0
        result = string(desolve([ode], t, :N))
        @test contains(result, "exp")
    end

    @testset "Physics Examples - Population Growth" begin
        @giac_var t P(t) r

        # Exponential growth: dP/dt = rP
        ode = D(P) - r * P ~ 0
        result = string(desolve([ode], t, :P))
        @test contains(result, "exp")
    end
end
