using JuliaGPsDocs: JuliaGPsDocs, generate_examples
using Test

@testset "JuliaGPsDocs.jl" begin
    generate_examples(JuliaGPsDocs; examples_basedir="test/examples")

    PKG_DIR = pkgdir(JuliaGPsDocs)
    EXAMPLES_PATH = joinpath(PKG_DIR, "docs", "src", "examples")
    for example in ["example-a", "example-b"]
        @test isdir(joinpath(EXAMPLES_PATH, example))
        @test isfile(joinpath(EXAMPLES_PATH, example, "notebook.ipynb"))
        @test isfile(joinpath(EXAMPLES_PATH, example, "example.md"))
        @test isfile(joinpath(EXAMPLES_PATH, example, "Manifest.toml"))
    end
    # rm(joinpath(PKG_DIR, "docs"); recursive=true)
end
