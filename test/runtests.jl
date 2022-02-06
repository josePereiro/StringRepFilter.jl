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
end
