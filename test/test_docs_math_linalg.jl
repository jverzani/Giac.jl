# Documentation Examples Tests: Linear Algebra (036-domain-docs-tests)
# Verifies all code examples in docs/src/mathematics/linear_algebra.md work correctly

@testset "Documentation Examples: Linear Algebra" begin
    using LinearAlgebra
    using Giac.Commands: eigenvalues, linsolve

    @testset "Matrix Creation" begin
        # Numeric matrix
        A = GiacMatrix([1 2; 3 4])
        @test A isa GiacMatrix
        @test size(A) == (2, 2)

        # Symbolic matrix
        @giac_var a b c d
        B = GiacMatrix([[a, b], [c, d]])
        @test B isa GiacMatrix

        # Symbol constructor
        M = GiacMatrix(:m, 3, 3)
        @test M isa GiacMatrix
        @test size(M) == (3, 3)
    end

    @testset "Determinant" begin
        A = GiacMatrix([1 2; 3 4])

        @test string(det(A)) == "-2"

        # Symbolic determinant
        @giac_var a b c d
        B = GiacMatrix([[a, b], [c, d]])
        result = string(det(B))
        @test contains(result, "a") && contains(result, "d") && contains(result, "b") && contains(result, "c")
    end

    @testset "Inverse" begin
        A = GiacMatrix([1 2; 3 4])

        Ainv = inv(A)
        @test Ainv isa GiacMatrix
        @test size(Ainv) == (2, 2)
    end

    @testset "Trace" begin
        A = GiacMatrix([1 2; 3 4])

        @test string(tr(A)) == "5"
    end

    @testset "Transpose" begin
        A = GiacMatrix([1 2; 3 4])

        At = transpose(A)
        @test At isa GiacMatrix
        @test size(At) == (2, 2)
    end

    @testset "Eigenvalues" begin
        A = GiacMatrix([2 1; 1 2])

        # Convert GiacMatrix to GiacExpr via ptr for eigenvalues command
        result = string(eigenvalues(GiacExpr(A.ptr)))
        @test contains(result, "1") && contains(result, "3")
    end

    @testset "Linear System Solving" begin
        @giac_var x y

        result = string(linsolve([x + y ~ 3, x - y ~ 1], [x, y]))
        @test contains(result, "2") && contains(result, "1")
    end

    @testset "Rank" begin
        A = GiacMatrix([1 2 3; 4 5 6; 7 8 9])

        # Use invoke_cmd because rank conflicts with LinearAlgebra.rank
        # Convert GiacMatrix to GiacExpr via ptr
        @test string(invoke_cmd(:rank, GiacExpr(A.ptr))) == "2"
    end

    @testset "Matrix Operations" begin
        A = GiacMatrix([1 2; 3 4])
        B = GiacMatrix([5 6; 7 8])

        # Addition
        C = A + B
        @test C isa GiacMatrix

        # Multiplication
        D = A * B
        @test D isa GiacMatrix

        # Scalar multiplication
        E = 2 * A
        @test E isa GiacMatrix
    end
end
