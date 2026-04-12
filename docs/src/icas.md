# Using `icas` (Giac C++ REPL)

`icas` is the interactive C++ command-line interface shipped with upstream Giac. It lets you evaluate Giac expressions directly, without going through Giac.jl or Julia at all. This is especially useful for **isolating whether a problem lives in Giac.jl (the Julia bindings) or in Giac itself (the upstream C++ library)**.

If a computation produces an unexpected result in Julia, reproducing it in `icas` answers one question cleanly:

- **Same result in `icas`** → the behaviour comes from upstream Giac. Report it on the [Giac issue tracker](https://xcas.univ-grenoble-alpes.fr/forum/) or verify against the [Giac documentation](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html).
- **Different result in `icas`** → the issue is in Giac.jl (wrapper, conversion, display, …). Please file it on the [Giac.jl issue tracker](https://github.com/s-celles/Giac.jl/issues).

## Launching `icas` via `GIAC_jll`

`GIAC_jll` ships the `icas` binary alongside the shared library, so you do not need a system install of Giac.

```julia
julia> using GIAC_jll

julia> GIAC_jll.icas_path  # absolute path to the binary
"/home/user/.julia/artifacts/…/bin/icas"

julia> run(`$(GIAC_jll.icas())`)
```

`GIAC_jll.icas()` returns a `Cmd` with the environment correctly set up (library paths, etc.), which is why you should prefer it over calling `icas_path` directly.

## Running `icas` from a shell (outside Julia)

Once you know the artifact path printed by `GIAC_jll.icas_path`, you can launch `icas` directly from a terminal without starting Julia every time. Copy the path and run it:

```bash
# Linux / macOS — path from GIAC_jll.icas_path
~/.julia/artifacts/ecf2beae5145924fc8d151fa5b57b85738c8367b/bin/icas
```

```powershell
# Windows PowerShell
& "$HOME\.julia\artifacts\…\bin\icas.exe"
```

You only need Julia the first time, to discover the path. After that you can add the `bin/` directory to your `PATH` (or make a shell alias) and invoke `icas` like any other command:

```bash
export PATH="$HOME/.julia/artifacts/ecf2beae5145924fc8d151fa5b57b85738c8367b/bin:$PATH"
icas
```

!!! note
    The artifact hash in the path (`ecf2be…`) changes when `GIAC_jll` is updated. If `icas` suddenly fails to start after upgrading Giac.jl, re-run `GIAC_jll.icas_path` in Julia to get the new path.

A session looks like:

```
Welcome to giac readline interface, version 2.0.0
(c) 2002,2023 B. Parisse & others
…
Press CTRL and D simultaneously to finish session
Type ?commandname for help
0>> sin(2)
sin(2)
1>> sin(2.0)
0.909297426826
2>> evalf(sin(2))
0.909297426826
```

Press `Ctrl-D` to exit.

## Reproducing a Giac.jl issue in `icas`

A typical triage workflow:

1. Note the exact Giac expression Julia sends to the library. For most Giac.jl calls this is just the textual form of the command, e.g. `integrate(sin(x)^2, x)`.
2. Launch `icas` as above.
3. Type the same expression at the `>>` prompt and compare the result with what Giac.jl returned.
4. Include both outputs in your bug report.

!!! tip
    If you are unsure what string Giac.jl actually sends to Giac, you can evaluate the expression in Julia and `print` it — the `Giac` string form is what `icas` will parse.

## See also

- [`GIAC_jll` on JuliaHub](https://juliahub.com/ui/Packages/General/GIAC_jll)
- [Developer troubleshooting](developer/troubleshooting.md)
