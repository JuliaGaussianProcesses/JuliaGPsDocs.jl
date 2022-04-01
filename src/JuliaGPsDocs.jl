module JuliaGPsDocs

using Literate

const LITERATE = joinpath(@__DIR__, "literate.jl")

"""
    generate_examples(pkg; examples_basedir, website_root)

Initialize the environments in each folder `pkgdir(pkg)/examples_basedir` sequentially.
Then run each example in a separate process.

## Arguments
- `pkg`: the module where the examples are stored
- `examples_basedir`: the relative path to the examples directory (`examples` by default)
- `website_root`: the website root path (for correct redirecting in the examples)
`https://juliagaussianprocesses.github.io/` by default.

"""
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

    @info "Instantiating examples environments"
    precompile_packages(examples, PKG_DIR)

    @info "Running examples in parallel"
    processes = run_examples(examples, EXAMPLES_OUT, EXAMPLES_DIR, PKG_DIR, WEBSITE)

    if isempty(processes)
        error("no process was run, check the paths used to your examples")
    elseif !success(processes)
        error("the examples $(examples[success.(processes)]) were not run successfully")
    end
    return examples
end

"""
    precompile_packages(examples, PKG_DIR)

Go in each example and try instantiating each of the examples environments.
This has to be executed sequentially, before rendering the examples in parallel.
"""
function precompile_packages(examples::AbstractVector{<:String}, PKG_DIR)
    script = "
        import Pkg;
        Pkg.activate(ARGS[1]);
        # Pkg.develop(Pkg.PackageSpec(; path=\"$(PKG_DIR)\"));
        Pkg.instantiate();
    "
    for example in examples
        cmd = `julia -e $script $example`
        if !success(cmd)
            @warn string(
                "project environment of example ",
                basename(example),
                " could not be instantiated",
            )
            read(cmd, String)
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
function run_examples(examples, EXAMPLES_OUT, EXAMPLES_DIR, PKG_DIR, WEBSITE)
    return map(examples) do example
        return run(
            pipeline(
                `$(Base.julia_cmd()) --startup-file="no" --project=$(example) $(LITERATE) $(basename(example)) $(EXAMPLES_DIR) $(PKG_DIR) $(EXAMPLES_OUT) $(WEBSITE)`;
                stdin=devnull,
                stdout=devnull,
                stderr=stderr,
            );
            wait=false,
        )::Base.Process
    end
end

end
