module StringRepFilter

## ------------------------------------------------------------------
export has_match
export foreach_match, findall_match, findfirst_match, filter_match
export strrep
export show_strrep, show_elstrrep

## ------------------------------------------------------------------
_match(rstr::String, str::String) = match(Regex(rstr), str)
_match(r, str) = match(r, str)
# _eltype(obj) = try; eltype(obj) catch; Any end

## ------------------------------------------------------------------
"""
    strrep(obj)::String

Return an string representation of the object.
Overwrite it for custom behavior.
By default it uses `Base.string`

"""
strrep(obj) = string(obj)

## ------------------------------------------------------------------

"""
Check if the query match the object
"""
has_match

"""
    has_match(dict::Union{AbstractDict, NamedTuple}, qp::Pair)::Bool

The query pair will try to match the key and the value in the dictionary.

# Examples
```julia-repl
julia> d = Dict(:A => "AAB")
Dict{Symbol, String} with 1 entry:
  :A => "AAB"

julia> has_match(d, :A => r"^A")
true

julia> has_match(d, :B => r"^A")
false
```
"""
function has_match(dict::Union{AbstractDict, NamedTuple}, qp::Pair)
    rkey, reg = qp
    !haskey(dict, rkey) && return false
    has_match(dict[rkey], reg)
end

"""
    has_match(pair::Pair, qp::Pair)::Bool

The query pair will try to match the first and secund element in the target pair.

# Examples
```julia-repl
julia> p = Pair(:A ,"AAB")
:A => "AAB"

julia> has_match(p, :A => r"^A")
true

julia> has_match(p, :B => r"^A")
false

julia> has_match(p, "B" => r"^A")
false
```
"""
function has_match(pair::Pair, qp::Pair)
    rkey, reg = qp
    pkey, val = pair
    !isequal(rkey, pkey) && return false
    has_match(val, reg)
end

"""
    has_match(obj, qp::Pair)::Bool

The query pair will try to match the property and the value in the object.

# Examples
```julia-repl
julia> struct Obj; A end

julia> o = Obj("AAB")
Obj("AAB")

julia> has_match(o, :A => r"^A")
true

julia> has_match(o, :B => r"^A")

```
"""
function has_match(obj, qp::Pair)
    rkey, reg = qp
    !hasproperty(obj, rkey) && return false
    has_match(getproperty(obj, rkey), reg)
end

"""
    has_match(obj, qp::Union{Regex, String})

Check if the query match the string representation of the object.
"""
has_match(obj, qp::Union{Regex, String}) = !isnothing(_match(qp, strrep(obj)))

"""
    has_match(obj, qps::Vector)

Check if all queries match the string representation of the object.
"""
function has_match(obj, qs::Vector)
    for qi in qs
        ismatch = has_match(obj, qi)
        !ismatch && return ismatch
    end
    return true
end

has_match(obj, qs::Tuple) = !has_match(obj, collect(qs))

"""
    has_match(obj, qps::Vector)

Check if any queries match the string representation of the object.
"""
function has_match(obj, q, qs...)
    ismatch = has_match(obj, q)
    ismatch && return true
    for qi in qs
        ismatch = has_match(obj, qi)
        ismatch && return true
    end
    return false
end

## ------------------------------------------------------------------
"""
    foreach_match(f::Function, col, qp, qps...)::Nothing

Apply `f(i::Int, elm)` to each element (`elm`) in `col` which match the queries (`i` is the element index).
The index is based on the `iterator` interface (e.g. index 1 means the element yield by the first iteration).
If the return value of `f` is `=== true` the iteration will stop.

# Examples
```julia-repl
julia> d = Dict("A" => "AAB", :B => "BBC", "C" => "CCB")
Dict{Any, String} with 3 entries:
  "A" => "AAB"
  "C" => "CCB"
  :B  => "BBC"

julia> foreach_match(d, r":B") do i, elm
            println(i, ": ", elm)
        end
3: Pair{Any, String}(:B, "BBC")

julia> foreach_match(d, r"") do i, elm
            println(i, ": ", elm)
            i == 1
        end
1: Pair{Any, String}("A", "AAB")
```
"""
function foreach_match(f::Function, col, qp, qps...)
    for (i, elm) in enumerate(col)
        match_flag = has_match(elm, qp)
        for qpi in qps
            match_flag |= has_match(elm, qpi)
        end
        if match_flag
            flag = f(i, elm)
            (flag === true) && return nothing
        end
    end
    return nothing
end

## ------------------------------------------------------------------
"""
Print the string representation (yield by `strrep`) of the object.

"""
show_strrep(obj) = println(strrep(obj))

"""
    show_elstrrep(col, n = 10)

Print the string representation (yield by `strrep`) of the first `n` items in the collection.
This method is intended mainly for debugging proposes.

# Examples
```julia-repl
julia> d = Dict("A" => "AAB", :B => "BBC", "C" => "CCB")
Dict{Any, String} with 3 entries:
    "A" => "AAB"
    "C" => "CCB"
    :B  => "BBC" 

julia> show_elstrrep(d)
Pair{Any, String}("A", "AAB")
Pair{Any, String}("C", "CCB")
Pair{Any, String}(:B, "BBC")
```    
"""
function show_elstrrep(col, n = 10)
    foreach_match(col, r"") do i, elm
        show_strrep(elm)
        if (i == n)
            println("[...]")
            return true
        end
        return false
    end
    return nothing
end

## ------------------------------------------------------------------
"""
    findall_match(col, qp, qps...)::Vector{Int}

Returns all the indexes of the elements in the collection which match the queries.
The index is based on the `iterator` interface (e.g. index 1 means the element yield by the first iteration).
For capturing the elements instead use `find_match`.

# Examples
```julia-repl
julia> d = Dict("A" => "AAB", :B => "BBA")
Dict{Any, String} with 2 entries:
  "A" => "AAB"
  :B  => "BBA"

julia> show_elstrrep(d)
Pair{Any, String}("A", "AAB")
Pair{Any, String}(:B, "BBA")

julia> findall_match(d, "A" => r"^A")
1-element Vector{Int64}:
  1

julia> findall_match(d, :A => r"^A")
Int64[]
```
"""
function findall_match(col, qp, qps...) 
    founds = Int[]
    foreach_match(col, qp, qps...) do i, elm
        push!(founds, i)
        return nothing
    end
    return founds
end

"""
    findfirst_match(col, qp, qps...)::Union{Nothing, Tuple}

Returns the tuple (index, item) for the first item in the collection which match the queries.
If no match is found returns nothing.
The index is based on the `iterator` interface (e.g. index 1 means the element yield by the first iteration).

# Examples
```julia-repl
julia> d = Dict("A" => "AAB", :B => "BBA")
Dict{Any, String} with 2 entries:
  "A" => "AAB"
  :B  => "BBA"

julia> show_elstrrep(d)
Pair{Any, String}("A", "AAB")
Pair{Any, String}(:B, "BBA")

julia> findfirst_match(d, "A" => r"^A")
(1, Pair{Any, String}("A", "AAB"))

julia> findfirst_match(d, r"\".+B\"")
(1, Pair{Any, String}("A", "AAB"))

julia> findfirst_match(d, "ZZ") |> typeof
Nothing

julia> all(filter_match(d, r"[A|B]") .== filter_match(d, "A", "B"))
true
```
"""
function findfirst_match(col, qp, qps...)
    found = nothing
    foreach_match(col, qp, qps...) do i, elm
        found = (i, elm)
        return true
    end
    return found
end


"""
    filter_match(col, qp, qps...)::Vector

Returns the elements which match the queries.
If no match is found returns an empty vector.

# Examples
```julia-repl
julia> d = Dict("A" => "AAB", "B" => "BBC", "C" => "CCD")
Dict{String, String} with 3 entries:
  "B" => "BBC"
  "A" => "AAB"
  "C" => "CCD"

julia> show_elstrrep(values(d))
BBC
AAB
CCD

julia> filter_match(values(d), r"")
3-element Vector{String}:
 "BBC"
 "AAB"
 "CCD"

julia> filter_match(values(d), r"^[^B]*\$")
1-element Vector{String}:
 "CCD"

julia> filter_match(values(d), r"Z")
String[]
```
"""
function filter_match(col, qp, qps...)
    # T = _eltype(col)
    T = eltype(col)
    founds = T[]
    foreach_match(col, qp, qps...) do i, elm
        push!(founds, elm)
    end
    return founds
end


## 
end # module
