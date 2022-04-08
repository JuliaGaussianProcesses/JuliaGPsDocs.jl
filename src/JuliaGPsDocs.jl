module JuliaGPsDocs

using Literate
using RemoteREPL

const LITERATE = joinpath(@__DIR__, "literate.jl")

"""
    generate_examples(
        pkg::Module;
        examples_basedir::String="examples",
        website_root::String="https://juliagaussianprocesses.github.io/",
        inclusions::Union{Symbol,AbstractVector{<:String}}=:all,
        exclusions::AbstractVector{<:String}=[],
    )

Initialize the environments in each folder `pkgdir(pkg)/examples_basedir` sequentially.
Then run each example in a separate process.
Write output to `pkgdir(pkg)/docs/src/examples/` (deleting any pre-existing directory there).

The examples structure should be organized as follow:

examples_basedir
├─ example-a
|   ├─ script.jl
|   └─ Project.toml
└─ example-b
   ├─ script.jl
   └─ Project.toml

The output will be given by

docs
└─ src
    └─ examples
        ├─ example-a
        |   ├─ example.md
        |   ├─ notebook.ipynb
        |   └─ Manifest.toml
        └─ example-b
            ├─ example.md
            ├─ notebook.ipynb
            └─ Manifest.toml

## Arguments
- `pkg`: the module where the examples are stored
- `examples_basedir`: the relative path to the examples directory
- `website_root`: the website root path (for correct redirecting in the examples)
- `inclusions`: will only run the example directories listed
- `exclusions`: will not run any of the examples directories listed (even if present in `inclusions`)

The final set of examples run is given by `setdiff(intersect(example, inclusions), exclusions)`.

"""
function generate_examples(
    pkg::Module;
    examples_basedir="examples",
    website_root="https://juliagaussianprocesses.github.io/",
    inclusions=:all,
    exclusions=String[]
)
    PKG_DIR = pkgdir(pkg)
    EXAMPLES_DIR = joinpath(PKG_DIR, examples_basedir)
    isdir(EXAMPLES_DIR) || error("example folder $EXAMPLES_DIR not found")

    EXAMPLES_OUT = _examples_output_dir(PKG_DIR)
    ispath(EXAMPLES_OUT) && begin
        @info "Deleting previous notebook and examples"
        rm(EXAMPLES_OUT; recursive=true)
    end
    mkpath(EXAMPLES_OUT)

    WEBSITE = joinpath(website_root, string(pkg) * ".jl")

    examples = basename.(filter!(isdir, readdir(EXAMPLES_DIR; join=true)))

    if inclusions != :all
        intersect!(examples, inclusions)
    end
    setdiff!(examples, exclusions)

    examples = joinpath.(Ref(EXAMPLES_DIR), examples)

    @info "Instantiating examples environments"
    precompile_packages(pkg, examples)

    @info "Running examples in parallel"
    processes = run_examples(examples, EXAMPLES_OUT, examples_basedir, PKG_DIR, WEBSITE)

    if isempty(processes)
        error("no process was run, check the paths used to your examples")
    elseif !success(processes)
        error("the examples $(examples[success.(processes)]) were not run successfully")
    end
    return examples
end

function rolling_examples(pkg::Module;
    examples_basedir="examples",
    website_root="https://juliagaussianprocesses.github.io/",
    inclusions=:all,
    exclusions=String[])
    PKG_DIR = pkgdir(pkg)
    EXAMPLES_DIR = joinpath(PKG_DIR, examples_basedir)
    isdir(EXAMPLES_DIR) || error("example folder $EXAMPLES_DIR not found")

    DOCS_DIR = joinpath(PKG_DIR, "docs")
    EXAMPLES_OUT = joinpath(DOCS_DIR, "src", "examples")
    mkpath(EXAMPLES_OUT)

    WEBSITE = joinpath(website_root, string(pkg) * ".jl")

    examples = basename.(filter!(isdir, readdir(EXAMPLES_DIR; join=true)))

    if inclusions != :all
        intersect!(examples, inclusions)
    end
    setdiff!(examples, exclusions)

    examples = joinpath.(Ref(EXAMPLES_DIR), examples)

    @info "Instantiating examples environments"
    # precompile_packages(pkg, examples)

    @info "Keep running examples while session is on"
    processes = roll_examples(examples, EXAMPLES_OUT, EXAMPLES_DIR, PKG_DIR, WEBSITE)
    return examples

end


"""
    precompile_packages(pkg, examples)

Go in each example and try instantiating each of the examples environments.
This has to be executed sequentially, before rendering the examples in parallel.
"""
function precompile_packages(pkg, examples::AbstractVector{<:String})
    script = """
using Pkg
Pkg.add(Pkg.PackageSpec(; path="$(pkgdir(pkg))"))
Pkg.instantiate()
    """
    for example in examples
        cmd = `$(Base.julia_cmd()) --project=$example -e $script`
        if !success(cmd)
            @warn string(
                "project environment of ", basename(example), " could not be instantiated"
            )
            # By default, running `cmd` will not print anything.
            read(cmd, String)  # this will show what happened, and here give us more detail on the error
        end
    end
end

"""
    run_examples(examples, EXAMPLES_OUT, PKG_DIR, WEBSITE)

Start background processes to render the examples using the $(LITERATE) script.

## Arguments

- `examples`: vector of path to the examples folder
- `EXAMPLES_OUT`: path to examples output
- `examples_basedir`: relative path to the root examples folder
- `PKG_DIR`: path to the package to be developed
- `WEBSITE`: path to the website url
"""
function run_examples(examples, EXAMPLES_OUT, examples_basedir, PKG_DIR, WEBSITE)
    cmd = addenv( # From https://github.com/devmotion/CalibrationErrors.jl/
        Base.julia_cmd(), "JULIA_LOAD_PATH" => (Sys.iswindows() ? ";" : ":") * @__DIR__
    )
    return map(examples) do example
        return run(
            pipeline(
                `$(cmd) --startup-file="no" --project=$(example) $(LITERATE) $(basename(example)) $(examples_basedir) $(PKG_DIR) $(EXAMPLES_OUT) $(WEBSITE)`;
                stdin=devnull,
                stdout=devnull,
                stderr=stderr,
            );
            wait=false,
        )::Base.Process
    end
end

"""
    roll_examples(examples, EXAMPLES_OUT, PKG_DIR, WEBSITE)

Start background processes to render the examples using the $(LITERATE) script.

## Arguments

- `examples`: vector of path to the examples folder
- `EXAMPLES_OUT`: path to examples output
- `EXAMPLES_DIR`: path to the root examples folder
- `PKG_DIR`: path to the package to be developed
- `WEBSITE`: path to the website url
"""
function roll_examples(examples, EXAMPLES_OUT, EXAMPLES_DIR, PKG_DIR, WEBSITE)
    cmd = addenv( # From https://github.com/devmotion/CalibrationErrors.jl/
        Base.julia_cmd(), "JULIA_LOAD_PATH" => (Sys.iswindows() ? ";" : ":") * "/home/theo/.julia/dev/JuliaGPsDocs/"
    )
    example_to_port = Dict(examples[i] => 5000 + i for i in eachindex(examples))
    processes = map(examples) do example
        port = example_to_port[example]
        # TODO check for port opening and close if necessary
        return run(
            pipeline(
                `$(cmd) --startup-file="no" --project=$(example) -e "using RemoteREPL; serve_repl($(port))" $(basename(example)) $(EXAMPLES_DIR) $(PKG_DIR) $(EXAMPLES_OUT) $(WEBSITE)`;
                stdin=devnull,
                stdout=stdout,
                stderr=stderr,
            );
            wait=false,
        )::Base.Process
    end
    sleep(2)
    map(examples) do example
        port = example_to_port[example]
        RemoteREPL.remote_eval(RemoteREPL.Sockets.localhost, port, "@async include(\"$(LITERATE)\")")
    end
    # Create an infinite loop where one checks when a file is modified and rerun the appropriate process when necessary

    # map(examples) do example
    #     port = example_to_port[example]
    #     RemoteREPL.remote_eval(RemoteREPL.Sockets.localhost, port, "@async exit()")
    # end
end

_examples_output_dir(PKG_DIR) = joinpath(PKG_DIR, "docs", "src", "examples")

"""
    find_generated_examples(pkg)

Find all generated notebooks for package `pkg` and return it as a list, to be
used as part of the `pages` argument to `Documenter.makedocs()`.
"""
function find_generated_examples(pkg)
    EXAMPLES_OUT = _examples_output_dir(pkgdir(pkg))
    return map(
        basename.(
            filter!(isdir, readdir(EXAMPLES_OUT; join=true)),
        ),
    ) do x
        joinpath("examples", x, "index.md")
    end
end

"""
Common `doctestfilters` for JuliaGaussianProcesses docs.
"""
const DOCTEST_FILTERS = [
    r"{([a-zA-Z0-9]+,\s?)+[a-zA-Z0-9]+}",
    r"(Array{[a-zA-Z0-9]+,\s?1}|Vector{[a-zA-Z0-9]+})",
    r"(Array{[a-zA-Z0-9]+,\s?2}|Matrix{[a-zA-Z0-9]+})",
]

end
