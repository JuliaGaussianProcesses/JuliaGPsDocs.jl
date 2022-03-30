module JuliaGPsDocs

using Literate
using Pkg

include("literate_functions.jl")

const LITERATE = joinpath(@__DIR__, "literate.jl")

function generate_examples(
    pkg::Module;
    examples_basedir="examples",
    website_root="https://juliagaussianprocesses.github.io/",
)
    PKG_DIR = pkgdir(pkg)
    EXAMPLES_DIR = joinpath(PKG_DIR, examples_basedir)
    isdir(EXAMPLES_DIR) || error("example folder $EXAMPLES_DIR not found")

    DOCS_DIR = joinpath(PKG_DIR, "docs")
    EXAMPLES_OUT = joinpath(DOCS_DIR, "src", "examples")
    ispath(EXAMPLES_OUT) && begin
        @info "Deleting previous notebook and examples"
        rm(EXAMPLES_OUT; recursive=true)
    end
    mkpath(EXAMPLES_OUT)

    WEBSITE = joinpath(website_root, string(pkg) * ".jl")

    examples = filter!(isdir, readdir(EXAMPLES_DIR; join=true))

    precompile_packages(examples)

    processes = run_examples(examples, EXAMPLES_OUT, PKG_DIR, WEBSITE)

    if !isempty(processes)
        error("no process was run, check the paths used to your examples")
    elseif !success(processes)
        error("the examples $(examples[success.(processes)]) were not run successfully")
    end
    return examples
end

"""
    precompile_package(examples)

Go in each example and try instantiating each of the examples environments.
This has to be executed sequentially, before rendering the examples in parallel.
"""
function precompile_package(examples::AbstractVector{<:String})
    let script = "using Pkg; Pkg.activate(ARGS[1]); Pkg.instantiate()"
        for example in examples
            if !success(`$(Base.julia_cmd()) -e $script $example`)
                error(
                    "project environment of example ",
                    basename(example),
                    " could not be instantiated",
                )
            end
        end
    end
end

"""
    run_examples(examples, EXAMPLES_OUT, PKG_DIR, WEBSITE)

Start background processes to render the examples using the $(LITERATE) script.

## Arguments

- `examples`: vector of path to the examples folder
- `EXAMPLES_OUT`: path to examples output
- `PKG_DIR`: path to the package to be developed
- `WEBSITE`: path to the website url
"""
function run_examples(examples, EXAMPLES_OUT, PKG_DIR, WEBSITE)
    return map(examples) do example
        return run(
            pipeline(
                `$(Base.julia_cmd()) $(LITERATE) $(basename(example)) $(PKG_DIR) $(EXAMPLES_OUT) $(WEBSITE)`;
                stdin=devnull,
                stdout=devnull,
                stderr=stderr,
            );
            wait=false,
        )::Base.Process
    end
end

end
