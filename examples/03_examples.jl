### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000001
begin
	using Giac
	using Giac.Commands
	using LinearAlgebra
end

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000000
md"""
# Giac.jl Examples

A comprehensive showcase of GIAC's computer algebra capabilities through Julia, organized by mathematical domain. All commands use the `Giac.Commands` API.
"""

# ╔═╡ 2715140c-b9b1-45ba-b0f9-7346e0473bb1
# ╠═╡ disabled = true
#=╠═╡
begin
	#using Pkg
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	#Pkg.develop(PackageSpec(path=".."))
end
  ╠═╡ =#

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000002
@giac_var x y z n k a b c d

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000010
md"""
---

## 1. Algebra

### `simplify` — Simplify an expression
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000011
hold_cmd(:simplify, giac_eval("4*atan(1/5) - atan(1/239)")) ~ simplify(giac_eval("4*atan(1/5) - atan(1/239)"))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000012
(sin(3*x) + sin(7*x)) / sin(5*x) ~ simplify(texpand((sin(3*x) + sin(7*x)) / sin(5*x)))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000013
md"""
### `collect` — Collect like terms / factor integers
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000014
hold_cmd(:collect, x + 2*x + 1 - 4) ~ collect(x + 2*x + 1 - 4)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000015
hold_cmd(:collect, x^2 - 9*x + 5*x + 3 + 1) ~ collect(x^2 - 9*x + 5*x + 3 + 1)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000016
md"""
### `expand` — Distribute multiplication over addition
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000017
(x + y) * (z + 1) ~ expand((x + y) * (z + 1))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000018
(a + b + c) / d ~ expand((a + b + c) / d)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000019
(x + 3)^4 ~ expand((x + 3)^4)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000001a
md"""
### `factor` — Factorize a polynomial
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000001b
hold_cmd(:factor, x^4 - 1) ~ factor(x^4 - 1)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000001c
hold_cmd(:factor, x^4 + 12*x^3 + 54*x^2 + 108*x + 81) ~ factor(x^4 + 12*x^3 + 54*x^2 + 108*x + 81)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000001d
md"""
### `partfrac` — Partial fraction decomposition
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000001e
hold_cmd(:partfrac, x / (4 - x^2)) ~ partfrac(x / (4 - x^2))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000001f
hold_cmd(:partfrac, (x^2 - 2*x + 3) / (x^2 - 3*x + 2)) ~ partfrac((x^2 - 2*x + 3) / (x^2 - 3*x + 2))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000020
md"""
---

## 2. Fractions & Equations

### `numerator` / `denominator` — Extract numerator and denominator
"""

# ╔═╡ 39d02d8d-2660-4c63-8d94-a637ee84a943
giac_eval("25/15")

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000021
numerator(giac_eval("25/15"))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000022
denominator(giac_eval("25/15"))

# ╔═╡ 360695e0-101b-47df-bafe-1942593ac232
(x^3 - 1) / (x^2 - 1)

# ╔═╡ 713c05cf-fc44-422c-8228-159041ef6947
simplify((x^3 - 1) / (x^2 - 1))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000023
numerator((x^3 - 1) / (x^2 - 1))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000024
denominator((x^3 - 1) / (x^2 - 1))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000025
md"""
### Equations with `~` operator

Use `~` to create symbolic equations (not boolean equality):
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000026
eq1 = x^2 - 1 ~ 2*x + 3

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000027
md"""
Extract left and right sides:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000028
left(eq1)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000029
right(eq1)

# ╔═╡ 3dde1763-7e94-4cb4-bc52-9a2bdfb12312
md"""
Swap left and right side
"""

# ╔═╡ da9ce357-d7bb-4efd-9fb4-276d1426e1d6
begin
	function swap_sides(eq)
	    right(eq) ~ left(eq)
	end
	
	swap_sides(eq1)
end

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000002a
md"""
### `substitute` — Replace variables in expressions
"""

# ╔═╡ 99a37002-7ee8-425f-ae13-cb01f2edadb7
x / (4 - x^2)

# ╔═╡ 91517640-8f32-4dd2-86a5-be9b006eb5ee
md"""with"""

# ╔═╡ c30acc26-fa4a-4e5f-8806-ba48daf6fb9a
x => giac_eval("3")

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000002b
substitute(x / (4 - x^2), x => giac_eval("3"))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000030
md"""
---

## 3. Calculus: Derivatives

### `diff` — Symbolic differentiation
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000031
hold_cmd(:diff, x^3 - x, x) ~ diff(x^3 - x, x)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000032
md"""
Higher-order derivatives (2nd, 3rd, ...):
"""

# ╔═╡ 744a8a67-2217-4f4d-a14e-620f5c4b408c
hold_cmd(:diff, x^3 - x, x, 2) ~ diff(x^3 - x, x, 2)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000034
md"""
Mixed partial derivatives:
"""

# ╔═╡ d2fad6f5-0c4e-45c0-b5a9-2979291b5124
exp(x*y)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000035
diff(exp(x*y), x, x, x, y, y)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000036
md"""
Gradient-like derivative with respect to a list of variables:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000037
diff(x*y + z*y, [y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000040
md"""
---

## 4. Calculus: Integration

### `integrate` — Symbolic integration

Indefinite integrals:
"""

# ╔═╡ 0ad15d89-6269-47f4-a8be-823c775a41a1
hold_cmd(:integrate, 1/x, x)

# ╔═╡ 698e46a1-aad5-4a1e-8956-185e49d7f740
integrate(1/x, x)

# ╔═╡ 9dffdc70-ac0f-4197-9569-9906c54ccdae
hold_cmd(:integrate, 1/(4+z^2))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000042
integrate(1/(4+z^2), z)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000043
md"""
Definite integrals with bounds:
"""

# ╔═╡ b9602cdc-aca4-45bb-abd3-e415803e9325
hold_cmd(:integrate, 1/(1-x^4), x, 2, 3)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000044
integrate(1/(1-x^4), x, 2, 3)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000050
md"""
---

## 5. Limits & Series

### `limit` — Compute limits
"""

# ╔═╡ 61d6b7bd-58c4-4ff7-838b-b2afcb141238
hold_cmd(:limit, sin(x)/x, x, 0) ~ limit(sin(x)/x, x, 0)

# ╔═╡ 10d0be2a-6503-49ee-958a-6669a8b9029e
hold_cmd(:limit, (n*tan(x)-tan(n*x))/(sin(n*x)-n*sin(x)), x, 0) ~ limit((n*tan(x)-tan(n*x))/(sin(n*x)-n*sin(x)), x, 0)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000052
hold_cmd(:limit, (2*x-1)/exp(1/(x-1)), x, Inf) ~ limit((2*x-1)/exp(1/(x-1)), x, Inf)

# ╔═╡ 92a6f8fb-1911-4dec-9337-6cf5f673ab89
hold_cmd(:limit, (2*x-1)/exp(1/(x-1)), x, Inf)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000054
md"""
One-sided limits (direction: 1 for right, -1 for left):
"""

# ╔═╡ c577424f-bc7b-422c-a820-0b2fc2d7d4cd
hold_cmd(:limit, sign(x), x, 0, 1) ~ limit(sign(x), x, 0, 1)

# ╔═╡ 90d822c0-f6da-4434-aaba-c5d21c83ce04
hold_cmd(:limit, sign(x), x, 0, -1) ~ limit(sign(x), x, 0, -1)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000057
md"""
### `series` / `taylor` — Series expansion
"""

# ╔═╡ 18665807-3610-4927-a5f7-64542002de07
hold_cmd(:series, (x^4+x+2)/(x^2+1), x, 0, 5)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000058
series((x^4+x+2)/(x^2+1), x, 0, 5)

# ╔═╡ e8db1c02-4eea-46af-8ede-d7cd6d115743
hold_cmd(:taylor, sin(x)/x, x, 0, 7)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000059
taylor(sin(x)/x, x, 0, 7)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000060
md"""
---

## 6. Discrete Sums

Use `invoke_cmd(:sum, ...)` since `sum` conflicts with Julia's `Base.sum`:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000061
hold_cmd(:sum, 1/n^2, n, 1, 17)

# ╔═╡ 97ef37a2-1cc5-418b-849a-f870ea497ff9
invoke_cmd(:sum, 1/n^2, n, 1, 17)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000062
md"""
Infinite series — the famous Basel problem:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000063
_result = hold_cmd(:sum, 1/n^2, n, 1, Inf)

# ╔═╡ 8e05925b-de16-49e9-b334-6c2912fea73c
release(_result)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000064
md"""
Sum of a list:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000065
hold_cmd(:sum, [1,2,3,4]) ~ invoke_cmd(:sum, [1,2,3,4])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000066
md"""
### Riemann sums
"""

# ╔═╡ 6a27b3c9-5fcd-4f84-ae80-da79dcebddbb
hold_cmd(:sum_riemann, 1 / (n + k), [n, k]) ~ sum_riemann(1 / (n + k), [n, k])

# ╔═╡ eb4be260-0366-4005-b566-1b417caba394
hold_cmd(:sum_riemann, n / (n^2+k^2), [n,k]) ~ sum_riemann(n / (n^2+k^2), [n,k])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-300000000001
md"""
### Products

The `product` command computes products (∏ notation). Since `Base.Iterators.product` shadows it, use `invoke_cmd` or `hold_cmd`:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-300000000002
hold_cmd(:product, k, k, 1, n) ~ invoke_cmd(:product, k, k, 1, n)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-300000000004
hold_cmd(:product, k, k, 1, 5) ~ invoke_cmd(:product, k, k, 1, 5)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-300000000005
hold_cmd(:product, 2*k, k, 1, 5) ~ invoke_cmd(:product, 2*k, k, 1, 5)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000070
md"""
---

## 7. Equation Solving

### `solve` — Symbolic solutions
"""

# ╔═╡ ba7561c5-9ac3-47f0-bc9c-fb293c14876f
hold_cmd(:solve, x^2 - 3 ~ 1, x)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000071
solve(x^2 - 3 ~ 1, x)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000072
md"""
System of linear equations:
"""

# ╔═╡ f7dac550-c45c-4663-bece-9394f58094dd
hold_cmd(:linsolve, [x+y+z~1, x-y~2, 2*x-z~3], [x,y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000073
linsolve([x+y+z~1, x-y~2, 2*x-z~3], [x,y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000074
md"""
Symbolic system:
"""

# ╔═╡ 04e51861-82e0-4d24-ab56-d0455a5b159c
hold_cmd(:linsolve, [n*x+y~a, x+n*y~b], [x,y])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000075
linsolve([n*x+y~a, x+n*y~b], [x,y])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000076
md"""
### `cSolve` — Complex-domain solving
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000077
cSolve(x^4 - 1 ~ 0, x)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000078
md"""
### `fSolve` — Numerical solving
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000079
fsolve(cos(x) ~ x, x)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000007a
md"""
### `deSolve` — Differential equations
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000007b
begin
	@giac_var y1(x)
	#deSolve(giac_eval("diff(y(x),x,x)+y(x)=0"), giac_eval("y"))
	#deSolve(giac_eval("diff(y(x),x,1)+y(x)=0"), giac_eval("y"))
	deSolve(D(y1)+y1 ~ 0, y1)
end

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000080
md"""
---

## 8. Vector Calculus

### `curl` — Vector curl
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000081
hold_cmd(:curl, [2*x*y, x*z, y*z], [x,y,z]) ~ curl([2*x*y, x*z, y*z], [x,y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000082
md"""
### `divergence` — Vector divergence
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000083
hold_cmd(:divergence, [x^2+y, x+z+y, z^3+x^2], [x,y,z]) ~ divergence([x^2+y, x+z+y, z^3+x^2], [x,y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000084
md"""
### `grad` — Gradient
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000085
hold_cmd(:grad, 2*x^2*y - x*z^3, [x,y,z]) ~ grad(2*x^2*y - x*z^3, [x,y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000086
md"""
### `hessian` — Hessian matrix
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000087
hold_cmd(:hessian, 2*x^2*y - x*z, [x,y,z]) ~ hessian(2*x^2*y - x*z, [x,y,z])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000090
md"""
---

## 9. Trigonometric Rewrites

GIAC provides many commands for rewriting trigonometric expressions.

### Expand / Linearize
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000091
hold_cmd(:trigexpand, sin(3*x)) ~ trigexpand(sin(3*x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000092
hold_cmd(:tlin, sin(x)^3) ~ tlin(sin(x)^3)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000093
hold_cmd(:tcollect, sin(x) + cos(x)) ~ tcollect(sin(x) + cos(x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000094
md"""
### Simplify with trig identities
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000095
hold_cmd(:trigsin, cos(x)^4 + sin(x)^2) ~ trigsin(cos(x)^4 + sin(x)^2)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000096
hold_cmd(:trigcos, cos(x)^4 + sin(x)^2) ~ trigcos(cos(x)^4 + sin(x)^2)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000097
hold_cmd(:trigtan, cos(x)^4 + sin(x)^2) ~ trigtan(cos(x)^4 + sin(x)^2)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000098
md"""
### Half-tangent substitution
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000099
(
	hold_cmd(:halftan, cos(x)) ~ halftan(cos(x)),
	hold_cmd(:halftan, sin(x)) ~ halftan(sin(x)),
	hold_cmd(:halftan, tan(x)) ~ halftan(tan(x)),
)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000009a
md"""
### Conversions between trig and exponential forms
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000009b
exp(1im * x) ~ exp2trig(exp(1im * x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000009c
hold_cmd(:trig2exp, sin(x)) ~ trig2exp(sin(x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000009d
md"""
### Inverse trig conversions
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000009e
hold_cmd(:tan2sincos, tan(x)) ~ tan2sincos(tan(x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000009f
hold_cmd(:sin2costan, sin(x)) ~ sin2costan(sin(x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-2000000000a0
hold_cmd(:atrig2ln, atan(x)) ~ atrig2ln(atan(x))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-2000000000a1
md"""
### Exponential/power conversions
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-2000000000a2
hold_cmd(:exp2pow, exp(3*ln(x))) ~ exp2pow(exp(3*ln(x)))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-2000000000a3
hold_cmd(:pow2exp, a^b) ~ pow2exp(a^b)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-2000000000a4
hold_cmd(:powexpand, giac_eval("2")^(x+y)) ~ powexpand(giac_eval("2")^(x+y))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-2000000000a5
lncollect(ln(x) + 2*ln(y))

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000100
md"""
---

## 10. Linear Algebra

### Creating matrices with `GiacMatrix`
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000101
M = GiacMatrix([[a, b], [c, d]])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000102
md"""
### Determinant
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000103
det(M)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000104
md"""
### Inverse
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000105
inv(M)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000106
md"""
### Transpose
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000107
transpose(M)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000108
md"""
### Symbolic matrices

Create a symbolic ``5 \times 5`` matrix:
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000109
GiacMatrix(:m, 5, 5)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000010a
md"""
### Eigenvalues
"""

# ╔═╡ 4ea627a7-be62-489c-9ee2-8ddd445684cf
M2 = GiacMatrix([[1, 2], [3, 4]])

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-20000000010b
hold_cmd(:eigenvals, M2) ~ eigenvals(M2)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000110
md"""
---

## 11. Integral Transforms

### Laplace transform
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000111
begin
	@giac_var t s α
	hold_cmd(:laplace, α*t, t, s) ~ laplace(α*t, t, s)
end

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000112
md"""
### Inverse Laplace transform
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000113
hold_cmd(:ilaplace, α/s^2, s, t) ~ ilaplace(α/s^2, s, t)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000114
md"""
### z-transform
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000115
hold_cmd(:ztrans, α^n, n, z) ~ ztrans(α^n, n, z)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000116
md"""
### Inverse z-transform
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000117
hold_cmd(:invztrans, z/(z-α), z, n) ~ invztrans(z/(z-α), z, n)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000120
md"""
---

## 12. Held Commands & LaTeX Display

Use `hold_cmd` to create unevaluated expressions with beautiful LaTeX rendering, then `release` to compute the result.

### Derivative (Leibniz notation)
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000121
begin
	f = 2 / (1 - x)
	h_diff = hold_cmd(:diff, f, x)
end

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000122
release(h_diff)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000123
md"""
### Indefinite integral
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000124
h_int = hold_cmd(:integrate, f, x)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000125
release(h_int)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000126
md"""
### Definite integral
"""

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000127
h_def = hold_cmd(:integrate, f, x, 2, 3)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000128
release(h_def)

# ╔═╡ b0c1d2e3-f4a5-6789-bcde-200000000140
md"""
---

## Summary

This notebook demonstrated GIAC's capabilities across many mathematical domains. All commands used the `Giac.Commands` API directly (e.g., `factor(expr)`) except for a few that conflict with Julia's `Base` module (`sum`, `zeros`, `left`, `right`) which require `invoke_cmd`.

For more details, see the [Giac.jl documentation](https://s-celles.github.io/Giac.jl/).
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Giac = "e4421f97-9838-4fd0-9fa5-94f11373bf78"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
"""

# ╔═╡ Cell order:
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000000
# ╟─2715140c-b9b1-45ba-b0f9-7346e0473bb1
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000001
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000002
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000010
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000011
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000012
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000013
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000014
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000015
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000016
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000017
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000018
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000019
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000001a
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000001b
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000001c
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000001d
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000001e
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000001f
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000020
# ╠═39d02d8d-2660-4c63-8d94-a637ee84a943
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000021
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000022
# ╠═360695e0-101b-47df-bafe-1942593ac232
# ╠═713c05cf-fc44-422c-8228-159041ef6947
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000023
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000024
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000025
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000026
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000027
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000028
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000029
# ╟─3dde1763-7e94-4cb4-bc52-9a2bdfb12312
# ╠═da9ce357-d7bb-4efd-9fb4-276d1426e1d6
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000002a
# ╟─99a37002-7ee8-425f-ae13-cb01f2edadb7
# ╟─91517640-8f32-4dd2-86a5-be9b006eb5ee
# ╟─c30acc26-fa4a-4e5f-8806-ba48daf6fb9a
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000002b
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000030
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000031
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000032
# ╟─744a8a67-2217-4f4d-a14e-620f5c4b408c
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000034
# ╠═d2fad6f5-0c4e-45c0-b5a9-2979291b5124
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000035
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000036
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000037
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000040
# ╟─0ad15d89-6269-47f4-a8be-823c775a41a1
# ╠═698e46a1-aad5-4a1e-8956-185e49d7f740
# ╟─9dffdc70-ac0f-4197-9569-9906c54ccdae
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000042
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000043
# ╟─b9602cdc-aca4-45bb-abd3-e415803e9325
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000044
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000050
# ╠═61d6b7bd-58c4-4ff7-838b-b2afcb141238
# ╠═10d0be2a-6503-49ee-958a-6669a8b9029e
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000052
# ╟─92a6f8fb-1911-4dec-9337-6cf5f673ab89
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000054
# ╠═c577424f-bc7b-422c-a820-0b2fc2d7d4cd
# ╠═90d822c0-f6da-4434-aaba-c5d21c83ce04
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000057
# ╟─18665807-3610-4927-a5f7-64542002de07
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000058
# ╟─e8db1c02-4eea-46af-8ede-d7cd6d115743
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000059
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000060
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000061
# ╠═97ef37a2-1cc5-418b-849a-f870ea497ff9
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000062
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000063
# ╠═8e05925b-de16-49e9-b334-6c2912fea73c
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000064
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000065
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000066
# ╠═6a27b3c9-5fcd-4f84-ae80-da79dcebddbb
# ╠═eb4be260-0366-4005-b566-1b417caba394
# ╟─b0c1d2e3-f4a5-6789-bcde-300000000001
# ╠═b0c1d2e3-f4a5-6789-bcde-300000000002
# ╠═b0c1d2e3-f4a5-6789-bcde-300000000004
# ╠═b0c1d2e3-f4a5-6789-bcde-300000000005
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000070
# ╟─ba7561c5-9ac3-47f0-bc9c-fb293c14876f
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000071
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000072
# ╟─f7dac550-c45c-4663-bece-9394f58094dd
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000073
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000074
# ╟─04e51861-82e0-4d24-ab56-d0455a5b159c
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000075
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000076
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000077
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000078
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000079
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000007a
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000007b
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000080
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000081
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000082
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000083
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000084
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000085
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000086
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000087
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000090
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000091
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000092
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000093
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000094
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000095
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000096
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000097
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000098
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000099
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000009a
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000009b
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000009c
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000009d
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000009e
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000009f
# ╠═b0c1d2e3-f4a5-6789-bcde-2000000000a0
# ╟─b0c1d2e3-f4a5-6789-bcde-2000000000a1
# ╠═b0c1d2e3-f4a5-6789-bcde-2000000000a2
# ╠═b0c1d2e3-f4a5-6789-bcde-2000000000a3
# ╠═b0c1d2e3-f4a5-6789-bcde-2000000000a4
# ╠═b0c1d2e3-f4a5-6789-bcde-2000000000a5
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000100
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000101
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000102
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000103
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000104
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000105
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000106
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000107
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000108
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000109
# ╟─b0c1d2e3-f4a5-6789-bcde-20000000010a
# ╠═4ea627a7-be62-489c-9ee2-8ddd445684cf
# ╠═b0c1d2e3-f4a5-6789-bcde-20000000010b
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000110
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000111
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000112
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000113
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000114
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000115
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000116
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000117
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000120
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000121
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000122
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000123
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000124
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000125
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000126
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000127
# ╠═b0c1d2e3-f4a5-6789-bcde-200000000128
# ╟─b0c1d2e3-f4a5-6789-bcde-200000000140
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
