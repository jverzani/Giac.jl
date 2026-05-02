# Tests for build_function tier 3 — Symbolics-backed callable
# (067-build-function-tier3)
#
# Every testset cites the contract clause ID(s) it covers from
# specs/067-build-function-tier3/contracts/build_function_tier3.md.

using Symbolics
using ForwardDiff

@testset "build_function tier 3 (symbolics backend)" begin

    # ========================================================================
    # T008: B1 — Default backend unchanged
    # ========================================================================
    @testset "B1: default backend is :giac and behavior matches v0.13" begin
        @giac_var x
        f_default = Giac.build_function(x^2 - 1, x)
        f_giac    = Giac.build_function(x^2 - 1, x; backend = :giac)
        # Both must produce the same value on representative inputs.
        for v in (-2, 0, 1, 3, 2.5)
            @test f_default(v) == f_giac(v)
        end
    end

    # ========================================================================
    # T009: B4 — Backend symbol validation
    # ========================================================================
    @testset "B4: bad backend symbol raises ArgumentError" begin
        @giac_var x
        @test_throws ArgumentError Giac.build_function(x^2, x; backend = :nope)
        @test_throws ArgumentError Giac.build_function(x^2, x; backend = :fast)
        # The error message must mention what was expected.
        try
            Giac.build_function(x^2, x; backend = :nope)
            @test false  # unreachable
        catch e
            @test e isa ArgumentError
            msg = sprint(showerror, e)
            @test occursin("nope", msg)
            @test occursin(":giac", msg) || occursin(":symbolics", msg)
        end
    end

    # ========================================================================
    # T010: B2 — Numeric equivalence sweep, :giac vs :symbolics
    # ========================================================================
    @testset "B2: numeric equivalence sweep — :giac vs :symbolics" begin
        @giac_var x y

        # Three representative expressions in the supported head set.
        cases = [
            ("x^2 - 2x + 1", x^2 - 2*x + 1, (x,),
                () -> (rand(-5.0:0.01:5.0),)),
            ("sin(x)*cos(y)", invoke_cmd(:sin, x) * invoke_cmd(:cos, y), (x, y),
                () -> (rand(-3.0:0.01:3.0), rand(-3.0:0.01:3.0))),
            ("(x+y)^3 / (x-y+1)", (x + y)^3 / (x - y + 1), (x, y),
                () -> begin
                    a = rand(-5.0:0.01:5.0)
                    b = rand(-5.0:0.01:5.0)
                    while isapprox(a - b + 1, 0; atol = 1e-3)
                        a = rand(-5.0:0.01:5.0)
                        b = rand(-5.0:0.01:5.0)
                    end
                    (a, b)
                end),
        ]

        for (name, expr, vars, sampler) in cases
            f_giac = Giac.build_function(expr, vars...; backend = :giac)
            f_sym  = Giac.build_function(expr, vars...; backend = :symbolics)
            for _ in 1:100
                vals = sampler()
                v_giac = f_giac(vals...)
                v_sym  = f_sym(vals...)
                @test isapprox(v_giac, v_sym; atol = 1e-10, rtol = 1e-10)
            end
        end
    end

    # ========================================================================
    # T011: B6 — Free-symbol error
    # ========================================================================
    @testset "B6: free symbol not bound by vars raises ArgumentError" begin
        @giac_var x y
        @test_throws ArgumentError Giac.build_function(x*y, x; backend = :symbolics)
        # Message names the unbound symbol and points to :giac for recovery.
        try
            Giac.build_function(x*y, x; backend = :symbolics)
            @test false  # unreachable
        catch e
            @test e isa ArgumentError
            msg = sprint(showerror, e)
            @test occursin("y", msg)
            @test occursin(":giac", msg)
        end
    end

    # ========================================================================
    # T017: B3 — ForwardDiff compatibility (US2 — SciML smoke)
    # ========================================================================
    @testset "B3: ForwardDiff.derivative through :symbolics callable" begin
        @giac_var x
        expr = x^3 - 2*x + 1
        f_sym = Giac.build_function(expr, x; backend = :symbolics)

        # Analytic derivative: 3x^2 - 2 → at x=2.0 → 10.0.
        @test ForwardDiff.derivative(f_sym, 2.0) ≈ 10.0 atol=1e-10

        # Equivalence with the manual chain.
        manual = to_julia(Giac.substitute(invoke_cmd(:diff, expr, x), x => 2.0))
        @test ForwardDiff.derivative(f_sym, 2.0) ≈ manual atol=1e-10
    end

    # ========================================================================
    # T019: B7 — Unsupported-head error (US3)
    # ========================================================================
    @testset "B7: unsupported GIAC head raises at build_function time" begin
        @giac_var x
        # Heaviside is currently NOT in the to_symbolics translation map.
        # If a future release adds it, swap for another untranslated head.
        exotic = giac_eval("Heaviside(x)")
        @test_throws Exception Giac.build_function(exotic, x; backend = :symbolics)

        # The error message must name the offending head (or the operator
        # string), so a user can tell what went wrong without a debugger.
        try
            Giac.build_function(exotic, x; backend = :symbolics)
            @test false  # unreachable
        catch e
            msg = sprint(showerror, e)
            @test occursin("Heaviside", msg)
        end
    end

    # ========================================================================
    # T012: B8 — Edge-case parity with the :giac backend
    # ========================================================================
    @testset "B8: edge-case parity with :giac" begin
        @giac_var x y

        # Constant expression (zero vars).
        @test Giac.build_function(giac_eval("42"); backend = :symbolics)() == 42

        # Symbolic π reduced numerically — both backends must produce the
        # same Float64 within 1e-10.
        f_pi_giac = Giac.build_function(invoke_cmd(:sin, x), x; backend = :giac)
        f_pi_sym  = Giac.build_function(invoke_cmd(:sin, x), x; backend = :symbolics)
        @test isapprox(f_pi_giac(Float64(pi)/2), f_pi_sym(Float64(pi)/2); atol = 1e-10)

        # Extra (unused) vars are silently ignored.
        @test Giac.build_function(x^2, x, y; backend = :symbolics)(3, 100) == 9

        # Argument-count mismatch on the returned callable raises *some*
        # exception. Note: the Symbolics-built RuntimeGeneratedFunction
        # raises BoundsError for too few args (different from Tier 1's
        # MethodError) and silently ignores extra args. This divergence is
        # documented in the contract — Tier 3 callers who need strict
        # arity should use the :giac backend instead.
        f_arity = Giac.build_function(x^2, x; backend = :symbolics)
        @test_throws Exception f_arity()
        # f_arity(1, 2) is NOT asserted to throw — Symbolics' RGF accepts
        # extra args silently.
    end
end
