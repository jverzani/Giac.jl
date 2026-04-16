# Tests for symbolic comparison operators (064-symbolic-comparison-operators)
# This file tests <, >, <=, >= operators returning GiacExpr for symbolic inequalities.

using Test
using Giac
using Giac.Commands: assume, about, sign, purge, additionally

@testset "Comparison Operators (064-symbolic-comparison-operators)" begin

    # ========================================================================
    # User Story 1: Build symbolic inequalities (Priority: P1) - MVP
    # ========================================================================

    @testset "US1: Less-than operator (<) between GiacExpr" begin
        x = giac_eval("x")
        y = giac_eval("y")
        result = x < y
        @test result isa GiacExpr
        # GIAC may normalize x<y to y>x — check both representations
        s = string(result)
        @test occursin("<", s) || occursin(">", s)
    end

    @testset "US1: Greater-than operator (>) between GiacExpr" begin
        x = giac_eval("x")
        y = giac_eval("y")
        result = x > y
        @test result isa GiacExpr
        @test occursin(">", string(result))
    end

    @testset "US1: Less-than-or-equal operator (<=) between GiacExpr" begin
        x = giac_eval("x")
        y = giac_eval("y")
        result = x <= y
        @test result isa GiacExpr
        # GIAC may normalize x<=y to y>=x — check both representations
        s = string(result)
        @test occursin("<=", s) || occursin(">=", s)
    end

    @testset "US1: Greater-than-or-equal operator (>=) between GiacExpr" begin
        x = giac_eval("x")
        y = giac_eval("y")
        result = x >= y
        @test result isa GiacExpr
        @test occursin(">=", string(result))
    end

    @testset "US1: Regression — existing operators unaffected" begin
        x = giac_eval("x")
        y = giac_eval("y")

        # == still returns Bool
        @test (x == x) isa Bool
        @test x == x
        @test !(x == y)

        # ~ still returns GiacExpr
        @test (x ~ y) isa GiacExpr

        # hash still works for Dict/Set
        d = Dict(x => 1, y => 2)
        @test d[x] == 1
        @test d[y] == 2
        s = Set([x, y])
        @test length(s) == 2
    end

    # ========================================================================
    # User Story 2: Use with assume and additionally (Priority: P1)
    # ========================================================================

    @testset "US2: assume(x > 0) sets assumption" begin
        x = giac_eval("x")
        assume(x > 0)
        @test sign(x) == giac_eval("1")
        about_str = string(about(x))
        @test occursin("assume", about_str)
        purge(x)
    end

    @testset "US2: purge clears assumption" begin
        x = giac_eval("x")
        assume(x > 0)
        purge(x)
        @test string(about(x)) == "x"
    end

    @testset "US2: assume + additionally for interval constraints" begin
        x = giac_eval("x")
        assume(x > giac_eval("-1"))
        additionally(x < giac_eval("1"))
        about_str = string(about(x))
        @test occursin("assume", about_str)
        purge(x)
    end

    # ========================================================================
    # User Story 3: Mixed-type comparisons (Priority: P2)
    # ========================================================================

    @testset "US3: GiacExpr vs Int" begin
        x = giac_eval("x")
        @test (x > 0) isa GiacExpr
        @test (x < 0) isa GiacExpr
        @test (x >= 1) isa GiacExpr
        @test (x <= -1) isa GiacExpr
    end

    @testset "US3: Int vs GiacExpr" begin
        x = giac_eval("x")
        @test (0 < x) isa GiacExpr
        @test (0 > x) isa GiacExpr
        @test (1 <= x) isa GiacExpr
        @test (-1 >= x) isa GiacExpr
    end

    @testset "US3: GiacExpr vs Float64" begin
        x = giac_eval("x")
        @test (x > 1.5) isa GiacExpr
        @test (x < 1.5) isa GiacExpr
    end

    @testset "US3: GiacExpr vs Rational" begin
        x = giac_eval("x")
        @test (x > 1//2) isa GiacExpr
        @test (x >= 1//3) isa GiacExpr
    end

    @testset "US3: GiacExpr vs Irrational" begin
        x = giac_eval("x")
        @test (x > π) isa GiacExpr
        @test (x <= ℯ) isa GiacExpr
    end

    @testset "US3: Edge cases" begin
        x = giac_eval("x")

        # Self-comparison returns GiacExpr (not Bool)
        result = x > x
        @test result isa GiacExpr

        # Infinity comparisons
        @test (x > Inf) isa GiacExpr
        @test (x < -Inf) isa GiacExpr
    end

    # ========================================================================
    # Logical operators & and | for combining inequalities
    # ========================================================================

    @testset "Logical AND (&) between GiacExpr" begin
        x = giac_eval("x")
        result = (x > 0) & (x < 10)
        @test result isa GiacExpr
        s = string(result)
        @test occursin("and", s)
    end

    @testset "Logical OR (|) between GiacExpr" begin
        x = giac_eval("x")
        result = (x < -1) | (x > 1)
        @test result isa GiacExpr
        s = string(result)
        @test occursin("or", s)
    end

    @testset "assume with interval via & operator" begin
        x = giac_eval("x")
        assume((x > 0) & (x < 10))
        @test sign(x) == giac_eval("1")
        about_str = string(about(x))
        @test occursin("assume", about_str)
        purge(x)
    end

end
