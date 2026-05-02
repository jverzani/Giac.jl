### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000001
begin
	using Giac
	using Symbolics
	using Groebner   # enables Symbolics.symbolic_solve on multivariate systems (used in §7)
	using Pkg
end

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000000
md"""
# Giac.jl × Symbolics.jl — Bridge Notebook

## Overview

**Part A — The bridge.** How `to_giac` and `to_symbolics` move expressions between the two systems, and what's preserved on the way.

**Part B — Gap showcase.** Operations where a `Symbolics.jl` workflow benefits from a quick round-trip through GIAC: polynomial factorization, partial fractions, Laplace transforms, large-integer factorization, resultants, Diophantine equations, exact transcendental solutions, square-free & discriminant.

---

## The extension in one line

When both `Giac.jl` and `Symbolics.jl` are loaded, Giac activates its `GiacSymbolicsExt` extension and exports:

- `to_giac(::Num) -> GiacExpr` — Symbolics expression → GIAC expression
- `to_symbolics(::GiacExpr) -> Num` — GIAC expression → Symbolics expression

Both are tree-traversal converters — expression structure is rebuilt node by node using the C++ `Gen` constructors, not via a `string(expr)` → `giac_eval` round-trip. Integer handling specifically (per [`ext/GiacSymbolicsExt.jl:164-174`](../ext/GiacSymbolicsExt.jl#L164-L174), [`ext/GiacSymbolicsExt.jl:98-131`](../ext/GiacSymbolicsExt.jl#L98-L131)):

- `Int32`-range integer → `Gen(Int32)` constructor — direct.
- `BigInt` → GMP `__gmpz_export` + `make_zint_from_bytes` — direct binary transfer.
- `Int64` outside the `Int32` range → `Gen(string(n))` — the one string-based path.

Rationals, complex numbers, and the canonical mathematical constants `π`, `ℯ`, `i` are also preserved. Full API details live in [`docs/src/extensions/symbolics.md`](../docs/src/extensions/symbolics.md) and the source in [`ext/GiacSymbolicsExt.jl`](../ext/GiacSymbolicsExt.jl).

**Versions used when this notebook was last authored:** Julia 1.12.6, `Giac v0.11.2`, `Symbolics v7.19.0`, `Groebner v0.10.3`, `SymbolicUtils v4.24.2`. Claims about *what Symbolics does or does not do* are version-dependent — the cell below prints the versions actually loaded at runtime, so the reader can confirm what is being observed.
"""

# ╔═╡ 1a17980a-d7b0-4a7c-a823-2acaee00feae
# ╠═╡ disabled = true
#=╠═╡
begin
	#using Pkg
	#Pkg.add("Giac")
	#Pkg.add("Symbolics")
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	#Pkg.develop(PackageSpec(path=".."))
end
  ╠═╡ =#

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000005ff
let
	pkgs = ["Julia" => string(VERSION)]
	deps = Pkg.dependencies()
	for name in ("Giac", "Symbolics", "Groebner", "SymbolicUtils")
		for (_, info) in deps
			if info.name == name && info.version !== nothing
				push!(pkgs, name => "v$(info.version)")
				break
			end
		end
	end
	pkgs
end

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000500
md"""
---

# Part A — The Bridge

## A.1  Setting up shared symbolic variables

The rest of the notebook uses `x` as the primary symbolic variable on the Symbolics side. Create it once:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000011
@variables x

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000501
md"""
---

## A.2  `to_giac(::Num) → GiacExpr`

`to_giac` walks the Symbolics expression tree and builds the corresponding GIAC expression. Concrete-number literals keep their type; identifiers become GIAC identifiers; compound expressions are rebuilt with the matching GIAC operator.
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000502
md"""
**Integer literals** pass through as exact integers (not floats):
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000503
to_giac(Num(42))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000504
md"""
**`BigInt`** is transferred directly via GMP (no string round-trip):
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000505
to_giac(Num(big(2)^100))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000506
md"""
**Symbolic expressions** become GIAC expression trees. The surface syntax differs slightly (`1+x^2+2*x` vs `1 + 2x + x^2`) but the expression is the same:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000507
to_giac(x^2 + 2x + 1)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000508
md"""
**Julia math functions** map to their GIAC counterparts; GIAC's `ln` is the one exception to the common-name rule and is handled automatically when the Julia input is `log`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000509
to_giac(sin(x) + cos(x) + log(x))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000050c
md"""
---

## A.3  `to_symbolics(::GiacExpr) → Num`

The reverse traversal rebuilds a Symbolics `Num`. The key design choice is **preservation of symbolic structure** — GIAC results containing `sqrt`, factorized forms, or mathematical constants are not evaluated to floating-point approximations.

(On the forward direction, there is a known limitation with bare Julia `Irrational` wrappers like `Num(π)`; the reverse direction below handles GIAC's own `pi` / `e` / `i` cleanly.)
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000050d
md"""
`sqrt(2)` stays symbolic — you do *not* get `1.4142135623730951`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000050e
to_symbolics(giac_eval("sqrt(2)"))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000050f
md"""
`π` from GIAC becomes `Symbolics.pi` (not the Julia `Irrational`):
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000510
to_symbolics(giac_eval("pi"))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000511
md"""
Factorized forms coming out of `ifactor` or `factor` keep their factored structure — the `2^3·5^3` is **not** collapsed to `1000`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000512
to_symbolics(Giac.Commands.ifactor(to_giac(Num(1000))))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000513
to_symbolics(Giac.Commands.factor(to_giac(x^2 - 1)))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000514
md"""
---

## A.4  Round-trip

`to_symbolics ∘ to_giac` round-trips arithmetic expressions cleanly. Note that the Symbolics printer may choose a slightly different surface form (operand ordering) but the expression is mathematically identical:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000515
round_trip_in = x^2 + 2x + 1

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000516
to_symbolics(to_giac(round_trip_in))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000517
md"""
---

# Part B — Gap showcase

The rest of the notebook pairs an **actual Symbolics attempt** (what it returns today for the operation) with the **Giac result via the bridge**.

**Scope note.** This compares Giac with `Symbolics.jl` *itself* as loaded here — not the whole Julia ecosystem (AbstractAlgebra.jl, Nemo/Oscar, ModelingToolkit, Groebner, Primes, etc., which may cover some of the same ground under other names). The authoritative evidence of what Symbolics is *missing* is the Symbolics issue tracker; attempted computations below are illustrative complements, not exhaustive proofs of absence.

Referenced Symbolics issues (authoritative):

- [#59 — Feature completeness against SymPy](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59)
- [#249 — Partial fraction decomposition](https://github.com/JuliaSymbolics/Symbolics.jl/issues/249)
- [#1770 — Laplace and inverse Laplace transforms](https://github.com/JuliaSymbolics/Symbolics.jl/issues/1770)

Referenced Symbolics pull requests (in-flight attempts at closing gaps shown below):

- [PR #1843 — Polynomial algebra (factor / sqrfree / discriminant / resultant)](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843) — AI-generated draft targeting §2, §6, §9 of this notebook; unmerged as of this writing. When the cells below were authored, Symbolics v7.19.0 was loaded, i.e. *without* the PR.
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000002
md"""
---

## A note on name conflicts

Both `Giac.Commands` and `Symbolics` export `simplify`. When both packages are loaded, **qualify the call** so the intent is clear:

```julia
Giac.Commands.simplify(g)   # use GIAC's simplifier
Symbolics.simplify(s)       # use Symbolics' simplifier
```

The same applies to other overlapping names (`expand`, `factor`, etc.).
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000010
md"""
---

## 1. Trigonometric simplification

`simplify(tan(x) - sin(x)/cos(x))` is identically zero, but Symbolics won't reduce it on its own. Round-trip through GIAC:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000012
sym_expr = tan(x) - sin(x)/cos(x)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000013
Giac.Commands.simplify(to_giac(sym_expr))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000014
md"""
And the result as a Symbolics `Num`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000015
to_symbolics(Giac.Commands.simplify(to_giac(sym_expr)))

# ╔═╡ e3dc151c-0ee8-4a20-b3b6-63208449e358
Symbolics.simplify(sym_expr)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000020
md"""
---

## 2. Polynomial factorization

Tracked in [#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59) under *Polynomials → Factorization* (unchecked as of this notebook). In-flight attempt: [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843).

`Symbolics.factor` exists but delegates to `Primes.factor` — it **only handles integers** and raises `MethodError` on a polynomial:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000021
poly = x^4 - 1

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000f1
# Uncomment to reproduce the MethodError:
# Symbolics.factor(poly)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000f2
try
	Symbolics.factor(poly)
catch e
	string(typeof(e), ": ", sprint(showerror, e))
end

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000022
Giac.Commands.factor(to_giac(poly))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000023
to_symbolics(Giac.Commands.factor(to_giac(poly)))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000f3
md"""
**Symbolics-side attempt from [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843).** The PR adds a two-argument `Symbolics.factor(f, var)` that returns `(unit, [(factor, multiplicity), …])` — **not exported**, to avoid shadowing `Base.factor` / `Primes.factor`. Once merged, the native call would be:

```julia
u, fs = Symbolics.factor(x^4 - 1, x)
# → (1, [(x - 1, 1), (x + 1, 1), (x^2 + 1, 1)])
```

Higher-degree residuals (≥ 4 with no rational root) delegate to `Nemo.factor` through `SymbolicsNemoExt` when `Nemo` is loaded.
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000030
md"""
---

## 3. Partial fraction decomposition

Tracked in [#249](https://github.com/JuliaSymbolics/Symbolics.jl/issues/249) (open).

Symbolics' closest rational manipulators — `simplify`, `simplify_fractions`, `expand` — all leave a rational unchanged. None decompose into partial fractions:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000031
rational = x / (x^2 - 1)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000f4
Symbolics.simplify_fractions(rational)  # returns x/(x^2-1) — not a PFD

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000032
Giac.Commands.partfrac(to_giac(rational))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000033
to_symbolics(Giac.Commands.partfrac(to_giac(rational)))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000040
md"""
---

## 4. Laplace transform

Tracked in [#1770](https://github.com/JuliaSymbolics/Symbolics.jl/issues/1770); [PR #1590](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1590) proposed a `laplace`/`ilaplace` implementation but is open / unmerged (as of this writing). Symbolics itself exposes no Laplace transform.

Transform ``f(t) = e^{-t}\\cos(t)`` into ``F(s)`` via GIAC:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000041
@variables t s

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000042
f_t = exp(-t) * cos(t)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000043
F_s = Giac.invoke_cmd(:laplace, to_giac(f_t), to_giac(t), to_giac(s))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000044
to_symbolics(F_s)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000045
md"""
### Inverse Laplace

$$\mathcal{L}^{-1}\!\left\{\dfrac{1}{s^2+1}\right\} = \sin(t)$$
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000046
F_inv = 1 / (s^2 + 1)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000047
to_symbolics(Giac.invoke_cmd(:ilaplace, to_giac(F_inv), to_giac(s), to_giac(t)))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000050
md"""
---

## 5. Integer factorization

Symbolics does not ship an integer factorizer — `Symbolics.factor` on an `Integer` delegates to `Primes.factor`. `Primes.jl` handles moderate sizes (trial division + Pollard rho) but stalls on balanced 60-digit semiprimes; [PR #173](https://github.com/JuliaMath/Primes.jl/pull/173) adds an ECM + MPQS polyalgorithm for the 50–60-digit range.

Giac's `ifactor` / `ifactors` already runs that range. First, the classic Mersenne number ``2^{67} - 1`` (Cole 1903):
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000051
mersenne67 = big(2)^67 - 1

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000052
Giac.Commands.ifactors(mersenne67)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000f7
md"""
`ifactor` returns the product form; `ifactors` returns an alternating list `[p₁, e₁, p₂, e₂, …]`.

Now a **60-digit balanced semiprime** (two 30-digit primes). `Primes.factor` times out here today (>120 s on this machine); Giac returns in a few seconds:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000fa
semiprime60 = parse(BigInt, "632459103267572196107100983820469021721602147490918660274601")

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000fb
@elapsed Giac.Commands.ifactors(semiprime60)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000fc
Giac.Commands.ifactors(semiprime60)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000053
md"""
Same `ifactor` call, but driven through a Symbolics `Num`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000054
to_symbolics(Giac.Commands.ifactor(to_giac(Num(mersenne67))))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000060
md"""
---

## 6. Resultants

Tracked in [#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59) under *Polynomials → Resultants* (unchecked). In-flight attempt: [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843). `AbstractAlgebra.jl` and `Nemo.jl` implement resultants for their own polynomial types; Symbolics itself has no `resultant` on `Num` in v7.19.0.

$\mathrm{Res}_x(x^2 - 1,\; x^2 - 4) = 9$
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000061
p1 = x^2 - 1

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000062
p2 = x^2 - 4

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000063
Giac.Commands.resultant(to_giac(p1), to_giac(p2), to_giac(x))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000064
md"""
**Symbolics-side attempt from [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843).** The PR adds `Symbolics.resultant(f, g, var; algorithm = :euclid | :sylvester)` with two algorithms that must agree on every valid input (PRS via extended Euclid, and the Sylvester-matrix determinant). Once merged:

```julia
Symbolics.resultant(x^2 - 1, x^2 - 4, x)                       # → 9
Symbolics.resultant(x^2 - 1, x^2 - 4, x; algorithm = :sylvester)  # → 9
Symbolics.resultant(a*x + b, c*x + d, x)                       # → a*d - b*c
```
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000080
md"""
---

## 7. Linear Diophantine equation — solving over ℚ vs ℤ

Tracked in [#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59) under *Diophantine equations* (unchecked).

We pass the **same symbolic equation** ``21 u + 28 v = 7`` to both solvers. `Symbolics.symbolic_solve` (with `Groebner` loaded) is an algebraic solver **over a field** — for a single equation in two unknowns it returns a 1-parameter rational family, parametrized by `v`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000081
@variables u v

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000008a
Symbolics.symbolic_solve(21u + 28v ~ 7, [u, v])

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000082
md"""
Output: `Dict(u => 1//3 - (4//3)*v, v => v)` — the line ``u = 1/3 - (4/3)v`` over ``\\mathbb{Q}``. Pick any rational `v` and you get a valid `(u, v) \\in \\mathbb{Q}^2` solution. But a Diophantine problem asks specifically for ``(u, v) \\in \\mathbb{Z}^2`` — most rational `v` give a non-integer `u`.

Giac's `isolve` solves the equation **over ℤ** and returns the integer-lattice parametric family — ``u = -1 + 4k,\\ v = 1 - 3k`` for ``k \\in \\mathbb{Z}`` (GIAC names the free parameter `_Z0`):
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000083
Giac.Commands.isolve(to_giac(21u + 28v) ~ 7)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000008b
md"""
The two parametric forms are consistent: substituting the Giac integer family into Symbolics' rational form gives the same line. Setting `v = 1 − 3k` in `u = 1/3 − (4/3)·v` gives `u = 1/3 − (4/3)(1 − 3k) = −1 + 4k`. ✓

If you already have three concrete integers and just want *one* witness pair, Giac also exposes the numeric helper `iabcuv(a, b, c)` — *not symbolic on input*: it takes three `Int` arguments and returns a single solution:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-60000000008c
Giac.Commands.iabcuv(21, 28, 7)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000090
md"""
---

## 8. Transcendental equation solving — exact vs float

Both sides use the Julia **rational** literal `1//2` (exact `Rational{Int}`), not `1/2` which is `Float64(0.5)`. The difference matters here — a rational input keeps everything exact up to the solver; a float input would contaminate the whole computation.

`Symbolics.symbolic_solve` handles the trig equation and reports the general family `π/3 + 2πk`, but **evaluates `π/3` as a float**:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000091
Symbolics.symbolic_solve(cos(x) ~ 1//2, x)

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000092
md"""
`1.0471975511965976` is `Float64(π/3)` — an approximation, not the symbolic constant. Giac keeps `π/3` exact (principal values only, no integer parameter):
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000093
Giac.Commands.solve(cos(to_giac(x)) ~ 1//2, to_giac(x))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000094
md"""
Tradeoff: Symbolics gives you the integer-indexed family but loses the exact constant; Giac gives the exact constants but only the principal values. For a downstream symbolic pipeline (further simplification, integration, LaTeX rendering), the exact form is usually what you want.
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a0
md"""
---

## 9. Square-free decomposition & discriminant

Tracked in [#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59) under *Polynomials* (unchecked). In-flight attempt: [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843). In v7.19.0, Symbolics has no `sqrfree` or `discriminant` on `Num`; searching under common alternative names (`squarefree`, `square_free`, `sqfree`, `disc`) returns nothing either.

`sqrfree(x⁵ − 2x⁴ + x³)` factors into distinct square-free pieces — here `(x − 1)²·x³`:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a3
poly_sqr = x^5 - 2x^4 + x^3

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a4
Giac.Commands.sqrfree(to_giac(poly_sqr))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a5
to_symbolics(Giac.Commands.sqrfree(to_giac(poly_sqr)))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a6
md"""
The discriminant of the general quadratic ``ax² + bx + c`` is ``b² − 4ac``:
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a7
@variables a b c

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a8
quad = a*x^2 + b*x + c

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000a9
Giac.Commands.discriminant(to_giac(quad), to_giac(x))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000aa
to_symbolics(Giac.Commands.discriminant(to_giac(quad), to_giac(x)))

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-6000000000ab
md"""
**Symbolics-side attempt from [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843).** The PR adds `Symbolics.sqrfree(f, var)` (Yun's algorithm, characteristic 0) and `Symbolics.discriminant(f, var)` (via the classical `(-1)^{n(n-1)/2} · Res(f, f') / lc(f)` identity). Once merged:

```julia
u, fs = Symbolics.sqrfree(x^5 - 2x^4 + x^3, x)
# → (1, [(x - 1, 2), (x, 3)])    # same (x − 1)²·x³ split shown above

Symbolics.discriminant(a*x^2 + b*x + c, x)   # → b^2 - 4*a*c
Symbolics.discriminant(x^3 - 3x + 2, x)      # → 0   (repeated root at x = 1)
```
"""

# ╔═╡ d1e2f3a4-b5c6-7890-abcd-600000000099
md"""
---

## Summary — demonstrated gaps

Only features shown above are listed here.

| Feature | Symbolics.jl attempt (what it returned) | Giac.jl command (what it returned) |
|---------|-----------------------------------------|------------------------------------|
| Trig simplification | `Symbolics.simplify(tan(x)−sin(x)/cos(x))` → `(-sin(x)+cos(x)·tan(x))/cos(x)` | `Giac.Commands.simplify` → `0` |
| Polynomial factorization ([PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843) proposes native `Symbolics.factor(f, x)`) | `Symbolics.factor(x⁴−1)` → `MethodError` (delegates to `Primes.factor`) | `factor(x⁴−1)` → `(x−1)(x+1)(x²+1)` |
| Partial fractions ([#249](https://github.com/JuliaSymbolics/Symbolics.jl/issues/249)) | `Symbolics.simplify_fractions(x/(x²−1))` → `x/(x²−1)` unchanged | `partfrac(x/(x²−1))` → `½/(x−1) + ½/(x+1)` |
| Laplace / inverse Laplace ([#1770](https://github.com/JuliaSymbolics/Symbolics.jl/issues/1770); [PR #1590](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1590) unmerged) | no `laplace`/`ilaplace` function | `laplace(e⁻ᵗcos t)` → `(s+1)/(s²+2s+2)`; `ilaplace(1/(s²+1))` → `sin(t)` |
| Integer factorization | `Primes.factor` stalls on 60-digit balanced semiprimes (context of [Primes.jl #173](https://github.com/JuliaMath/Primes.jl/pull/173), ECM+MPQS polyalg.) | `ifactors` returns the factorization of 2⁶⁷−1 and of the 60-digit semiprime in seconds |
| Resultants ([#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59); [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843) proposes `Symbolics.resultant(f, g, x; algorithm = :euclid|:sylvester)`) | `Num` has no `resultant` method | `resultant(x²−1, x²−4, x)` → `9` |
| Diophantine `a u + b v = c` ([#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59)) | `symbolic_solve` (with `Groebner`) → `Dict(u => 1//3 - 4//3 v, v => v)` — line over ℚ | `isolve(21u + 28v = 7)` → integer family `u = -1+4k, v = 1-3k`; `iabcuv` gives one witness `[-1,1]` |
| Transcendental solve — exact form | `symbolic_solve(cos(x)=1//2)` → `1.047… + 6.28…·k` (float for `π/3`) | `solve` → `[-π/3, π/3]` exact |
| Square-free decomposition ([#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59); [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843) proposes `Symbolics.sqrfree(f, x)`) | no `sqrfree`/`squarefree` on `Num` | `sqrfree` → `(x−1)²·x³` |
| Discriminant ([#59](https://github.com/JuliaSymbolics/Symbolics.jl/issues/59); [PR #1843](https://github.com/JuliaSymbolics/Symbolics.jl/pull/1843) proposes `Symbolics.discriminant(f, x)`) | no `discriminant` on `Num` | `discriminant(ax²+bx+c, x)` → `b²−4ac` |

**Pattern:** `to_giac → Giac.Commands.<op> → to_symbolics`.

Not covered (Symbolics already has equivalent support): Bessel, Airy, `sinint`/`cosint`/`expint`, `digamma`, `erf`, `gamma`, `series`/`taylor`.

See also:
- [`01_basics.jl`](01_basics.jl) — symbolic API foundations
- [`03_examples.jl`](03_examples.jl) — broader Giac showcase
- Extension source: [`ext/GiacSymbolicsExt.jl`](../ext/GiacSymbolicsExt.jl)
- Extension docs: [`docs/src/extensions/symbolics.md`](../docs/src/extensions/symbolics.md)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Giac = "e4421f97-9838-4fd0-9fa5-94f11373bf78"
Groebner = "0b43b601-686d-58a3-8a1c-6623616c7cd4"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
"""

# ╔═╡ Cell order:
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000000
# ╟─1a17980a-d7b0-4a7c-a823-2acaee00feae
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000001
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000005ff
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000500
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000011
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000501
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000502
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000503
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000504
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000505
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000506
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000507
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000508
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000509
# ╟─d1e2f3a4-b5c6-7890-abcd-60000000050c
# ╟─d1e2f3a4-b5c6-7890-abcd-60000000050d
# ╠═d1e2f3a4-b5c6-7890-abcd-60000000050e
# ╟─d1e2f3a4-b5c6-7890-abcd-60000000050f
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000510
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000511
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000512
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000513
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000514
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000515
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000516
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000517
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000002
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000010
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000012
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000013
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000014
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000015
# ╠═e3dc151c-0ee8-4a20-b3b6-63208449e358
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000020
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000021
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000f1
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000f2
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000022
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000023
# ╟─d1e2f3a4-b5c6-7890-abcd-6000000000f3
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000030
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000031
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000f4
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000032
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000033
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000040
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000041
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000042
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000043
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000044
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000045
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000046
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000047
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000050
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000051
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000052
# ╟─d1e2f3a4-b5c6-7890-abcd-6000000000f7
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000fa
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000fb
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000fc
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000053
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000054
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000060
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000061
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000062
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000063
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000064
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000080
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000081
# ╠═d1e2f3a4-b5c6-7890-abcd-60000000008a
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000082
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000083
# ╟─d1e2f3a4-b5c6-7890-abcd-60000000008b
# ╠═d1e2f3a4-b5c6-7890-abcd-60000000008c
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000090
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000091
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000092
# ╠═d1e2f3a4-b5c6-7890-abcd-600000000093
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000094
# ╟─d1e2f3a4-b5c6-7890-abcd-6000000000a0
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000a3
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000a4
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000a5
# ╟─d1e2f3a4-b5c6-7890-abcd-6000000000a6
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000a7
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000a8
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000a9
# ╠═d1e2f3a4-b5c6-7890-abcd-6000000000aa
# ╟─d1e2f3a4-b5c6-7890-abcd-6000000000ab
# ╟─d1e2f3a4-b5c6-7890-abcd-600000000099
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
