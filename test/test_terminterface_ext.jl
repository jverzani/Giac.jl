# TermInterface Extension Tests (Issue #3 task 3)
# Verifies that TermInterface.iscall / operation / arguments / maketerm /
# isexpr dispatch correctly to Giac's introspection methods on GiacExpr.

using TermInterface

@testset "TermInterface extension" begin

    @giac_var x y

    # ========================================================================
    # iscall / isexpr
    # ========================================================================

    @testset "iscall and isexpr" begin
        # Compound expressions
        @test TermInterface.iscall(sin(x)) == true
        @test TermInterface.iscall(x + y) == true
        @test TermInterface.iscall(x * y) == true
        @test TermInterface.isexpr(sin(x)) == true

        # Atomic
        @test TermInterface.iscall(x)              == false  # identifier
        @test TermInterface.iscall(giac_eval("1")) == false  # literal
        @test TermInterface.iscall(giac_eval("pi")) == false # constant
        @test TermInterface.isexpr(x) == false
    end

    # ========================================================================
    # operation
    # ========================================================================

    @testset "operation" begin
        @test TermInterface.operation(sin(x)) === sin
        @test TermInterface.operation(x + y) === +
        @test TermInterface.operation(x * y) === *
    end

    # ========================================================================
    # arguments
    # ========================================================================

    @testset "arguments" begin
        @test TermInterface.arguments(sin(x))           == [x]
        @test length(TermInterface.arguments(x + y))    == 2
        @test TermInterface.arguments(giac_eval("a*b*c")) |> length == 3
    end

    # ========================================================================
    # maketerm
    # ========================================================================

    @testset "maketerm" begin
        # Reconstruct sin(x) from op + args.
        rebuilt = TermInterface.maketerm(GiacExpr, sin, (x,))
        @test rebuilt isa GiacExpr
        @test string(rebuilt) == "sin(x)"

        # 2 + 3 == 5
        @test TermInterface.maketerm(
                GiacExpr, +, (giac_eval("2"), giac_eval("3"))
              ) == giac_eval("5")
    end

    # ========================================================================
    # End-to-end consistency: arguments(maketerm(op, args)) == args
    # ========================================================================

    @testset "round-trip" begin
        original = sin(x + 1)
        @test TermInterface.iscall(original)
        op = TermInterface.operation(original)
        args = TermInterface.arguments(original)
        rebuilt = TermInterface.maketerm(GiacExpr, op, Tuple(args))
        @test string(rebuilt) == string(original)
    end
end
