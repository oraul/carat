# Queue

The ordered queue of changes, one line each with its reason. `/status` prints it; the planner keeps it, citing the data behind each decision against `docs/goals.md`.

1. `authoring-kit`: golden examples, make generators, Spinel notes, the docs size and quality gate, and slimmer `docs/architecture.md` and contributor instructions.
2. `search-and-substitute`: the next roadmap item, Neovim command support.
3. UI track, in order: theme tokens with the four palettes and per-palette syntax colors; the buffer list; bars (a global status bar and buffer tabs, rendered in the core with plugin segments); the leader layout (breaking: the leader `w` and `q` keys become groups, save on Ctrl-S); floating windows; discoverability (key hints and a command palette); the finder; layout slots with breadcrumbs; the mouse; feedback (messages, notifications, a start screen).
4. Language services with autocomplete and diagnostics.
5. Backlog items worth a change: move the plugin host to the adapters layer behind a port; reduce the Spinel miscompilations and report them upstream.

## Decisions

- The planner went first: measure before improving. 1,231 of 2,130 contributor tool calls were lookups, and no per-run token record existed to tell whether a later change helped. From `planner-and-metrics` on, the planner keeps this file from `docs/metrics.tsv`, whose baseline is `lh` at 27.0 objects per key and 2 re-narrowing rounds for both roots, and `authoring-kit` is the first change measured against it.
- Agent frontmatter may name a model tier alias: the cheaper alias for mechanical phases saves tokens (a scout used about 170 thousand tokens per pack), while judgment phases (the contributor and the reviewers) keep the session's model.
- UI defaults: the bars live in the core, an exception to be recorded in `docs/architecture.md` section 13; the leader change is breaking and says so; the UI track comes after `search-and-substitute`.
