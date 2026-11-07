# Design

## Context

`test/lint.rb` reads every source file in `make lint`, `make test`, and CI, and each of its rules is a `LintTest` function, a `violations <<` line in `main`, and a `t.assert_equal` self-check against a line it must refuse and one it must pass. `tools/gates.sh` compares the branch with `origin/main` gate by gate, `static` being what `make gates` runs and `pre-push` what `tools/run_state.sh push` runs; `tools/tools_test.sh` has a case per gate. The four checks of this change follow those two shapes, so none needs a new target.

## Decisions

### Predicate-like members and keywords

`member_problem(stripped)` reads one line: on an `attr_reader`, `attr_writer`, or `attr_accessor` line, or a `Struct.new(` or `Data.define(` record declaration, a symbol `:get_`, `:is_`, or `:has_` is refused; on a `def` line, a parameter `get_x:`, `is_x:`, or `has_x:` is refused. It runs in the naming loop over `carat/**/*.rb` after the method rule, so a line gets one problem. Positional parameters are left out: the recorded blockers were members and keywords, and a local name is not part of an interface.

### The port table

`port_rows(text)` reads the rows of the table under `## 6. Ports` in `docs/architecture.md`, from the row's first cell (the port name in a code span) to the code spans of its second cell, each cut at its `(`, so `read(path, limit)` reads `read`. `port_problems(ports, rows)` compares them with each port's `defs_of` its class body, in both directions, and names a port without a row. The table is the one place an agent reads a port's contract, so a missing method there is a missing contract; reading prose spans keeps the table readable rather than adding a machine column.

### Shared holders

`assembly_readers(text)` reads `EditorAssembly`'s `attr_reader :name #: Type` lines into names and bare types; the bare types are the shared types. For each reader whose class is found under `carat/` (by its `class Name` line), `holder_problems` reads that file: every keyword of its `initialize` stored as `@k = k` whose `# @rbs @k:` type is shared needs an `attr_reader :k`, and every `attr_reader :r #: T` with a shared `T` must appear in the assembly test as `.name.r`. The assembly test calls the plugin host `host = a.plugins`, so its text is read with `host.` as `a.plugins.`. Reading only the assembly's own readers keeps the rule exact for the holders the composition root wires directly; the nested ones stay by hand.

The tree today has six stored shared keywords without a reader (`Dispatcher` and `RepeatLast` the action table; `HandleKey` the action table, the dispatcher, `InsertText`, and `EditCommandLine`) and about forty readers the test never names (the search prompt and histories, `FindMatch`, `WalkHistory`, the float use cases of the hover, the language gateway's clock, and others). The change adds the readers and one strangers row group per shared object.

### Changed tools need a case

`gate_cases` lists the scripts under `tools/` other than `tools/tools_test.sh` whose diff from the base adds or removes a line that is not blank and not a comment, and fails when `tools/tools_test.sh`'s diff adds no line starting with `expect `. It works per script: the cases call the scripts through their subcommands, so a function name is not something a case names. It joins `static` and `pre-push`; the merge group leaves it out, since the merge runs after the push gates.

## Risks

- A tooling change that only moves code would need a case; that is the intent, since the recorded blockers were untested moves.
- A rename of an assembly reader changes the text the holder rule looks for; the rule then names the row to fix, which is cheap.
