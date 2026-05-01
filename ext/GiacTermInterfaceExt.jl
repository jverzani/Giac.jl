# Extension module for TermInterface.jl integration.
#
# Implements TermInterface's iscall / operation / arguments / maketerm methods
# for `GiacExpr`, so that downstream packages built on TermInterface
# (Metatheory.jl, SymbolicUtils.jl, …) can traverse and rewrite Giac
# expressions as syntax trees.
#
# The core methods are defined in `Giac` itself (introspection.jl) so that
# `Giac.iscall(expr)` etc. always work without an extra dependency. This
# extension just bridges those into TermInterface's namespace when the user
# has TermInterface loaded.

module GiacTermInterfaceExt

using Giac
using TermInterface

TermInterface.iscall(g::GiacExpr)::Bool = Giac.iscall(g)

TermInterface.operation(g::GiacExpr) = Giac.operation(g)

TermInterface.arguments(g::GiacExpr)::Vector{GiacExpr} = Giac.arguments(g)

# `iscall` and `isexpr` typically agree for languages without explicit
# `term`-vs-`call` distinction. Giac doesn't carry that distinction either.
TermInterface.isexpr(g::GiacExpr)::Bool = Giac.iscall(g)

# Reconstruct an expression from an op + args. Mirrors the in-core helper.
TermInterface.maketerm(::Type{<:GiacExpr}, op, args, metadata=nothing)::GiacExpr =
    Giac.maketerm(GiacExpr, op, args, metadata)

end # module GiacTermInterfaceExt
