using StringRepFilter
using Test

@testset "StringRepFilter.jl" begin
    
    ## --------------------------------------------------------------
    @info("Testing has_match")
    
    struct Obj; A end

    for d in [Dict(:A => "AAB"), (;A = "AAB"), Obj("AAB")]
        
        @test has_match(d, :A => "B")
        @test has_match(d, :A => r"^A")
        @test has_match(d, :A => r"B$")
        @test !has_match(d, :A => r"C")
        @test !has_match(d, :A => r"^B")
        @test !has_match(d, :B => r"^A")
        
        @test has_match(d, [:A => r"B$"])
        @test !has_match(d, [:A => r"^B"])
        @test !has_match(d, [:B => r"^A"])
        
        if (d isa Dict)
            # Check wrong key type
            @test !has_match(d, "A" => r"^A")
            @test !has_match(d, "A" => r"^B")
        end

    end

    ## --------------------------------------------------------------
    @info("Testing finders and filters")

    col = ["AAA", "BBB", 123]
    @test all(filter_match(col, r"^[A|1]") .== filter_match(col, "A", "1"))
    @test findfirst_match(col, r"^[A|1]") == (1, first(col))
    @test findall_match(col, r"^[A|1]") == [1, 3]
    
    ## --------------------------------------------------------------
end
