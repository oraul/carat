# carat

A terminal IDE written in Ruby with Neovim's modal editing model, built, tested, and shipped with Spinel. `docs/architecture.md` holds the design and the roadmap; `CLAUDE.md` holds the commands and conventions.

Today it is an editor with one window: normal, insert, and command-line modes, cursor motions, insert-mode editing, and `:w`, `:q`, `:wq`, and `:e`. Build it with `make build` and run `build/bin/carat FILE`; `docs/compatibility.md` lists the Neovim commands it implements.
