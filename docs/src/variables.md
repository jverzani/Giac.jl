# Symbolic variables

## Simple Variable Creation

Create a symbolic variable with `@giac_var`:

```julia
using Giac

@giac_var a
@giac_var a

a + b

# or simply

@giac_var a b
```

## Batch Variable Creation

Create multiple indexed symbolic variables with `@giac_several_vars`:

```julia
using Giac

# 1D vector of variables
@giac_several_vars a 3
# Creates: a1, a2, a3
# Returns: (a1, a2, a3)
a1 + a2 + a3  # Symbolic sum

# 2D matrix of variables
@giac_several_vars m 2 3
# Creates: m11, m12, m13, m21, m22, m23 (row-major order)
# Returns: (m11, m12, m13, m21, m22, m23)

# N-dimensional tensors
@giac_several_vars t 2 2 2
# Creates: t111, t112, t121, t122, t211, t212, t221, t222

# Large dimensions use underscore separators
@giac_several_vars b 2 10
# Creates: b_1_1, b_1_2, ..., b_2_10

# Unicode base names supported
@giac_several_vars α 2
# Creates: α1, α2

# Capture return tuple for iteration
vars = @giac_several_vars c 4
for v in vars
    println(v)
end
```

## Symbolic Comparisons and Inequalities

The comparison operators `<`, `>`, `<=`, `>=` return symbolic inequality expressions
(`GiacExpr`), not booleans. This enables natural syntax for building constraints:

```julia
using Giac

@giac_var x y

# Build symbolic inequalities
x > 0        # Returns a GiacExpr representing x>0
x < y        # Returns a GiacExpr representing x<y
x >= 1//2    # Works with Rational
x <= π       # Works with Irrational
```

Combine inequalities with `&` (and) and `|` (or):

```julia
(x > 0) & (x < 10)    # GIAC "and" expression
(x < -1) | (x > 1)    # GIAC "or" expression
```

## Assumptions on Variables

Use `assume` and `additionally` to declare constraints on symbolic variables.
Subsequent computations will respect these assumptions:

```julia
using Giac
using Giac.Commands: assume, about, sign, purge, additionally, sqrt

@giac_var x

# Declare x as positive
assume(x > 0)
sign(x)      # Returns 1
sqrt(x^2)    # Returns x (simplified thanks to assumption)

# Interval constraint using &
assume((x > 0) & (x < 10))
about(x)     # Shows interval [0, 10]

# Or use assume + additionally
assume(x > -1)
additionally(x < 1)
about(x)     # Shows interval [-1, 1]

# Clear assumptions
purge(x)
```

!!! note
    Julia's chained comparison syntax `0 < x < 10` does not work because Julia
    desugars it using `&&` (which cannot be overloaded). Use `(x > 0) & (x < 10)`
    or `assume` + `additionally` instead.

!!! warning
    When a variable already has an assumption, GIAC evaluates comparisons involving
    that variable to `true` or `false` instead of keeping them symbolic. This means
    calling `assume` a second time without `purge` first will fail:

    ```julia
    assume(x > 0)
    additionally(x < 10)
    # x > 0 now evaluates to "true" (GIAC knows x is positive)
    assume(x > 0)  # ERROR: assume(true) is invalid

    # Fix: always purge before re-assuming
    purge(x)
    assume(x > 0)  # Works
    ```