# build_function: convert a GiacExpr into a native Julia callable
# (066-build-function — Tier 1 wrapper over substitute + to_julia)

# Internal callable wrapper. The fixed-arity Vararg{Any, N} method on
# _BuildFunction{N} guarantees that calls with the wrong number of arguments
# fall through Julia's dispatcher as a real MethodError. Users never reference
# this type directly — they only see the value as a `<: Function` callable.
struct _BuildFunction{N} <: Function
    expr::GiacExpr
    vars::NTuple{N, GiacExpr}
end

(b::_BuildFunction{0})() = to_julia(b.expr)

(b::_BuildFunction{N})(vals::Vararg{Any, N}) where {N} =
    to_julia(b.expr(Pair.(b.vars, vals)...))

Base.show(io::IO, b::_BuildFunction{N}) where {N} =
    print(io, "build_function callable for ", b.expr, " over ", N, " variable(s)")

"""
    build_function(expr::GiacExpr, vars::GiacExpr...) -> Function

Wrap a symbolic `GiacExpr` into a native Julia callable, evaluated at runtime
through GIAC's substitution and Julia conversion pipeline.

The returned callable `f` satisfies the equivalence

```julia
f(vals...) ≡ to_julia(expr(Pair.((vars...,), (vals...,))...))
            ≡ to_julia(substitute(expr, vars[1] => vals[1], …, vars[N] => vals[N]))
```

So `build_function` is a thin convenience wrapper. It does not introduce any
new substitution or evaluation mechanism — it just gives the
`substitute` + `to_julia` chain a single named entry point that is suitable as
a drop-in argument to `Plots.plot`, `Plots.surface`, broadcasting (`f.(xs)`),
and matrix comprehensions.

# Arguments
- `expr::GiacExpr`: the symbolic expression to wrap.
- `vars::GiacExpr...`: the symbolic variables to bind, in positional order.

# Returns
A Julia callable (`<: Function`) of fixed arity `length(vars)` that, when
called, returns whatever `to_julia(...)` produces — typically `Bool`,
`Int64`, `BigInt`, `Float64`, `Rational`, `Complex`, `Vector`, `String`, or
`GiacExpr` (see [`to_julia`](@ref)). Calling with the wrong number of
arguments raises `MethodError` (Julia dispatch).

# Examples
```jldoctest
julia> @giac_var x;

julia> f = build_function(x^2 - 1, x);

julia> f(3)
8

julia> f(0)
-1
```

```jldoctest
julia> @giac_var x y;

julia> g = build_function(x + 2*y, x, y);

julia> g(1, 2)
5
```

# Equivalent manual form

`build_function` is a *thin convenience wrapper*. The same result is always
recoverable from the underlying primitives:

```julia
@giac_var x y
expr = x + 2*y

# Either of these gives identical values:
f1 = build_function(expr, x, y);             f1(1, 2)
f2(_x, _y) = to_julia(substitute(expr, x => _x, y => _y));  f2(1, 2)
```

If you need to insert a transformation between substitution and Julia
conversion (e.g., simplify, expand, evalf with custom precision), use
`substitute` and `to_julia` directly rather than expecting `build_function` to
grow new keyword arguments for every variant.

# Edge cases
- **Constant expression (zero `vars`).** `build_function(expr)()` returns
  `to_julia(expr)`. Symbolic constants such as `π` are reduced via
  `Giac.Commands.evalf` automatically (see [`to_julia`](@ref)).
- **Extra (unused) variables.** `build_function(x^2, x, y)(3, 100)` returns
  `9`; the unused `y` is silently ignored, matching `substitute`'s semantics.
- **Missing variables.** `build_function(x*y, x)(2)` returns a `GiacExpr`
  containing the still-free `y` (no error). To get a numeric value you must
  bind every free variable.
- **Mixed numeric input types.** `Int`, `Float64`, `Rational`, `BigInt`
  (and any value `substitute` accepts) flow through unchanged — whatever
  `substitute` + `to_julia` produces is what you get.
- **Argument-count mismatch.** Calling the returned callable with the wrong
  number of positional arguments raises `MethodError` via Julia dispatch.

# See also
- [`substitute`](@ref) — the underlying simultaneous-substitution primitive.
- [`to_julia`](@ref) — the Giac-to-Julia value converter (with auto-`evalf`).
- [`@giac_var`](@ref) — declare symbolic variables.
- `Symbolics.build_function` — the SciML analogue this function is named after.
- `SymPy.lambdify` — the SymPy.jl analogue for users coming from SymPy.
"""
build_function(expr::GiacExpr, vars::GiacExpr...) = _BuildFunction(expr, vars)
