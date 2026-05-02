### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000001
begin
	using Giac
	using Giac.Commands
end

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000000
md"""
# Programming in the GIAC Language

Beyond single-expression evaluation, GIAC has its own programming language with control flow (`if/then/else`, `for`, `while`) and user-defined procedures. Access it from Julia through `giac_eval` with a multi-line string.
"""

# ╔═╡ 3bd303ff-74f7-40e9-a3f4-ff5c62133b3f
# ╠═╡ disabled = true
#=╠═╡
begin
	#using Pkg
	#Pkg.add("Giac")
	#Pkg.add(PackageSpec(url="https://github.com/s-celles/Giac.jl"))
	#Pkg.develop(PackageSpec(path=".."))
end
  ╠═╡ =#

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000002
md"""
---

## 1. Defining a procedure

Use `proc(args) ... end` to define a GIAC procedure. The trailing `;` on the Julia side suppresses the proc listing in the cell output:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000003
giac_eval("""
  mysqcu := proc(x)
	if x > 0 then
	  x^2
	else
	  x^3
	fi
  end
""");

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000004
md"""
Now call the procedure from Julia, again via `giac_eval`:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000005
giac_eval("mysqcu(5)")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000006
giac_eval("mysqcu(-5)")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000007
md"""
---

## 2. Calling a GIAC procedure from Julia

Wrap the `giac_eval` call in a Julia function to interpolate an argument and convert the result back to a native Julia value with `to_julia`:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000008
g(v) = giac_eval("mysqcu($v)") |> to_julia

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000009
g(3)

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-30000000000a
g(-2)

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000010
md"""
---

## 3. Loops and accumulators

GIAC supports `for` loops and local variables. Example — sum the first *n* squares:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000011
giac_eval("""
  sum_of_squares := proc(n)
	local s, k;
	s := 0;
	for k from 1 to n do
	  s := s + k^2;
	od;
	s
  end
""");

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000012
giac_eval("sum_of_squares(10)")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000013
md"""
Compare with the closed form $\frac{n(n+1)(2n+1)}{6}$ for n = 10:
"""

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000014
giac_eval("10 * 11 * 21 / 6")

# ╔═╡ c1d2e3f4-a5b6-7890-abcd-300000000099
md"""
---

## Summary

| Construct | GIAC syntax |
|-----------|-------------|
| Procedure | `name := proc(args) ... end` |
| Conditional | `if cond then ... else ... fi` |
| For loop | `for k from a to b do ... od` |
| Local var | `local x, y;` |
| Call from Julia | `giac_eval("name(arg)")` |
| Result to Julia | `to_julia(...)` |

See `01_basics.jl` for the symbolic API, and `04_plotting.jl` for plotting `GiacExpr` values.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Giac = "e4421f97-9838-4fd0-9fa5-94f11373bf78"
"""

# ╔═╡ Cell order:
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000000
# ╟─3bd303ff-74f7-40e9-a3f4-ff5c62133b3f
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000001
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000002
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000003
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000004
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000005
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000006
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000007
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000008
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000009
# ╠═c1d2e3f4-a5b6-7890-abcd-30000000000a
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000010
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000011
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000012
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000013
# ╠═c1d2e3f4-a5b6-7890-abcd-300000000014
# ╟─c1d2e3f4-a5b6-7890-abcd-300000000099
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
