# Documentation Examples Tests: Mechanics (036-domain-docs-tests)
# Verifies all code examples in docs/src/physics/mechanics.md work correctly

@testset "Documentation Examples: Mechanics" begin
    using Giac.Commands: diff, integrate, solve, desolve

    @testset "Kinematics - Position, Velocity, Acceleration" begin
        @giac_var t

        # Position to velocity
        x_t = t^2
        v_t = diff(x_t, t)
        @test string(v_t) == "2*t"

        # Velocity to acceleration
        a_t = diff(v_t, t)
        @test string(a_t) == "2"
    end

    @testset "Kinematics - Integration" begin
        @giac_var t a_const

        # Acceleration to velocity (constant acceleration = 2)
        v_t = integrate(2 + 0*t, t)  # Use 2 + 0*t to create GiacExpr
        result = string(v_t)
        @test contains(result, "2") && contains(result, "t")

        # Velocity to position
        x_t = integrate(2*t, t)
        result = string(x_t)
        @test contains(result, "t^2")
    end

    @testset "Projectile Motion" begin
        @giac_var t g v0 theta

        # Vertical motion y(t) = v0*sin(theta)*t - g*t^2/2
        y_t = v0 * sin(theta) * t - g * t^2 / 2
        vy_t = diff(y_t, t)
        result = string(vy_t)
        @test contains(result, "sin") && contains(result, "v0")
    end

    @testset "Dynamics - Force Equations" begin
        @giac_var F m a

        # Newton's second law: F = ma, solve for a
        result = string(solve(F ~ m * a, a))
        @test contains(result, "F") && contains(result, "m")
    end

    @testset "Simple Harmonic Motion" begin
        @giac_var t x(t) omega

        # SHM differential equation using D operator
        ode = D(x, 2) + omega^2 * x ~ 0
        result = string(desolve([ode], t, :x))
        @test contains(result, "sin") || contains(result, "cos")
    end

    @testset "Energy Conservation" begin
        @giac_var m v h g

        # KE = PE: (1/2)mv^2 = mgh, solve for v
        result = string(solve(m * v^2 / 2 ~ m * g * h, v))
        @test contains(result, "g") && contains(result, "h")
    end

    @testset "Uniform Circular Motion" begin
        @giac_var v r omega

        # v = omega * r, solve for omega
        result = string(solve(v ~ omega * r, omega))
        @test contains(result, "v") && contains(result, "r")
    end
end
