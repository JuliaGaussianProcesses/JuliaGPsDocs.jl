
# Retrieve name of example and output directory
if length(ARGS) != 5
    error(
        """
        please specify, in this order:
        - the basename of the example directory (e.g. `0-intro-1d`)
        - the full path to the examples directory (e.g. `examples`)
        - the root of the package directory (e.g. `~/AbstractGPs.jl/`)
        - the full path to the output directory (e.g. `path/to/docs/src/`)
        - the base URL of the website (e.g. `https://juliagaussianprocesses.github.io/AbstractGPs.jl`)
        """
    )
end
const EXAMPLE = ARGS[1]
const EXAMPLES_DIR = ARGS[2]
const PKG_DIR = ARGS[3]
const OUT_DIR = ARGS[4]
const WEBSITE = ARGS[5]

# Activate environment
# Note that each example's Project.toml must include Literate as a dependency
using Pkg: Pkg

using InteractiveUtils
Pkg.instantiate()
pkg_status = sprint() do io
    Pkg.status(; io=io)
end

using Literate: Literate

const MANIFEST_OUT = joinpath(EXAMPLE, "Manifest.toml")
mkpath(joinpath(OUT_DIR, EXAMPLE))
# Make a copy of the Manifest to include in the notebook
const EXAMPLE_PATH = joinpath(EXAMPLES_DIR, EXAMPLE)
cp(joinpath(EXAMPLE_PATH, "Manifest.toml"), joinpath(OUT_DIR, MANIFEST_OUT); force=true)

using Markdown: htmlesc

function preprocess(content)
    # Add link to nbviewer below the first heading of level 1
    sub = SubstitutionString(
        """
#md # ```@meta
#md # EditURL = "@__REPO_ROOT_URL__/examples/@__NAME__/script.jl"
#md # ```
#md #
\\0
#
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/examples/@__NAME__.ipynb)
#md #
# *You are seeing the
#md # HTML output generated by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and
#nb # notebook output generated by
# [Literate.jl](https://github.com/fredrikekre/Literate.jl) from the
# [Julia source file](@__REPO_ROOT_URL__/examples/@__NAME__/script.jl).
#md # The corresponding notebook can be viewed in [nbviewer](@__NBVIEWER_ROOT_URL__/examples/@__NAME__.ipynb).*
#nb # The rendered HTML can be viewed [in the docs]($(WEBSITE)/dev/examples/@__NAME__/).*
#
#md # ---
#
        """,
    )
    content = replace(content, r"^# # [^\n]*"m => sub; count=1)

    # remove VSCode `##` block delimiter lines
    content = replace(content, r"^##$."ms => "")

    """ The regex adds "# " at the beginning of each line; chomp removes trailing newlines """
    literate_format(s) = chomp(replace(s, r"^"m => "# "))

    # <details></details> seems to be buggy in the notebook, so is avoided for now
    info_footer = """
    #md # ```@raw html
    # <hr />
    # <h6>Package and system information</h6>
    # <details>
    # <summary>Package information (click to expand)</summary>
    # <pre>
    $(literate_format(htmlesc(pkg_status)))
    # </pre>
    # To reproduce this notebook's package environment, you can
    #nb # <a href="./Manifest.toml">
    #md # <a href="./Manifest.toml">
    # download the full Manifest.toml</a>.
    # </details>
    # <details>
    # <summary>System information (click to expand)</summary>
    # <pre>
    $(literate_format(htmlesc(sprint(InteractiveUtils.versioninfo))))
    # </pre>
    # </details>
    #md # ```
    """

    return content * info_footer
end

# Convert to markdown and notebook
const SCRIPTJL = joinpath(EXAMPLE_PATH, "script.jl")
Literate.markdown(SCRIPTJL, joinpath(OUT_DIR, EXAMPLE); name=EXAMPLE, execute=true, preprocess=preprocess)
Literate.notebook(SCRIPTJL, joinpath(OUT_DIR, EXAMPLE); name=EXAMPLE, execute=true, preprocess=preprocess)
