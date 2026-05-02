# Creating Julia Functions from Expressions

Giac.jl lets you build symbolic expressions and then wrap them into regular Julia functions. The recommended named entry point is [`build_function`](@ref); under the hood it composes [`substitute`](@ref) and [`to_julia`](@ref), and you can always drop down to those primitives directly.

## Basic Idea

A symbolic expression like `x^2 - 1` lives in the Giac engine. To evaluate it at a specific point, substitute the symbolic variable with a value, then convert the result to a native Julia type:

```julia
using Giac

@giac_var x
expr = x^2 - 1

# Wrap into a Julia function
f(_x) = to_julia(substitute(expr, x => _x))

f(3)   # 8
f(0)   # -1
f(-2)  # 3
```

## Using `build_function`

`build_function(expr, vars...)` is the named convenience wrapper for exactly the pattern above. It returns a Julia callable that you can pass to `Plots.plot`, `Plots.surface`, broadcasting (`f.(xs)`), and matrix comprehensions — without writing the `substitute` + `to_julia` line every time.

```julia
using Giac

@giac_var x
f = build_function(x^2 - 1, x)

f(3)            # 8
f.([0, 1, 2])   # [-1, 0, 3]
```

For multivariate expressions, list the variables in the desired positional order:

```julia
@giac_var x y
g = build_function(x^2 + 2*x*y - y^2, x, y)

g(1, 2)  # 1
g(3, 1)  # 14
```

`build_function` is intentionally a *thin* wrapper. It does not introduce any new substitution mechanism: the result of `build_function(expr, vars...)(vals...)` is always equal to `to_julia(substitute(expr, Pair.(vars, vals)...))`. If you need to insert a transformation between substitution and conversion (e.g., `simplify`, `expand`, `evalf` at custom precision), drop down to the primitives directly rather than expecting `build_function` to grow new keyword arguments for every variant.

### Comparison with SymPy and Symbolics.jl

| Library | Function | Signature | Returns | Notes |
|---|---|---|---|---|
| **Giac.jl** | `build_function` | `build_function(expr::GiacExpr, vars::GiacExpr...)` | Julia callable (`<: Function`) | Tier 1 wrapper over `substitute` + `to_julia`; each call goes through the Giac FFI. |
| **Symbolics.jl** | `build_function` | `build_function(expr, args...; kwargs...)` | Julia function (in-house codegen) | Walks the expression tree and emits native Julia code. SciML standard. |
| **SymPy.jl** | `lambdify` | `lambdify(expr, vars; fns=...)` | Julia function | Translates a SymPy expression into a Julia function via a Python intermediary. |

```@docs
build_function
```

### Choosing a backend

`build_function` accepts a `backend::Symbol` keyword that selects the engine
that evaluates the substituted expression. As of Giac.jl v0.14:

| Backend | Default? | Requires | Performance | Autodiff-friendly | Restricted heads? |
|---|---|---|---|---|---|
| `:giac` | ✅ | nothing extra | one FFI call per evaluation | ❌ | no — every GIAC head works |
| `:symbolics` | — | `using Symbolics` | compiled once, cheap per call | ✅ (ForwardDiff, SciML) | yes — only heads `to_symbolics` translates |

The two backends agree numerically on the supported subset (within `1e-10`).
Pick `:symbolics` when you need speed in a hot loop or when downstream code
expects an autodiff-able function. Stay on the default `:giac` for one-off
evaluation or when your expression contains heads outside the `to_symbolics`
map.

#### Side-by-side equivalence

```julia
using Giac, Symbolics

@giac_var x
expr = sin(x)^2 + cos(x)^2   # equals 1 mathematically

f_giac = Giac.build_function(expr, x; backend = :giac)
f_sym  = Giac.build_function(expr, x; backend = :symbolics)

xs = -2.0:0.01:2.0
all(isapprox.(f_giac.(xs), f_sym.(xs); atol = 1e-10))   # true
```

#### Speed

```julia
using Giac, Symbolics

@giac_var x y
expr = sin(x)*cos(y) + (x + y)^3

f_giac = Giac.build_function(expr, x, y; backend = :giac)
f_sym  = Giac.build_function(expr, x, y; backend = :symbolics)

xs = randn(10_000); ys = randn(10_000)

f_giac(xs[1], ys[1]); f_sym(xs[1], ys[1])   # warm up

t1 = @elapsed for i in 1:10_000; f_giac(xs[i], ys[i]); end
t2 = @elapsed for i in 1:10_000; f_sym(xs[i], ys[i]);  end

println("speedup: ", round(t1 / t2; digits = 1), "×")
```

The `:symbolics` backend is typically at least an order of magnitude faster
on hot-loop workloads — for the expression above, a representative laptop
measurement records `:giac` at ~335 ms and `:symbolics` at ~2.4 ms over
10 000 calls, a **141× speedup**. Exact ratios depend on the expression
and hardware.

#### Autodiff

```julia
using Giac, Symbolics, ForwardDiff

@giac_var x
f_sym = Giac.build_function(x^3 - 2x + 1, x; backend = :symbolics)

ForwardDiff.derivative(f_sym, 2.0)   # 10.0  ( = 3·4 - 2 )
```

The `:giac` backend cannot do this — each call is opaque to `ForwardDiff`.

#### Naming caveat: qualify when both packages are loaded

`Symbolics` also exports `build_function`. With both `using Giac` and
`using Symbolics` in scope, the bare name is ambiguous and Julia raises
`UndefVarError`. Write `Giac.build_function(...)` (or
`Symbolics.build_function(...)` for the Symbolics-specific call sites).

#### Error paths

| Situation | Error |
|---|---|
| `backend = :symbolics` without `using Symbolics` | `ArgumentError` naming Symbolics |
| Free symbol not bound by `vars` (`:symbolics` only) | `ArgumentError` listing the unbound names; recovery: bind it or use `:giac` |
| GIAC head with no `to_symbolics` translation | Error from `to_symbolics` naming the head; recovery: use `:giac` |
| Unknown `backend` value | `ArgumentError` naming the bad symbol |

## Step by Step

### 1. Declare symbolic variables

```julia
@giac_var x
```

This creates `x` as a `GiacExpr` representing the symbolic variable `x`.

### 2. Build the expression

```julia
expr = x^2 - 1
```

Standard arithmetic operators (`+`, `-`, `*`, `/`, `^`) work on `GiacExpr` and produce new symbolic expressions.

You can also use `giac_eval` to parse more complex expressions:

```julia
expr = giac_eval("sin(x)^2 + cos(x)^2")
```

### 3. Define the Julia function

```julia
f(_x) = to_julia(substitute(expr, x => _x))
```

This function:
1. Substitutes `x` with the argument `_x` using [`substitute`](@ref)
2. Converts the resulting `GiacExpr` to a native Julia type using [`to_julia`](@ref)

!!! note
    We use `_x` as the function parameter to avoid shadowing the symbolic variable `x`.

## Multivariate Functions

For expressions with multiple variables, use a `Dict` for substitution:

```julia
@giac_var x y
expr = x^2 + 2*x*y - y^2

f(_x, _y) = to_julia(substitute(expr, Dict(x => _x, y => _y)))

f(1, 2)   # 1 + 4 - 4 = 1
f(3, 1)   # 9 + 6 - 1 = 14
```

## Staying Symbolic

If you want the result to remain a `GiacExpr` (e.g., for further symbolic manipulation), skip the `to_julia` call:

```julia
@giac_var x
expr = x^2 - 1

f(_x) = substitute(expr, x => _x)

f(3)             # GiacExpr: "8"
f(giac_eval("a"))  # GiacExpr: "a^2-1"
```

This is useful when the argument itself is symbolic.

## Using Giac Commands in Expressions

Expressions built with Giac commands work the same way:

```julia
using Giac.Commands: sin, cos, integrate

@giac_var x

# Build a symbolic expression using Giac functions
expr = integrate(sin(x) * cos(x), x)

# Evaluate at specific points
f(_x) = to_julia(substitute(expr, x => _x))
```

## Matrix-Valued Functions

The pattern extends to `GiacMatrix` since [`substitute`](@ref) supports element-wise substitution:

```julia
@giac_var x
M = GiacMatrix([x x+1; 2*x x^2])

f(_x) = substitute(M, x => _x)

f(3)   # [[3, 4], [6, 9]]
```

## Defining Functions in the Giac Engine

Instead of wrapping Julia around a symbolic expression, you can define functions directly in the Giac engine using `giac_eval`. The Giac context is persistent within a Julia session, so definitions survive across calls.

### Simple Function Definition (`:=`)

```julia
using Giac

# Define a Giac function
giac_eval("f(x) := x^2 - 1")

# Call it from Julia
to_julia(giac_eval("f(5)"))    # 24
to_julia(giac_eval("f(0)"))    # -1
```

### Piecewise Functions (`ifte`)

For conditional logic, use Giac's `ifte` (if-then-else):

```julia
giac_eval("mysqcu(x) := ifte(x > 0, x^2, x^3)")

to_julia(giac_eval("mysqcu(5)"))    # 25
to_julia(giac_eval("mysqcu(-5)"))   # -125
```

### Procedures (`proc ... end`)

For more complex logic with local variables and control flow, use Giac's `proc` syntax:

```julia
giac_eval("g := proc(x) local res; if x > 0 then res:=x^2 else res:=x^3 fi; res end")

to_julia(giac_eval("g(5)"))    # 25
to_julia(giac_eval("g(-5)"))   # -125
```

!!! note
    With `proc`, use the `name := proc(...) ... end` syntax (not `name(x) := proc(...)`).
    Declare local variables with `local`. The last expression before `end` is the return value.

### Multivariate Giac Functions

```julia
giac_eval("h(x, y) := x^2 + 2*x*y - y^2")

to_julia(giac_eval("h(1, 2)"))   # 1
to_julia(giac_eval("h(3, 1)"))   # 14
```

### Wrapping Giac Functions as Julia Callables

You can combine a Giac function definition with a Julia wrapper for a clean interface:

```julia
# Define in Giac
giac_eval("mysqcu(x) := ifte(x > 0, x^2, x^3)")

# Wrap in Julia
mysqcu(_x) = to_julia(giac_eval("mysqcu($_x)"))

mysqcu(5)    # 25
mysqcu(-5)   # -125
```

### Context Persistence

All Giac function definitions persist within the same Julia session. They are stored in the default `GiacContext` created at module initialization:

```julia
# Define a function
giac_eval("double(x) := 2*x")

# Use it in another expression later
giac_eval("double(21)")   # 42

# Use it inside other Giac definitions
giac_eval("quadruple(x) := double(double(x))")
giac_eval("quadruple(10)")   # 40
```

## Performance Considerations

Each call to `f(_x)` goes through the Giac engine (substitution + evaluation). For performance-critical code with many evaluations, consider:

- **Precompiling to a native Julia function** using `eval` and `Meta.parse` on the string representation
- **Caching results** if the same arguments are used repeatedly
- **Using `Float64` inputs** to avoid unnecessary symbolic processing

## Summary

| Pattern | Returns | Use case |
|---------|---------|----------|
| `f = build_function(expr, x)` | Native Julia type | Recommended named entry point for plotting / broadcasting |
| `f(_x) = to_julia(substitute(expr, x => _x))` | Native Julia type | Manual form; use when you need a custom step between substitution and conversion |
| `f(_x) = substitute(expr, x => _x)` | `GiacExpr` | Further symbolic work |
| `f(_x, _y) = to_julia(substitute(expr, Dict(x => _x, y => _y)))` | Native Julia type | Multivariate evaluation |
| `giac_eval("f(x) := ...")` then `giac_eval("f(5)")` | `GiacExpr` | Giac-native function |
| `giac_eval("g := proc(x) ... end")` then `giac_eval("g(5)")` | `GiacExpr` | Procedures with control flow |

## See Also

- [Variable Substitution](@ref) for full details on `substitute`
- [Symbolic variables](@ref) for `@giac_var` usage
