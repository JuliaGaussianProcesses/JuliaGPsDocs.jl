using JuliaGPsDocs: JuliaGPsDocs, generate_examples, rolling_examples
using Test

@testset "JuliaGPsDocs.jl" begin
    generate_examples(JuliaGPsDocs; examples_basedir="test/examples")

    PKG_DIR = pkgdir(JuliaGPsDocs)
    EXAMPLES_PATH = joinpath(PKG_DIR, "docs", "src", "examples")
    # Test that the examples are generated
    for example in ["example-a", "example-b"]
        @test isdir(joinpath(EXAMPLES_PATH, example))
        @test isfile(joinpath(EXAMPLES_PATH, example, "notebook.ipynb"))
        @test isfile(joinpath(EXAMPLES_PATH, example, "example.md"))
        @test isfile(joinpath(EXAMPLES_PATH, example, "Manifest.toml"))
    end

    generate_examples(JuliaGPsDocs; examples_basedir="test/examples", exclusions=["example-a"])
    @test !isdir(joinpath(EXAMPLES_PATH, "example-a"))
    @test isdir(joinpath(EXAMPLES_PATH, "example-b"))

    generate_examples(JuliaGPsDocs; examples_basedir="test/examples", inclusions=["example-b"])
    @test !isdir(joinpath(EXAMPLES_PATH, "example-a"))
    @test isdir(joinpath(EXAMPLES_PATH, "example-b"))

    @test_throws ErrorException generate_examples(JuliaGPsDocs; examples_basedir="test/examples", exclusions=["example-a", "example-b"])
end
