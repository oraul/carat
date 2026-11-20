# Proposal

## Why

A project `.caratrc` comes with whatever directory the user opens, so it is untrusted input, and three security Lows from the sprint-20 and sprint-22 sweeps let it reach further than the rest of its rules allow: the gateway checks the file with a stat that does not follow a link and then opens it by path, which does follow one, so a file swapped for a link between the two is read; a project file may bind any key to an action that writes the buffer or quits the editor (`file.save`, `quit.all`, `quit.write_all`, `window.quit`); and it may bind keys in any mode to the command line's own actions, which run or recall an ex command (`cmdline.execute` and the history keys), so a key the user types runs a command they did not type. Two quality findings in the option reader ride along: `scroll`, `scrolloff`, `timeoutlen`, and `undolevels` take any nine-digit number, and the reader repeats its bounded-number and known-name checks branch by branch. This is the backlog lane's Sprint 23 item 1, outside the numbered roadmap of `docs/architecture.md` section 12, which closed; it hardens the delivered `caratrc-config` and `untrusted-config-limits` items.

## What Changes

- `FilePort#read_no_link(path, limit)`: `read`'s bounded, non-blocking read, refusing a path that is a symbolic link when it opens it (`File::NOFOLLOW` in `DiskFiles`, the link mark in `MemoryFiles`). `RcConfigGateway` reads the project file through it, so a link swapped in after the stat is refused as "cannot be read"; the user file, which may be a link, is still read with `read`.
- `Config` refuses a project file's keymap line whose action writes or quits (`file.save`, `quit.all`, `quit.write_all`, `window.quit`) or is a command-line action (`cmdline.*`), in every mode, reported as `file:line: write, quit, and command-line actions are not bound from a project file`; the defaults and the user file still bind them, and the project file still unbinds them with `none`. It refuses a project file's `keymap.leader` line too, reported as `file:line: keymap.leader is not read from a project file`, since a project leader such as `d` would move the defaults' and the user's `<leader>fs` and `<leader>qw` onto `dfs` and `dqw`, a write and a write-and-quit typed as a Vim command.
- `Options` bounds `scroll` and `scrolloff` to 0 to 9999 lines, `timeoutlen` to 0 to 10000 milliseconds, and `undolevels` to 0 to 10000, a value outside reported as `file:line: option.<name> takes a number from <low> to <high>` and the value before it kept, as `tabstop` and `keyhints.delay` are.
- `Options#apply` checks every bounded number through one private `bounded` and every named value through one private `named`, replacing `width_problem`, `range_problem`, and the seven copied known-name branches; the messages stay as they were.
- Docs: `docs/architecture.md` (the port table and the project-file rule of section 7), `README.md` (the option bounds and the project-file sentence), `docs/compatibility.md` rows of the four options, and the code map's area 3.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `config-files`: ADDED requirements "A project file is refused when it is a link at the open", "A project file cannot bind keys to a write, a quit, or the command line", "A project file cannot set the leader", and "Line, wait, and undo numbers are bounded".

## Out of scope

- The seven other headings of the queue line (the tokenizer, the Spinel append note, visual star, the background literals, the collaborator declarations, the Config predicates, the gen-config header): the plan queued them in its pool, already in the backlog, and they are not re-appended.
- A project file binding a plugin's file action (`plugin.explorer.delete` and the like) in a mode the plugin reads; recorded as a finding, not changed here.
- `:set` and the count of `<C-d>`, which set `scroll` from what the user types and keep Vim's behavior.
- No `tools/rules.sh` edit; no file of the feature lane.
- Assumptions: the bounds 9999 lines for `scroll` and `scrolloff` (Vim's idiom `scrolloff 999` fits), 10000 milliseconds for `timeoutlen` (the key hints' limit), and 10000 for `undolevels` (ten times the shipped 1000); "the command line actions" are the `cmdline.*` actions, while `mode.cmdline`, which only opens the prompt for the user to type, stays bindable. The refactor heading changes no message, so its proof is every unchanged option row beside the new rows of the four options, which fail before the change.

## Impact

- README.md: changed, the option bounds and the project file's refused bindings and leader.
- docs/architecture.md: changed, the `FilePort` row of section 6 and the project-file rule and gateway row of section 7; the validation bullet of section 7 names the files by their paths above instead of repeating the three names, and a few words of section 7 are tightened, so the doc stays within its docs-lint budget.
- CLAUDE.md: unchanged, no process changes.
- docs/codebase-map.md: area 3 (`Config`, `Options`, `RcConfigGateway`) and the ports and drivers rows that list `FilePort` methods.
- docs/compatibility.md: the rows of `option.scroll`, `scrolloff`, `timeoutlen`, `undolevels` where they exist.
- Performance: configuration loading only; no hot path changes.
