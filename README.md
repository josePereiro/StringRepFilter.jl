# StringRepFilter

[![Build Status](https://github.com/josePereiro/StringRepFilter.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/josePereiro/StringRepFilter.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/josePereiro/StringRepFilter.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/josePereiro/StringRepFilter.jl)

`StringRepFilter` allow you to select/find elements of a collection by matching its string representation with a regex pattern.
It use several cool `julia` built in features:

1. All data instance can be represented in a string form.
2. Built in support for regex.
3. Multiple dispatch and interfaces (such as `Iterable`) allow composability from general code.

> **_WARNING:_** To convert an object to string for identifying it is expensive and inefficient. This package is intended primarily for having an easy way to query data collections of __small__ objects in an interactive fashion.

## Usage

### Pattern matching

The method `strrep` give an string representation of an object (by default is call `string`)

```julia
julia> using StringRepFilter

julia> arr = ["AA", "AAB", 123, :A => "BBC", "B" => :blo];

julia> strrep(arr)
"Any[\"AA\", \"AAB\", 123, :A => \"BBC\", \"B\" => :blo]"
```

Different patters can be use to check if a string representation match using `has_match`.

```julia
julia> has_match(arr, r"^Any")
true
```

A `String` will be use as a regex too.

```julia
julia> has_match(arr, "^Any")
true
```

Note that `Any` wasn't any element of the `arr` object.
`has_match` search in the representation, not in the object.

A `Pair` can be use to signal that a `key/property` of a `dict/struct` want to be matched instead the `strrep` of the whole object.

```julia
julia> dic = Dict("A" => 123, :B => "CCC")

julia> strrep(dic)
"Dict{Any, Any}(\"A\" => 123, :B => \"CCC\")"

julia> has_match(dic, "Dict")
true

julia> strrep(dic["A"])
"123"

julia> has_match(dic, "A" => "Dict")
false

julia> has_match(dic, "A" => "^1")
true

```

In the case of an dictionary, the type of the key must be respected.

```julia
julia> has_match(dic, :A => "^1")
false
```

A `Vector` of patters will match if all match.

```julia
julia> strrep(dic)
"Dict{Any, Any}(\"A\" => 123, :B => \"CCC\")"

julia> has_match(dic, ["A" => "^1", :B => "C{3}", r"^Dict"])
true
```

Note that in this last call we combine pairs and single patters. There, the pairs was evaluated on `strrep(dic[key])` and the "plain" one over `strrep` (powerful!).

Additionally, if the patters are passed as different arguments the check will match if any of then match.

```julia
julia> has_match(dic, ["A" => "^1", :B => "C{3}", r"^NO MATCH"])
false

julia> has_match(dic, ["A" => "^1", :B => "C{3}", r"NO MATCH"], "Dict")
true
```

This way a compound boolean expression can be computed.

Finally, wrap a patter in a tuple to negate it.

```julia
julia> has_match(dic, ["A" => "^1", :B => "C{3}", r"^NO MATCH"])
false

julia> has_match(dic, ["A" => "^1", :B => "C{3}", (r"^NO MATCH",)], "Dict")
true
```

### Filtering matching

Now lets use the matching mechanism for filtering a collection of custom `struct`s.

```julia
julia> _randstuff() = rand([rand(1:10), rand(), join(rand('A':'Z', rand(5:10)))])

julia> struct Blo; A; B end

julia> o = Blo(rand(), "A")
Blo(0.5477207826309064, "A")

julia> strrep(o)
"Blo(0.5477207826309064, "A")"

julia> ocol = [Blo(_randstuff(), _randstuff()) for _ in 1:100]
100-element Vector{Blo}:
 Blo("FDTIWG", "XXVBJMX")
 Blo("JTVGOU", 0.035922399345289735)
 Blo(2, "KLMLE")
 Blo("JCXDA", 1)
 Blo(0.5854516803563331, 4)
 Blo(1, 7)
 Blo("FMXSXK", "BVXVGGOQYZ")
 Blo(9, 3)
 Blo(0.40251615683819564, 9)
 ⋮
 Blo("WRJHOXKH", "RPTWO")
 Blo(7, 0.46962365046171595)
 Blo("OLILEWJQXU", "OSGHDQ")
 Blo(1, "ZMWZG")
 Blo("GKXTNNQAD", "CEFGDABYV")
 Blo(0.12328916249921396, "UHRZUUCUK")
 Blo(10, 2)
 Blo(0.023304656906707688, 1)
```

The package export a `foreach_match`, `filter_match`, `findfirst_match` and `findall_match` functions for querying a collection.
I uses the `Iterator` interface for accessing all collection objects.

use `show_elstrrep(col)` to poke the `strrep` of a collection's elements.

```julia
julia> show_elstrrep(ocol)
Blo("FDTIWG", "XXVBJMX")
Blo("JTVGOU", 0.035922399345289735)
Blo(2, "KLMLE")
Blo("JCXDA", 1)
Blo(0.5854516803563331, 4)
Blo(1, 7)
Blo("FMXSXK", "BVXVGGOQYZ")
Blo(9, 3)
Blo(0.40251615683819564, 9)
Blo(5, 0.0845782517640391)
[...]
```

Lets filter all `Blo` objects such that `Blo.A::Float64 > 0.5`.

```julia
julia> filter_match(ocol, :A => r"0\.[5-9]\d+")
11-element Vector{Blo}:
 Blo(0.5854516803563331, 4)
 Blo(0.9489282779059586, "OREYSM")
 Blo(0.5448697251103501, "IOCIGFWVQA")
 Blo(0.5727456430603451, 8)
 Blo(0.778506994052303, "TANFWKRYOL")
 Blo(0.8446973050626903, 1)
 Blo(0.6378590643501615, "DXASPBBNQF")
 Blo(0.9532984387764549, 0.17636374775403263)
 Blo(0.8118686857078741, 0.090338870611959)
 Blo(0.6907206340829984, 0.1450930523863445)
 Blo(0.7438888740998787, 0.05609689148299868)
```

If we don't use a pair pattern, the whole representation will be use.

```julia
julia> filter_match(ocol, r"0\.[5-9]\d+")
19-element Vector{Blo}:
 Blo(0.5854516803563331, 4)
 Blo(0.45688740091378954, 0.9186268652726755)
 Blo(0.9489282779059586, "OREYSM")
 Blo(0.5448697251103501, "IOCIGFWVQA")
 Blo(0.5727456430603451, 8)
 Blo(0.778506994052303, "TANFWKRYOL")
 Blo(0.8446973050626903, 1)
 Blo(0.6378590643501615, "DXASPBBNQF")
 Blo("CVMQMIEKMN", 0.5993861287728526)
 ⋮
 Blo(2, 0.9566162228658616)
 Blo(0.8118686857078741, 0.090338870611959)
 Blo(0.6907206340829984, 0.1450930523863445)
 Blo(2, 0.553484983539994)
 Blo(0.2550700409151838, 0.8026123269406094)
 Blo(1, 0.629608013281538)
 Blo(0.7438888740998787, 0.05609689148299868)
 Blo(8, 0.5366508252193357)
```

Lets find all `Blo`s which has textual `B` fields but not containing a "V", or have a natural `A` field.
Note that the last query is a type assertion AND a boolean function.

```julia
julia> filter_match(ocol, [:B => "[A-Z]+", (:B => "V",) ], :A => [Real, isinteger])
50-element Vector{Blo}:
 Blo(2, "KLMLE")
 Blo(1, 7)
 Blo(9, 3)
 Blo(5, 0.0845782517640391)
 Blo(4, "PKVKGP")
 Blo(7, "SFLBYJZ")
 Blo(0.9489282779059586, "OREYSM")
 Blo(0.30204785881804386, "NYJSGXN")
 Blo(0.778506994052303, "TANFWKRYOL")
 ⋮
 Blo(4, "CBOBTH")
 Blo(8, 0.5366508252193357)
 Blo(0.22531171826053176, "HHWPNXE")
 Blo("WRJHOXKH", "RPTWO")
 Blo(7, 0.46962365046171595)
 Blo("OLILEWJQXU", "OSGHDQ")
 Blo(1, "ZMWZG")
 Blo(0.12328916249921396, "UHRZUUCUK")
```
