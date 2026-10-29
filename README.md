# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with one window: normal, insert, operator-pending, and command-line modes; counts, the `"x` register prefix, and Neovim's `[count] operator [count] motion` grammar; the motions `h l 0 ^ $ f F t T ; , j k G gg + - _ w W b B e E ge gE ( ) { } H M L`; the text objects `iw aw iW aW is as ip ap` and the bracket and quote objects; the operators `d c y > <` with `dd cc yy >> <<` and `x s S C D Y J p P`; the unnamed and named registers; insert-mode editing; and `:w`, `:q`, `:wq`, and `:e`. `docs/compatibility.md` lists every Neovim command it implements with its test, and `docs/backlog.md` the known items left for later changes.

## Building

The prerequisites are a C compiler, `make`, `git`, and `curl`. No Ruby interpreter is needed, not even to build the compiler.

1. `make toolchain` fetches the pinned Spinel commit into `tmp/.spinel`, builds it, and installs `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain`. Both directories are ignored by git, every `make` target finds the toolchain there on its own, and `make toolchain-clean` removes them.
2. `make build` compiles the editor to `build/bin/carat` and prints the alias line to add to your shell profile to run it from anywhere; `make install` puts it on the `PATH` instead.
3. `make check` builds, regenerates the config mirror, and runs the tests and `spinel-doctor`; run it before every push.

| Command | What it does |
| --- | --- |
| `make doctor` | Check that `spinel`, `spin`, a C compiler, and `node` are on the path |
| `make toolchain` | Fetch, build without Ruby, and install the pinned Spinel commit under `tmp/` |
| `make toolchain-clean` | Remove `tmp/`, the Spinel checkout and the installed toolchain |
| `make build` | Compile `bin/*.rb` into `build/bin` and print how to run it from anywhere |
| `make run FILE=path` | Build and run the editor on a file |
| `make test` | Build, then run every test program against its snapshot |
| `make lint` | Run the lint test program only |
| `make types` | Print the signatures Spinel inferred |
| `make diagnose` | Run `spinel-doctor` on every compile root |
| `make snapshots` | Rebuild the test programs and rewrite their snapshots |
| `make gen-config` | Regenerate the default config mirror |
| `make check` | Build, gen-config, test, and diagnose |
| `make spec-list`, `make spec-validate`, `make spec-update` | The OpenSpec commands |
