using InteractiveUtils

using Literate: Literate
using Markdown: htmlesc
using Pkg: Pkg

# Retrieve name of example and output directory
if length(ARGS) != 4
    error(
        """
        please specify, in this order:
        - the basename of the example directory (e.g. `0-intro-1d`)
        - the root of the package directory (e.g. `~/AbstractGPs.jl/`)
        - the output directory (e.g. `path/to/docs/src/`)
        - the base URL of the website (e.g. `https://juliagaussianprocesses.github.io/AbstractGPs.jl`)
        """
    )
end
const EXAMPLE = ARGS[1]
const PKG_DIR = ARGS[2]
const OUT_DIR = ARGS[3]
const WEBSITE = ARGS[4]

include("literate_functions.jl")

run_example(EXAMPLE, PKG_DIR, OUT_DIR, WEBSITE)
