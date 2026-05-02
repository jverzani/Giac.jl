# Tests for build_function (066-build-function)
#
# Every testset cites the clause ID(s) it covers from
# specs/066-build-function/contracts/build_function.md.

using Random

@testset "build_function" begin

    # ========================================================================
    # T005: constant expression (C1, C7)
    # ========================================================================
    @testset "C1, C7: constant expression with no free variables" begin
        # C1: zero-argument callable for a numeric constant.
        f = build_function(giac_eval("42"))
        @test f() == 42

        # C1: equivalent to to_julia(expr) directly.
        @test f() == to_julia(giac_eval("42"))

        # C7: symbolic constant (pi) is reduced numerically through evalf.
        pi_expr = convert(GiacExpr, Giac.Constants.pi)
        h = build_function(pi_expr)
        @test h() ≈ Float64(pi)
    end

    # ========================================================================
    # T006: univariate (C2)
    # ========================================================================
    @testset "C2: univariate substitution" begin
        @giac_var x
        f = build_function(x^2 - 1, x)

        @test f(3) == 8
        @test f(0) == -1
        @test f(2.5) ≈ 5.25

        # Equivalence with the manual chain.
        @test f(7) == to_julia(substitute(x^2 - 1, x => 7))
    end

    # ========================================================================
    # T007: multivariate, simultaneous substitution (C3)
    # ========================================================================
    @testset "C3: multivariate simultaneous substitution" begin
        @giac_var x y
        g = build_function(x + 2*y, x, y)
        @test g(1, 2) == 5

        # Subtraction; argument order matters.
        h = build_function(x - y, x, y)
        @test h(2, 5) == -3

        # Three-variable dispatch on vars::GiacExpr...
        @giac_var x y z
        k = build_function(x + y + z, x, y, z)
        @test k(1, 2, 3) == 6
    end

    # ========================================================================
    # T008: unused vars (C4)
    # ========================================================================
    @testset "C4: extra (unused) variables are silently ignored" begin
        @giac_var x y
        # y does not appear in expr; passing 100 for it is a no-op.
        @test build_function(x^2, x, y)(3, 100) == 9

        # Equivalent to the no-y form.
        @test build_function(x^2, x, y)(3, 100) == build_function(x^2, x)(3)
    end

    # ========================================================================
    # T009: missing vars (C5)
    # ========================================================================
    @testset "C5: missing variables produce a GiacExpr result (no error)" begin
        @giac_var x y
        f = build_function(x*y, x)
        res = f(2)
        # Free `y` remains, so the result is still symbolic.
        @test res isa GiacExpr
        # And it is exactly what the manual chain gives.
        @test string(res) == string(to_julia(substitute(x*y, x => 2)))
    end

    # ========================================================================
    # T010: arity mismatch (C6)
    # ========================================================================
    @testset "C6: argument-count mismatch raises MethodError" begin
        @giac_var x
        # Fixed-arity Vararg{Any, N} dispatch ⇒ natural Julia MethodError.
        @test_throws MethodError build_function(x^2, x)()
        @test_throws MethodError build_function(x^2, x)(1, 2)

        # n == 0 case: zero-arg callable; extra args ⇒ MethodError too.
        @test_throws MethodError build_function(giac_eval("42"))(1)
    end

    # ========================================================================
    # T011: symbolic constants (C7)
    # ========================================================================
    @testset "C7: symbolic constants flow through evalf" begin
        @giac_var x

        # Float pi: the substituted expression has no free vars, so
        # to_julia auto-evalfs.
        f = build_function(invoke_cmd(:sin, x), x)
        @test f(Float64(pi)/2) ≈ 1.0
        @test f(Float64(pi)) ≈ 0.0 atol=1e-10

        # exp(0) -> 1.
        g = build_function(invoke_cmd(:exp, x), x)
        @test g(0) == 1

        # Symbolic pi as the value: substitute(sin(x), x => pi/2) -> 1 (exact).
        pi_giac = convert(GiacExpr, Giac.Constants.pi)
        @test f(pi_giac/2) == 1
    end

    # ========================================================================
    # T012: mixed numeric types (C8)
    # ========================================================================
    @testset "C8: mixed numeric input types match the manual chain" begin
        @giac_var x
        expr = x^2 + 1
        f = build_function(expr, x)

        # The wrapper inherits the chain's behavior INCLUDING failure modes
        # (per research R5). For each value type, the build_function call and
        # the manual substitute+to_julia chain must produce the same outcome:
        # either the same value, or both fail with the same exception type.
        # `5//2` exercises the "both fail identically" case: GIAC's `to_julia`
        # cannot reduce a non-simplified FRAC like `(5/2)^2+1` directly.
        function outcome(thunk)
            try
                return thunk()
            catch e
                return (Exception, typeof(e))
            end
        end

        for v in (3, 3.0, 5//2, big(7), 1.0 + 2.0im)
            @test outcome(() -> f(v)) ==
                  outcome(() -> to_julia(substitute(expr, x => v)))
        end
    end

    # ========================================================================
    # T013: broadcasting and comprehension (C9)
    # ========================================================================
    @testset "C9: broadcasting and matrix comprehensions work" begin
        @giac_var x
        f = build_function(x^2, x)
        @test f.([0, 1, 2, 3]) == [0, 1, 4, 9]

        @giac_var x y
        g = build_function(x + y, x, y)
        M = [g(xi, yi) for xi in 1:3, yi in 1:3]
        @test M == [xi + yi for xi in 1:3, yi in 1:3]
    end

    # ========================================================================
    # T014: behavioral equivalence sweep (C10, the defining equivalence)
    # ========================================================================
    @testset "C10: behavioral equivalence sweep — f(vals...) ≡ to_julia(expr(Pair.(vars,vals)...))" begin
        @giac_var x y

        rng = MersenneTwister(20260502)

        # Three representative expressions × 100 sampled inputs each.
        cases = [
            ("x^2 - 2x + 1", x^2 - 2*x + 1, (x,),
                () -> (rand(rng, -5.0:0.01:5.0),)),
            ("sin(x)*cos(y)", invoke_cmd(:sin, x) * invoke_cmd(:cos, y), (x, y),
                () -> (rand(rng, -3.14:0.01:3.14), rand(rng, -3.14:0.01:3.14))),
            ("(x+y)^3 / (x-y+1)", (x + y)^3 / (x - y + 1), (x, y),
                () -> begin
                    a = rand(rng, -5.0:0.01:5.0)
                    b = rand(rng, -5.0:0.01:5.0)
                    while isapprox(a - b + 1, 0; atol=1e-3)
                        a = rand(rng, -5.0:0.01:5.0)
                        b = rand(rng, -5.0:0.01:5.0)
                    end
                    (a, b)
                end),
        ]

        for (name, expr, vars, sampler) in cases
            f = build_function(expr, vars...)
            for _ in 1:100
                vals = sampler()
                got = f(vals...)
                expected = to_julia(substitute(expr, Dict(vars[i] => vals[i] for i in eachindex(vars))))
                if got isa AbstractFloat && expected isa AbstractFloat
                    @test got ≈ expected atol=1e-8 rtol=1e-8
                else
                    @test got == expected
                end
            end
        end
    end
end
