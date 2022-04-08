# Example notebooks

In JuliaGaussianProcesses, each notebook example is stored in its own subdirectory `<PACKAGE-ROOT>/examples/<EXAMPLE-SUBDIR>`.
The notebook itself is stored in [Literate.jl](https://github.com/fredrikekre/Literate.jl) format in a file called `script.jl`.

To run an example script locally, you can start the Julia REPL from the package root directory,
and activate the environment of the example with the correct path:
```julia
julia> ] activate examples/my-example
```
Alternatively, you can start Julia with `julia --project=examples/my-example`. Then install all required
packages with
```julia
julia> ] instantiate
```
Afterwards simply run
```julia
julia> include("examples/my-example/script.jl")
```
In particular when editing an example, it can be convenient to (re-)run only some parts of
an example.
Many editors with Julia support such as VSCode, Juno, and Emacs support the evaluation of individual lines or code chunks.

You can convert a notebook to markdown and Jupyter notebook formats, respectively, by executing
```julia
julia> using Literate
julia> Literate.markdown("examples/my-example/script.jl", "output_directory")
julia> Literate.notebook("examples/my-example/script.jl", "output_directory")
```
(see the [Literate.jl docs](https://fredrikekre.github.io/Literate.jl/v2/) for additional options) or run
```shell
julia docs/literate.jl myexample output_directory
```
which also executes the code and generates embedded plots etc. in the same way as in building the AbstractGPs documentation.

## Add a new example

Create a new subdirectory `<package-root>/examples/<new-example>`, and
put your code in the file `<package-root>/examples/<new-example>/script.jl` so that it will get
picked up by the automatic docs build.

Every example uses a separate project environment. Therefore you should also create a new
project environment in the directory of the example that contains all packages required by your script.
Note that the dependencies of your example *must* include the `Literate` package (see https://github.com/JuliaGaussianProcesses/JuliaGPsDocs.jl/issues/2).

From a Julia REPL started in your package directory, you can run
```julia
julia> ] activate examples/new-example
julia> ] add Literate
julia> # the following line adds an AbstractGPs dependency that is based on the local directories, not a hash:
julia> ] dev .
julia> # add any other example-specific dependencies
```
to generate the project files.

Make sure to commit the `Project.toml` (but not the `Manifest.toml` file) when you want to contribute your example in a pull request.

Note that each example `script.jl` should have a level 1 heading with the example title in its first line, e.g.
```julia
# # Demonstration of Foo

...
```
