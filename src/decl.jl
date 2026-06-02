# Modified from https://github.com/jverzani/SymPyCore.jl/blob/main/src/decl.jl
#
# TODO:
# * rename to @giac_var; requires changing syms -> giac-var in this file
#   and removing giac_var code from `macros.jl`
# * copilot suggests allowing variables in ranges, eg. z[1:n], but this
#   is a bit too much work to implement
"""
    @syms x y::(integer, positive), z[1:4] u[1:2]::integer v=>"𝑣" w(t)

Create symbolic variables or function expressions from Julia symbols.

Creates `GiacExpr` variables in the calling scope by internally calling
`giac_eval` with the stringified expression.


# Arguments

- `sym...`: Symbol names to create as simple variables. Symbol names may include assumptions. Symbol names may refer to named arrays of symbols with fixed indicies. Symbol names may be renamed.
- `func(args...)`: Function syntax to create function expressions of one or more variables

# Assumptions

Giac has a flexible ability to add assumptions using `assume` and `additionally`. The use here allows for adding assumptions incrementally through `additionally` where the values may be:

* A specification of the domain for the variable with values `real`, `complex`, `rational`, or `integer`.
* A specification, by name, of a restricted range with values: `negative`, `nonpositive`, `nonnegative`, `positive`, and `finite`.
* A specification, by a predicate function, of a restricted range through: `<(𝑥)`, `<=(𝑥)`, `>=(𝑥)`, or `>(𝑥)` for a given value `𝑥`.


# Example

Single variable:
```julia
@syms x           # Creates x as a GiacExpr
string(x)             # "x"
x isa GiacExpr        # true
```

Single variable as array
```julia
@syms x[1:5]          # x is GiacExpr[x₁, x₂, x₃, x₄, x₅]
@syms x[-1:1, -1:1]   # x is GiacExpr[x₋₁_₋₁ x₋₁_₀ x₋₁_₁; x₀_₋₁ x₀_₀ x₀_₁; x₁_₋₁ x₁_₀ x₁_₁]
```

Single variable with assumptions
```{julia}
@syms x::integer
about(x)              # GiacExpr: assume[integer]
@syms x::(>(1))
about(x)              # GiacExpr: assume[[],[line[1,+infinity]],[1]]
@syms x::(integer, >=(1), <=(9))
about(x)              # GiacExpr: assume[integer,[line[1,9]],[]]
```

Multiple variables:
```julia
@syms x y z       # Creates x, y, z as GiacExpr variables
```

Functions:
```julia
@syms u(t)        # Creates u as GiacExpr representing "u(t)"
string(u)             # "u(t)"

# Use with differentiation
@syms t
diff(u, t)            # Returns diff(u(t),t)

# Multi-variable function
@syms u(s, t)
string(u)             # "u(s,t)"
```


Mixed declarations
```julia
@syms x y::(integer, positive) z[1:2,-1:1] u[1:2]::positive v=>"𝑣" w(t)
about(x)              # x
about(y)              # GiacExpr: assume[integer,[line[0,+infinity]],[0]]
z                     # 2×3 Matrix{GiacExpr}:
                      #  GiacExpr: z₁_₋₁  GiacExpr: z₁_₀  GiacExpr: z₁_₁
                      #  GiacExpr: z₂_₋₁  GiacExpr: z₂_₀  GiacExpr: z₂_₁
about(u[2])           # GiacExpr: assume[[],[line[0,+infinity]],[0]]
v                     # GiacExpr: 𝑣
w                     # GiacExpr: w(t)

@syms x::(integer, >(2))
about(x)              # GiacExpr: assume[integer,[line[2,+infinity]],[2]]
@syms x::(>(pi)
about(x)              # GiacExpr: assume[[],[line[pi,+infinity]],[pi]]
```

# Usage
```julia
using Giac

@syms x y
expr = giac_eval("x^2 + y^2")
result = giac_diff(expr, x)  # 2*x

# For ODEs
@syms t u(t)
# u''(t) + u(t) = 0

# Callable syntax for initial conditions (034-callable-giacexpr)
@syms t u(t) tau U0
u(0)                    # Returns GiacExpr: "u(0)"
u(0) ~ 1                # Initial condition: u(0) = 1
diff(u, t)(0) ~ 0       # Derivative condition: u'(0) = 0
desolve([tau * diff(u, t) + u ~ U0, u(0) ~ 1], u)
```

# See also
- [`giac_eval`](@ref): For evaluating string expressions

# Note

Originally by @matthieubulte in https://github.com/JuliaPy/SymPy.jl/pull/419

"""
macro syms(xs...)
    if isempty(xs)
        throw(ArgumentError("@syms requires at least one argument"))
    end

    # If the user separates declaration with commas, the top-level expression is a tuple


    if length(xs) == 1 && isa(xs[1], Expr) && xs[1].head == :tuple
        _gensyms(xs[1].args...)
    elseif length(xs) > 0
        _gensyms(xs...)
    end
end

export @syms


function _gensyms(xs...)
    asstokw(a) = Expr(:kw, esc(a), true)

    # Each declaration is parsed and generates a declaration using `symbols`
    symdefs = map(xs) do expr
        decl = parsedecl(expr)
        symname = sym(decl)
        symname, gendecl(decl)
    end
    syms, defs = collect(zip(symdefs...))

    # The macro returns a tuple of Symbols that were declared
    Expr(:block, defs..., :(tuple($(map(esc,syms)...))))
end


# The map_subscripts function is stolen from Symbolics.jl
const IndexMap = Dict{Char,Char}(
    '-' => '₋',
    '0' => '₀',
    '1' => '₁',
    '2' => '₂',
    '3' => '₃',
    '4' => '₄',
    '5' => '₅',
    '6' => '₆',
    '7' => '₇',
    '8' => '₈',
    '9' => '₉')

function map_subscripts(indices)
    str = string(indices)
    join(IndexMap[c] for c in str)
end

# Define a type hierarchy to describe a variable declaration. This is mainly for convenient pattern matching later.
abstract type VarDecl end

struct SymDecl <: VarDecl
    sym :: Symbol
end

struct NamedDecl <: VarDecl
    name :: String
    rest :: VarDecl
end

struct FunctionDecl <: VarDecl
    vars :: Vector{Any}
    rest :: VarDecl
end

struct TensorDecl <: VarDecl
    ranges :: Vector{AbstractRange}
    rest :: VarDecl
end

struct AssumptionsDecl <: VarDecl
    assumptions #:: Vector{Symbol}
    rest :: VarDecl
end

# Transform a Decl struct in an Expression that calls Giac to
# declare the corresponding symbol
function gendecl(x::VarDecl)
    val = :($(ctor(x))($(name(x, missing)), $(assumptions(x))...))
    :($(esc(sym(x))) = $(genreshape(val, x)))
end

# Transform an expression in a Decl struct
function parsedecl(expr)
    # @syms x
    if isa(expr, Symbol)
        return SymDecl(expr)

    # @syms x::assumptions, where assumption = assumptionkw | (assumptionkw...)
    elseif isa(expr, Expr) && expr.head == :(::)
        symexpr, assumptions = expr.args
        if isa(assumptions, Union{Symbol})
            assumptions = [assumptions]
        elseif isa(assumptions, Expr) && assumptions.head == :call
            assumptions = [assumptions]
        else
            assumptions = assumptions.args
        end
        return AssumptionsDecl(assumptions, parsedecl(symexpr))

    # @syms x=>"name"
    elseif isa(expr, Expr) && expr.head == :call && expr.args[1] == :(=>)
        length(expr.args) == 3 || parseerror()
        isa(expr.args[3], String) || parseerror()

        expr, strname = expr.args[2:end]
        return NamedDecl(strname, parsedecl(expr))
    # @syms x(t)
    elseif isa(expr, Expr) && expr.head == :call && expr.args[1] != :(=>)
        length(expr.args) == 1 && parseerror()

        funcname, funcargs... =  expr.args
        # Validate function name is a symbol
        if !(funcname isa Symbol)
            throw(ArgumentError("Function name must be a symbol, got $(typeof(funcname)): $funcname"))
        end

        # Validate at least one argument
        if isempty(funcargs)
            throw(ArgumentError("Function syntax requires at least one argument: @syms $(funcname)() is invalid. Use @syms $funcname for a simple variable."))
        end

        # Validate all arguments are symbols
        for (i, farg) in enumerate(funcargs)
            if !(farg isa Symbol)
                throw(ArgumentError("Function arguments must be symbols, got $(typeof(farg)): $farg in position $i"))
            end
        end
        return FunctionDecl(funcargs, parsedecl(funcname))

    # @syms x[1:5, 3:9]
    elseif isa(expr, Expr) && expr.head == :ref
        length(expr.args) > 1 || parseerror()
        ranges = map(parserange, expr.args[2:end])
        return TensorDecl(ranges, parsedecl(expr.args[1]))
    elseif expr isa String
            throw(ArgumentError("@syms arguments must be symbols, not strings. Use giac_eval(\"$expr\") instead."))
    else
        parseerror()
    end
end
function parserange(expr)
    range = eval(expr)
    isa(range, AbstractRange) || parseerror()
    range
end

sym(x::SymDecl) = x.sym
sym(x::NamedDecl) = sym(x.rest)
sym(x::FunctionDecl) = sym(x.rest)
sym(x::TensorDecl) = sym(x.rest)
sym(x::AssumptionsDecl) = sym(x.rest)

# create a symbol or symbols
# can put assumptions on
# domain of variable: complex, real, rational, integer
# values of variable: negative, nonpositive, nonnegative, positive, finite
# predicates of the form `<(𝑥)`, `<=(𝑥)`, `>=(𝑥)`, or `>(𝑥)`
function symbols(x, args...; kwargs...)
    if contains(x, ",")
        nm = [giac_eval(string(xᵢ)) for xᵢ ∈ split(x, ",")]
        for x ∈ nm
            _add_assumptions!(x, args)
        end
    else
        nm = giac_eval(x)
        _add_assumptions!(nm, args)
    end
    nm
end

function _add_assumptions!(x, assumptions)
    Commands.purge(x)
    for a in assumptions
        if a ∈ (:complex, :real, :rational, :integer)
            Commands.assume(x, string(a))
        end
    end
    for a in assumptions
        a == :negative    && Commands.additionally(x < 0)
        a == :nonpositive && Commands.additionally(x <= 0)
        a == :nonnegative && Commands.additionally(x >= 0)
        a == :positive    && Commands.additionally(x > 0)
        if a == :finite
            Commands.additionally("$x > -infinity")
            Commands.additionally("$x < infinity")
        end
        # check for >(0) or some such
        if isa(a, Expr) && a.head == :call && length(a.args) == 2
            op, val = a.args[1], a.args[2]
            op == :(<)  && Commands.additionally("$x < $(val)")
            op == :(<=) && Commands.additionally("$x <= $(val)")
            op == :(>=) && Commands.additionally("$x >= $(val)")
            op == :(>)  && Commands.additionally("$x > $(val)")
        end

    end
end

function SymFunction(x, args...;kwargs...)
    giac_eval(string(x))
end


ctor(::SymDecl) = :symbols
ctor(x::NamedDecl) = ctor(x.rest)
ctor(::FunctionDecl) = :SymFunction
ctor(x::TensorDecl) = ctor(x.rest)
ctor(x::AssumptionsDecl) = ctor(x.rest)

assumptions(::SymDecl) = []
assumptions(x::NamedDecl) = assumptions(x.rest)
assumptions(x::FunctionDecl) = assumptions(x.rest)
assumptions(x::TensorDecl) = assumptions(x.rest)
assumptions(x::AssumptionsDecl) = x.assumptions

# Reshape is not used by most nodes, but TensorNodes require the output to be given
# the shape matching the specification. For instance if @syms x[1:3, 2:6], we should
# have size(x) = (3, 5)
function _reshape(ex, dims)
    reshape(collect(GiacExpr, ex), dims)
end


genreshape(expr, ::SymDecl) = expr
genreshape(expr, x::NamedDecl) = genreshape(expr, x.rest)
function genreshape(expr, x::FunctionDecl)
    rhs = string(x.rest.sym) * "(" * join(x.vars, ",") * ")"
    return :(giac_eval($rhs))
end
genreshape(expr, x::TensorDecl) = let
    shape = tuple(length.(x.ranges)...)
    :(_reshape(collect($(expr)), $(shape)))
end
genreshape(expr, x::AssumptionsDecl) = genreshape(expr, x.rest)

# To find out the name, we need to traverse in both directions to make sure that each node can get
# information from parents and children about possible name.
# This is done because the expr tree will always look like NamedDecl -> ... -> TensorDecl -> ... -> SymDecl
# and the TensorDecl node will need to know if it should create names base on a NamedDecl parent or
# based on the SymDecl leaf.
name(x::SymDecl, parentname) = coalesce(parentname, String(x.sym))
name(x::NamedDecl, parentname) = coalesce(name(x.rest, x.name), x.name)
name(x::FunctionDecl, parentname) = name(x.rest, parentname)
name(x::AssumptionsDecl, parentname) = name(x.rest, parentname)
name(x::TensorDecl, parentname) = let
    basename = name(x.rest, parentname)
    # we need to double reverse the indices to make sure that we traverse them in the natural order
    namestensor = map(Iterators.product(x.ranges...)) do ind
        sub = join(map(map_subscripts, ind), "_")
        string(basename, sub)
    end
    join(namestensor[:], ", ")
end

function parseerror()
    error("Incorrect @syms syntax. Try `@syms x::(real,positive) y(t) z::complex n::integer` for instance.")
end
