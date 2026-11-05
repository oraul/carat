## Why

Carat has no `:g`, `:g!`, or `:v`, so a command cannot be run on every line that matches, or does not match, a pattern (`docs/queue.md` item 1). This change delivers the last part of roadmap item 6, `search-and-substitute` (`docs/architecture.md` section 12), after `buffer-search` and `buffer-substitute`. The most common global, `:g/pat/d`, needs a command that deletes lines, and Carat has no `:d`; the acceptance asks that a command that deletes or inserts lines runs on exactly the lines that matched, so `:d` comes with it.

## What Changes

- `:[range]g[lobal]/{pattern}/[cmd]` marks every line of the range (every line without one) that matches the pattern, then runs the ex command `cmd` with the cursor on each marked line in turn; `:g!` and `:v[global]` mark the lines that do not match. Without `cmd` the marked lines are listed, as `:p` would.
- A line deleted by the command run on an earlier line is not visited, and lines the command inserts are not visited; the lines keep their marks through every edit, so a marked line is found however the lines above it moved.
- The delimiter is any ASCII character but a letter (`E146`); `\` and a non-ASCII delimiter answer Not implemented. An empty pattern uses the last search pattern (`E35` without one); no argument is `E148: Regular expression missing from :global`; `:v!` is `E477`.
- The pattern goes through the search translation with `ignorecase` and `smartcase`, and becomes the last search pattern, the `/` register, a search history entry when typed, and the last substitute pattern, as in Vim. The marking scan is charged to one work budget; when it runs out nothing runs and the message is `E363`.
- No marked line answers `Pattern not found: pat` for `:g` and `Pattern found in every line: pat` for `:g!` and `:v`. The first command that fails stops the global with its message; otherwise the last message a command gave is shown.
- A global is one undo step, is not repeated by `.`, and stops when its command leaves the buffer it started on. A global run by a global's command acts on the cursor line only, and with a range other than every line is `E147: Cannot do :global recursive with a range`.
- `:[range]d[elete] [x] [count]` deletes the lines of the range (the cursor line without one) into register `x` or the unnamed register, shifting the numbered registers as a linewise delete does; a count deletes count lines from the range's last line. The cursor goes to the first non-blank of the line that took the first deleted line's place. `E477` for a bang, `E488: Trailing characters` for a register that cannot be written or anything after the count, `E939` for a zero count.

## Capabilities

### New Capabilities

- `global`: the global commands `:g`, `:g!`, and `:v`: marking, running a command per marked line through edits that move lines, messages, the pattern's memory, the work budget, undo, and recursion.
- `line-commands`: the ex commands that work on whole lines of a range, starting with `:d[elete]`.

### Modified Capabilities

None: `:s` and the ranges behave as before; the global reads them as `buffer-substitute` defined them.

## Impact

- Domain: new `GlobalArgs` (the parsed argument), `GlobalMarks` (the marked lines, moved by every splice), and `RegisterCount` (the `[x] [count]` argument); `Buffer` gains the `global_marks` member, shifted in its one splice.
- Use cases: new `GlobalCommand` (marks, runs the command through the `CommandRunner`, reports), `DeleteLines`, `GlobalCommandHandler` (`g[lobal]`, `v[global]`), and `DeleteCommandHandler` (`d[elete]`).
- Adapters: `EditorAssembly` builds the two use cases with the runner and registers the handlers after `:&`, before the plugin commands.
- Docs: `docs/compatibility.md` rows and a Global section, `docs/codebase-map.md` area 12, `docs/backlog.md`, `README.md`, and the status line of `CLAUDE.md`.
- Out of scope: `:m`, `:t`, `:normal`, and `:p` (later changes, recorded in `docs/backlog.md`); `\/`, `\?`, and `\&` as the delimiter; command chaining with `|`; the totals Vim prints after a global (`N substitutions on M lines` summed over the lines, `N fewer lines`); interrupting a global with Ctrl-C.
- Assumptions: a global with no command lists the marked lines and leaves the cursor on the first non-blank of the last one, since Carat has no `:p` and Neovim's column there depends on `startofline`; the message after a global is the last one its command gave rather than Vim's totals; the global stops when its command switches buffers, where Vim would go on in the new buffer; `:d` writes no message, as Carat's `dd` writes none.
