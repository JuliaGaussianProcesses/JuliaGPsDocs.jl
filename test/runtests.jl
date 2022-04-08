using JuliaGPsDocs: JuliaGPsDocs, generate_examples, find_notebook_examples
using Test

@testset "JuliaGPsDocs.jl" begin
    EXAMPLES_OUT = joinpath(pkgdir(JuliaGPsDocs), "docs", "src", "examples")

    @testset "generate examples" begin
        generate_examples(JuliaGPsDocs; examples_basedir="test/examples")

        # Test that the examples are generated
        for example in ["example-a", "example-b"]
            @test isdir(joinpath(EXAMPLES_OUT, example))
            @test isfile(joinpath(EXAMPLES_OUT, example, "notebook.ipynb"))
            @test isfile(joinpath(EXAMPLES_OUT, example, "index.md"))
            @test isfile(joinpath(EXAMPLES_OUT, example, "Manifest.toml"))
        end

        # Test discovery helper
        @test find_notebook_examples(JuliaGPsDocs) ==
            ["examples/example-a/index.md", "examples/example-b/index.md"]
    end

    @testset "exclusions" begin
        generate_examples(
            JuliaGPsDocs; examples_basedir="test/examples", exclusions=["example-a"]
        )
        @test !isdir(joinpath(EXAMPLES_OUT, "example-a"))
        @test isdir(joinpath(EXAMPLES_OUT, "example-b"))
    end

    @testset "inclusions" begin
        generate_examples(
            JuliaGPsDocs; examples_basedir="test/examples", inclusions=["example-b"]
        )
        @test !isdir(joinpath(EXAMPLES_OUT, "example-a"))
        @test isdir(joinpath(EXAMPLES_OUT, "example-b"))
    end

    @testset "error checking" begin
        @testset "error when no example found" begin
            # all notebooks excluded
            @test_throws ErrorException generate_examples(
                JuliaGPsDocs;
                examples_basedir="test/examples",
                exclusions=["example-a", "example-b"],
            )
        end
    end
end
