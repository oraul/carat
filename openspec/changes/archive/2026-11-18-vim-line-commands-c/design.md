# Design

## Context

Ex handlers get only the state and the parsed command; nothing in `carat/use_cases/ex/` feeds keys. `HandleKey#call(state, code)` is the one key entry, and it reaches the ex commands itself through the command line, so `:normal` re-enters it. `EditorAssembly` registers the ex commands before it builds `HandleKey`, and the plugins are prepared right after the registrations, so the registrations cannot move later.

## Goals / Non-Goals

Goals: `:normal`, `:{range}normal`, `:g/x/normal`, `:p`, `:{range}p` as Neovim; one clamp; the address count from `ExRange`. Non-goals: the flags of `:p`, `:normal!` without mappings, `'maxmapdepth'`.

## Decisions

- `HandleKey` and what it needs that was built after the registrations (`EditCommandLine`, `HideKeyHints`, `FollowPalette`, `Dispatcher`) are built before them; every dependency of theirs already exists there. `NormalCommandHandler` receives the one `HandleKey`, so no collaborator is attached later. Rejected: a forwarding object set after construction, which `CommandRunner` was introduced to avoid.
- Keys are the characters of the argument, each its code point, as Neovim reads `:normal` literally. After them a pending keymap prefix gets `Key::TIMEOUT` (the typeahead ran out), then `Key::ESC` is fed while the mode is not normal or the grammar holds a partial command, at most three times, as Neovim's `exec_normal` ends an unfinished command.
- Undo: `EditorState#normal_depth` counts the running `:normal` commands. While it is above 0 the dispatcher does not close an open transaction as a stale insert session, and `LeaveInsert` leaves it open, so the keys join the transaction the handler (or its caller: the command line's dispatch, a global) opened. The handler opens one when none is open and commits it. The depth also gives E192 at 100.
- `:p` is a `LineCommandHandler`: `lines_of`, `RegisterCount.parse_count` and `counted` as `:j`, `record_jump` as a range alone, and `place_cursor`. It answers `Outcome.from_print`, with a new member of `Outcome`, `printed`, and `GlobalCommand#visit` joins printed messages with line feeds where it keeps the last message otherwise.
- `ExRange` gains a member `addresses` (0, 1, or 2 as Neovim's `addr_count` for the checks Carat has: 2 for `%` and for two or more addresses); `:j` reads it.
- `place_cursor` becomes `state.clamp_col(row, want)`, with `state.max_col(row)` for a wanted column past the end (-1).

## Risks / Trade-offs

- Re-entering `HandleKey` runs its `follow` step (plugins observe, the view is arranged) for each line of `:g/x/normal`; correct, at some cost on large globals.
- A key sequence bound by the configuration that runs `:normal` with itself recurses; the depth limit of 100 answers E192 before the stack runs out.
