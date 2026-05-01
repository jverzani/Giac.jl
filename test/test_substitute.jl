# Tests for substitute function (028-substitute-mechanism)

@testset "Substitute Function" begin

    # ========================================================================
    # Phase 3: User Story 1 - Single Variable Substitution (P1 MVP)
    # ========================================================================

    @testset "US1: Single Variable Substitution" begin
        @testset "T007: Single numeric substitution" begin
            @giac_var a b
            expr = a + b
            result = substitute(expr, Dict(a => 2))
            @test result isa GiacExpr
            # Result should be 2 + b
            result_str = string(result)
            @test occursin("2", result_str) || occursin("b", result_str)
        end

        @testset "T008: Polynomial substitution" begin
            @giac_var x
            expr = x^2 + 3*x + 1
            result = substitute(expr, Dict(x => 5))
            @test result isa GiacExpr
            # x=5: 25 + 15 + 1 = 41
            result_str = string(result)
            @test occursin("41", result_str)
        end

        @testset "T009: Trig function substitution" begin
            @giac_var x
            expr = invoke_cmd(:sin, x) + x
            result = substitute(expr, Dict(x => 0))
            @test result isa GiacExpr
            # sin(0) + 0 = 0
            result_str = string(result)
            @test result_str == "0"
        end

        @testset "T010: Empty Dict returns original" begin
            @giac_var x
            expr = x + 1
            result = substitute(expr, Dict{GiacExpr, Int}())
            @test result isa GiacExpr
            @test string(result) == string(expr)
        end

        @testset "T011: Missing variable returns original" begin
            @giac_var x y
            expr = x + 1
            result = substitute(expr, Dict(y => 5))
            @test result isa GiacExpr
            # y is not in expr, so result should be unchanged
            @test string(result) == string(expr)
        end
    end

    # ========================================================================
    # Phase 4: User Story 2 - Multiple Variable Substitution (P2)
    # ========================================================================

    @testset "US2: Multiple Variable Substitution" begin
        @testset "T015: Multi-variable substitution" begin
            @giac_var a b c
            expr = a + b + c
            result = substitute(expr, Dict(a => 1, b => 2))
            @test result isa GiacExpr
            # a=1, b=2: 1 + 2 + c = 3 + c
            result_str = string(result)
            @test occursin("3", result_str) || (occursin("c", result_str))
        end

        @testset "T016: Complete substitution" begin
            @giac_var x y z
            expr = x*y + y*z
            result = substitute(expr, Dict(x => 2, y => 3, z => 4))
            @test result isa GiacExpr
            # 2*3 + 3*4 = 6 + 12 = 18
            result_str = string(result)
            @test occursin("18", result_str)
        end

        @testset "T017: Variable swap (simultaneous)" begin
            @giac_var a b
            expr = a^2 + b
            result = substitute(expr, Dict(a => b, b => a))
            @test result isa GiacExpr
            # Simultaneous: a^2 + b -> b^2 + a
            result_str = string(result)
            # Should contain b^2 and a (swapped)
            @test occursin("a", result_str) && occursin("b", result_str)
        end
    end

    # ========================================================================
    # Phase 5: User Story 3 - Symbolic-to-Symbolic Substitution (P3)
    # ========================================================================

    @testset "US3: Symbolic-to-Symbolic Substitution" begin
        @testset "T020: Symbolic substitution" begin
            @giac_var x y
            expr = x^2
            result = substitute(expr, Dict(x => y + 1))
            @test result isa GiacExpr
            # x^2 with x=y+1 -> (y+1)^2
            result_str = string(result)
            @test occursin("y", result_str)
        end

        @testset "T021: Symbolic in trig" begin
            @giac_var x y
            expr = invoke_cmd(:sin, x)
            result = substitute(expr, Dict(x => 2*y))
            @test result isa GiacExpr
            # sin(x) with x=2*y -> sin(2*y)
            result_str = string(result)
            @test occursin("sin", result_str) && occursin("y", result_str)
        end
    end

    # ========================================================================
    # Phase 6: User Story 4 - Pair Syntax Alternative (P4)
    # ========================================================================

    @testset "US4: Pair Syntax Alternative" begin
        @testset "T023: Pair syntax numeric" begin
            @giac_var x
            expr = x + 1
            result = substitute(expr, x => 5)
            @test result isa GiacExpr
            # x + 1 with x=5 -> 6
            result_str = string(result)
            @test occursin("6", result_str)
        end

        @testset "T024: Pair syntax symbolic result" begin
            @giac_var a b
            expr = a * b
            result = substitute(expr, a => 3)
            @test result isa GiacExpr
            # a*b with a=3 -> 3*b
            result_str = string(result)
            @test occursin("3", result_str) && occursin("b", result_str)
        end
    end

    # ========================================================================
    # Phase 7: Edge Cases & Robustness
    # ========================================================================

    @testset "Edge Cases" begin
        @testset "T027: Different numeric types" begin
            @giac_var x
            expr = x + 1

            # Int
            r1 = substitute(expr, Dict(x => 2))
            @test r1 isa GiacExpr

            # Float64
            r2 = substitute(expr, Dict(x => 2.5))
            @test r2 isa GiacExpr

            # Rational
            r3 = substitute(expr, Dict(x => 1//2))
            @test r3 isa GiacExpr
        end

        @testset "T028: Chained substitution" begin
            @giac_var x y z
            expr = x + y + z
            d1 = Dict(x => 1)
            d2 = Dict(y => 2)

            # Chained: substitute twice
            r1 = substitute(expr, d1)
            r2 = substitute(r1, d2)
            @test r2 isa GiacExpr
            # 1 + 2 + z = 3 + z
            result_str = string(r2)
            @test occursin("3", result_str) || occursin("z", result_str)
        end

        @testset "T029: Invalid value type throws ArgumentError" begin
            @giac_var x
            expr = x + 1
            @test_throws ArgumentError substitute(expr, Dict(x => nothing))
        end
    end

    # ========================================================================
    # T030: GiacMatrix Substitution (Element-wise)
    # ========================================================================

    @testset "GiacMatrix Substitution" begin
        @testset "T030a: Single variable matrix substitution with Dict" begin
            @giac_var x
            M = GiacMatrix([x x+1; 2*x x^2])
            result = substitute(M, Dict(x => 3))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Check elements: [3 4; 6 9]
            @test string(result[1, 1]) == "3"
            @test string(result[1, 2]) == "4"
            @test string(result[2, 1]) == "6"
            @test string(result[2, 2]) == "9"
        end

        @testset "T030b: Single variable matrix substitution with Pair" begin
            @giac_var x
            M = GiacMatrix([x 2*x; x+1 x^2])
            result = substitute(M, x => 3)
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Check elements: [3 6; 4 9]
            @test string(result[1, 1]) == "3"
            @test string(result[1, 2]) == "6"
            @test string(result[2, 1]) == "4"
            @test string(result[2, 2]) == "9"
        end

        @testset "T030c: Multi-variable matrix substitution" begin
            @giac_var x y
            M = GiacMatrix([x+y x*y; x-y x/y])
            result = substitute(M, Dict(x => 6, y => 2))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # x=6, y=2: [8 12; 4 3]
            @test string(result[1, 1]) == "8"
            @test string(result[1, 2]) == "12"
            @test string(result[2, 1]) == "4"
            @test string(result[2, 2]) == "3"
        end

        @testset "T030d: Partial substitution in matrix" begin
            @giac_var x y
            M = GiacMatrix([x y; x+y x*y])
            result = substitute(M, Dict(x => 2))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Only x=2: [2 y; 2+y 2*y]
            @test string(result[1, 1]) == "2"
            @test string(result[1, 2]) == "y"
            result_21 = string(result[2, 1])
            result_22 = string(result[2, 2])
            @test occursin("2", result_21) && occursin("y", result_21)
            @test occursin("2", result_22) && occursin("y", result_22)
        end

        @testset "T030e: Empty Dict returns matrix copy" begin
            @giac_var x
            M = GiacMatrix([x x+1; 2*x 3*x])
            result = substitute(M, Dict{GiacExpr, Int}())
            @test result isa GiacMatrix
            @test size(result) == size(M)
            # Elements should be unchanged
            @test string(result[1, 1]) == string(M[1, 1])
            @test string(result[2, 2]) == string(M[2, 2])
        end

        @testset "T030f: Symbolic substitution in matrix" begin
            @giac_var x y
            M = GiacMatrix([x^2 x; 1 x+1])
            result = substitute(M, Dict(x => y + 1))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # x -> y+1: [(y+1)^2 y+1; 1 y+2]
            result_11 = string(result[1, 1])
            result_12 = string(result[1, 2])
            result_22 = string(result[2, 2])
            @test occursin("y", result_11)
            @test occursin("y", result_12)
            @test occursin("y", result_22)
        end

        @testset "T030g: Vector (1D matrix) substitution" begin
            @giac_var x
            V = GiacMatrix([x, 2*x, x^2])  # Column vector
            result = substitute(V, x => 2)
            @test result isa GiacMatrix
            @test size(result) == (3, 1)
            # x=2: [2, 4, 4]
            @test string(result[1, 1]) == "2"
            @test string(result[2, 1]) == "4"
            @test string(result[3, 1]) == "4"
        end
    end

    # ========================================================================
    # 065-substitute-tier1: Direct-binding contract
    # Locks down simultaneous-substitution semantics and float precision so the
    # refactor from the string round-trip to GiacCxxBindings.giac_subst stays
    # safe.
    # ========================================================================

    @testset "065-substitute-tier1: simultaneous semantics & precision" begin
        @testset "C-003: Canonical variable swap (GiacExpr)" begin
            @giac_var x y
            expr = x + 2*y
            result = substitute(expr, Dict(x => y, y => x))
            @test result isa GiacExpr
            # Simultaneous: swap must NOT collapse to 3*x or 3*y.
            @test string(result) == "y+2*x"
            # And rigorous equivalence: result - (y + 2*x) simplifies to 0.
            diff = invoke_cmd(:simplify, result - (y + 2*x))
            @test string(diff) == "0"
        end

        @testset "C-004: Value references another key" begin
            @giac_var x y
            # Dict(x => y + 1, y => 0) applied to x must yield y + 1, NOT 1.
            # Values are taken as written; they are not re-substituted.
            result = substitute(x, Dict(x => y + 1, y => 0))
            @test result isa GiacExpr
            @test string(result) == "y+1"
            @test string(result) != "1"
        end

        @testset "C-005-strong: Empty Dict returns identical instance" begin
            @giac_var x
            expr = x + 1
            result = substitute(expr, Dict{GiacExpr, Int}())
            # Stronger than structural equality: confirms no GIAC call was made.
            @test result === expr
        end

        @testset "C-006: GiacMatrix dict-form simple substitution" begin
            @giac_var x y
            M = GiacMatrix([x+1 2*x; y x*y])
            result = substitute(M, Dict(x => 2))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            @test string(result[1, 1]) == "3"
            @test string(result[1, 2]) == "4"
            @test string(result[2, 1]) == "y"
            @test string(result[2, 2]) == "2*y"
        end

        @testset "C-007: GiacMatrix simultaneous swap" begin
            @giac_var x y
            M = GiacMatrix([x y; y x])
            result = substitute(M, Dict(x => y, y => x))
            @test result isa GiacMatrix
            @test size(result) == (2, 2)
            # Swapped element-wise, simultaneously.
            @test string(result[1, 1]) == "y"
            @test string(result[1, 2]) == "x"
            @test string(result[2, 1]) == "x"
            @test string(result[2, 2]) == "y"
        end

        @testset "C-008: GiacMatrix empty Dict structural copy" begin
            @giac_var x y
            M = GiacMatrix([x+1 2*x; y x*y])
            result = substitute(M, Dict{GiacExpr, Int}())
            @test result isa GiacMatrix
            @test size(result) == size(M)
            for i in 1:M.rows, j in 1:M.cols
                @test string(result[i, j]) == string(M[i, j])
            end
        end

        @testset "C-013: Float64 precision preservation" begin
            @giac_var x
            result = substitute(x, Dict(x => 0.1))
            result_str = string(result)
            # Result must contain "0.1" verbatim, not a long-decimal expansion.
            @test occursin("0.1", result_str)
            @test !occursin("0.1000000", result_str)
            @test !occursin("0.0999999", result_str)
        end
    end

    # ========================================================================
    # 065-substitute-tier1: Varargs convenience method
    # ========================================================================

    @testset "065-substitute-tier1: varargs convenience" begin
        @testset "C-009: Varargs scalar two-pair == Dict form" begin
            @giac_var x y
            r_varargs = substitute(x*y, x => 1, y => 2)
            r_dict    = substitute(x*y, Dict(x => 1, y => 2))
            @test r_varargs isa GiacExpr
            @test string(r_varargs) == string(r_dict)
            @test string(r_varargs) == "2"
        end

        @testset "C-010: Varargs swap matches dict swap" begin
            @giac_var x y
            r_varargs = substitute(x + 2*y, x => y, y => x)
            r_dict    = substitute(x + 2*y, Dict(x => y, y => x))
            @test string(r_varargs) == string(r_dict)
            @test string(r_varargs) == "y+2*x"
        end

        @testset "C-011: Zero-pairs varargs returns input unchanged" begin
            @giac_var x
            expr = x + 1
            result = substitute(expr)
            # No pairs splatted -> Dict() is empty -> no-op short-circuit.
            @test result === expr
        end

        @testset "C-012: GiacMatrix varargs swap matches dict swap" begin
            @giac_var x y
            M = GiacMatrix([x y; y x])
            r_varargs = substitute(M, x => y, y => x)
            r_dict    = substitute(M, Dict(x => y, y => x))
            @test r_varargs isa GiacMatrix
            @test size(r_varargs) == (2, 2)
            for i in 1:2, j in 1:2
                @test string(r_varargs[i, j]) == string(r_dict[i, j])
            end
        end
    end

    # ========================================================================
    # 065-substitute-tier1: Call-syntax sugar (idea from PR #11 by @jverzani)
    # `expr(pair1, pair2, ...)` delegates to `substitute(expr, pair1, ...)`,
    # inheriting simultaneous-substitution semantics.
    # ========================================================================

    @testset "065-substitute-tier1: call syntax with Pairs" begin
        @testset "Single pair via call" begin
            @giac_var x
            expr = x + 1
            @test string(expr(x => 5)) == "6"
        end

        @testset "Multi-pair via call equals substitute(expr, pairs...)" begin
            @giac_var a b c d t
            expr = a*invoke_cmd(:sin, b*t + c) + d
            r_call    = expr(a => 15, b => 10, c => 5, d => 0)
            r_sub     = substitute(expr, a => 15, b => 10, c => 5, d => 0)
            @test r_call isa GiacExpr
            @test string(r_call) == string(r_sub)
        end

        @testset "Call-syntax preserves simultaneous swap" begin
            @giac_var x y
            expr = x + 2*y
            # Critical: must not collapse the swap.
            @test string(expr(x => y, y => x)) == "y+2*x"
        end

        @testset "Call with non-pair args still does function evaluation" begin
            # Verifies the new Pair-specific overload does not shadow the
            # existing function-call-style behavior `u(0)`.
            @giac_var u(t)
            @test string(u(0)) == "u(0)"
        end
    end
end
