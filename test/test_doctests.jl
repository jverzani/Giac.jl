using Test
using Documenter
using Giac

DocMeta.setdocmeta!(Giac, :DocTestSetup, :(using Giac); recursive=true)

@testset "Doctests" begin
    doctest(Giac; manual=false)
end
