# Iteration and indexing for Giac.jl
# Provides Julia-native iteration and 1-based indexing for Gen vectors
#
# Part of feature 029-output-handling

# ============================================================================
# Length and Size
# ============================================================================

"""
    Base.length(g::GiacExpr) -> Int

Return the number of elements if `g` is a vector, otherwise `1`.

# Example
```julia
length(giac_eval("[1, 2, 3]"))  # 3
length(giac_eval("42"))          # 1
```
"""
function Base.length(g::GiacExpr)::Int
    if is_vector(g)
        return _vector_length(g)
    else
        return 1
    end
end

"""
    Base.size(g::GiacExpr) -> NTuple{<:Any, Int}

Return the size of a GiacExpr as a tuple.
For vectors, returns `(length,)`. For scalars, returns `(1,)`, for matrices, return value of `dim`.
"""
function Base.size(g::GiacExpr)::NTuple{<:Any, Int}
    if is_vector(g) && subtype(g) == 11
        sz = invoke_cmd(:dim, g)
        return tuple((to_julia(d) for d in sz)...)
    end
    return (length(g),)
end

function Base.transpose(g::GiacExpr)
    # adjust shape: vectors as a column vector is not GiacStyle
    if is_vector(g)
        out = invoke_cmd(:transpose, g)
        if subtype(g) == 0 # plain vector, do twice to lift to 1×n matrix
            out = invoke_cmd(:transpose, out)
        end
        return out
    end
    return g
end

# ============================================================================
# Indexing
# ============================================================================

"""
    Base.getindex(g::GiacExpr, i::Int) -> GiacExpr

Return the i-th element (1-based indexing) of a vector expression.

# Example
```julia
g = giac_eval("[10, 20, 30]")
g[1]  # GiacExpr representing 10
g[2]  # GiacExpr representing 20
g[3]  # GiacExpr representing 30
```

# Throws
- `ErrorException` if `g` is not a vector
- `BoundsError` if index is out of range
"""
function Base.getindex(g::GiacExpr, i::Int)::GiacExpr
    if !is_vector(g)
        throw(ErrorException("Gen is not a vector/list"))
    end

    n = length(g)
    if i < 1 || i > n
        throw(BoundsError(g, i))
    end

    return _vector_element(g, i)
end

"""
    Base.firstindex(g::GiacExpr) -> Int

Return the first index (always `1` for Julia convention).
"""
Base.firstindex(g::GiacExpr) = 1

"""
    Base.lastindex(g::GiacExpr) -> Int

Return the last index (same as `length(g)`).
"""
Base.lastindex(g::GiacExpr) = length(g)

"""
    Base.eachindex(g::GiacExpr)

Return an iterator over valid indices.
"""
Base.eachindex(g::GiacExpr) = 1:length(g)

# ============================================================================
# Iteration Protocol
# ============================================================================

"""
    Base.iterate(g::GiacExpr)

Begin iteration over a GiacExpr. For vectors, yields elements one by one.
For scalars, yields the value once.

# Example
```julia
g = giac_eval("[x, y, z]")
for elem in g
    println(elem)
end
```
"""
function Base.iterate(g::GiacExpr)
    if is_vector(g)
        n = length(g)
        if n == 0
            return nothing
        end
        return (_vector_element(g, 1), 2)
    else
        # Non-vector: iterate once over the value itself
        return (g, nothing)
    end
end

"""
    Base.iterate(g::GiacExpr, state)

Continue iteration over a GiacExpr.
"""
function Base.iterate(g::GiacExpr, state)
    if state === nothing
        # Non-vector case: we've already yielded the single value
        return nothing
    end

    # Vector case
    n = length(g)
    if state > n
        return nothing
    end

    return (_vector_element(g, state), state + 1)
end

### broadcasting
### still errors on sin.(giac_eval("2"))
### BroadcastStyle (ndims) depends on type, but this resolves on
### underlying Giac type, subtype, and size
function Base.Broadcast.broadcastable(ex::GiacExpr)
    !is_vector(ex) && return Ref(ex)
    isempty(ex) && return ex
    if subtype(ex) == 0
        r1 = first(ex)
        !is_vector(r1) && return map(identity, ex)
        n = length(ex)
        v1 = map(identity, r1)
        v = Vector{typeof(v1)}(undef, n)
        v[1] = v1
        for i in 2:n
            v[i] = map(identity,ex[i])
        end
        return v
    end

    # Collect object into a Matrix{GiacExpr}
    sz = size(ex)
    m,n = sz
    M = Matrix{GiacExpr}(undef, m, n)
    for i in 1:m
        r = invoke_cmd(:row, ex, i-1) # 0-based
        for j in 1:n
            M[i,j] = r[j]
        end
    end
    return M
end
Base.IteratorSize(v::GiacExpr) = Base.HasShape{length(size(v))}()
Base.axes(lst::GiacExpr) = map(Base.OneTo, size(lst))

"""
    Base.eltype(::Type{GiacExpr})

Return the element type for iteration (always `GiacExpr`).
"""
Base.eltype(::Type{GiacExpr}) = GiacExpr

# ============================================================================
# Collection Interface
# ============================================================================

"""
    Base.keys(g::GiacExpr)

Return an iterator over the keys (indices) of a GiacExpr.
"""
Base.keys(g::GiacExpr) = 1:length(g)

"""
    Base.values(g::GiacExpr)

Return an iterator over the values of a GiacExpr.
"""
Base.values(g::GiacExpr) = (g[i] for i in 1:length(g))

"""
    Base.pairs(g::GiacExpr)

Return an iterator over (index, value) pairs.
"""
Base.pairs(g::GiacExpr) = ((i, g[i]) for i in 1:length(g))

"""
    Base.in(item, g::GiacExpr) -> Bool

Check if an item is in a GiacExpr vector.

# Example
```julia
g = giac_eval("[1, 2, 3]")
giac_eval("2") in g  # true (by string comparison)
```
"""
function Base.in(item::GiacExpr, g::GiacExpr)::Bool
    if !is_vector(g)
        return string(item) == string(g)
    end

    item_str = string(item)
    for elem in g
        if string(elem) == item_str
            return true
        end
    end
    return false
end

# ============================================================================
# Slicing Support
# ============================================================================

"""
    Base.getindex(g::GiacExpr, r::AbstractRange) -> Vector{GiacExpr}

Return a slice of elements from a vector GiacExpr.

# Example
```julia
g = giac_eval("[1, 2, 3, 4, 5]")
g[2:4]  # [GiacExpr(2), GiacExpr(3), GiacExpr(4)]
```
"""
function Base.getindex(g::GiacExpr, r::AbstractRange)::Vector{GiacExpr}
    if !is_vector(g)
        throw(ErrorException("Gen is not a vector/list"))
    end

    n = length(g)
    result = GiacExpr[]
    for i in r
        if i < 1 || i > n
            throw(BoundsError(g, i))
        end
        push!(result, _vector_element(g, i))
    end
    return result
end

"""
    Base.getindex(g::GiacExpr, ::Colon) -> Vector{GiacExpr}

Return all elements as a Vector{GiacExpr}.

# Example
```julia
g = giac_eval("[1, 2, 3]")
g[:]  # [GiacExpr(1), GiacExpr(2), GiacExpr(3)]
```
"""
function Base.getindex(g::GiacExpr, ::Colon)::Vector{GiacExpr}
    return [g[i] for i in 1:length(g)]
end
