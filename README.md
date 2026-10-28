# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with one window: normal, insert, operator-pending, and command-line modes; counts, the `"x` register prefix, and Neovim's `[count] operator [count] motion` grammar; the motions `h l 0 ^ $ f F t T ; , j k G gg + - _ w W b B e E ge gE ( ) { } H M L`; the text objects `iw aw iW aW is as ip ap` and the bracket and quote objects; the operators `d c y > <` with `dd cc yy >> <<` and `x s S C D Y J p P`; the unnamed and named registers; insert-mode editing; and `:w`, `:q`, `:wq`, and `:e`. Build it with `make build` and run `build/bin/carat FILE`; `docs/compatibility.md` lists every Neovim command it implements with its test, and `docs/backlog.md` the known items left for later changes.

| Command | What it does |
| --- | --- |
| `make doctor` | Check that `spinel`, `spin`, a C compiler, and `node` are on the path |
| `make toolchain` | Fetch, build, and install the pinned Spinel commit |
| `make build` | Compile `bin/*.rb` into `build/bin` |
| `make run FILE=path` | Build and run the editor on a file |
| `make test` | Build, then run every test program against its snapshot |
| `make lint` | Run the lint test program only |
| `make types` | Print the signatures Spinel inferred |
| `make diagnose` | Run `spinel-doctor` on every compile root |
| `make snapshots` | Rebuild the test programs and rewrite their snapshots |
| `make gen-config` | Regenerate the default config mirror |
| `make check` | Build, gen-config, test, and diagnose |
| `make spec-list`, `make spec-validate`, `make spec-update` | The OpenSpec commands |
