# Queue

The ordered queue of changes, one line each with its reason. `/status` prints it; the planner keeps it, citing the data behind each decision against `docs/goals.md`.

1. `delivery-pipeline` (this change): the workflow, the narrow agents, the run state, and the gates, so no rule depends on memory.
2. `planner-and-metrics`: the planner agent, a metrics history of benchmarks, CI, tokens, and gate results, the retrospective, periodic reviews, `/plan` and `/review`. Before `authoring-kit` because no per-change metrics exist yet and later decisions need a baseline.
3. `authoring-kit`: golden examples, make generators, Spinel notes, the docs size and quality gate, and slimmer `docs/architecture.md` and contributor instructions.
4. `search-and-substitute`: the next roadmap item, Neovim command support.
5. UI track, in order: theme tokens with the four palettes and per-palette syntax colors; the buffer list; bars (a global status bar and buffer tabs, rendered in the core with plugin segments); the leader layout (breaking: the leader `w` and `q` keys become groups, save on Ctrl-S); floating windows; discoverability (key hints and a command palette); the finder; layout slots with breadcrumbs; the mouse; feedback (messages, notifications, a start screen).
6. Language services with autocomplete and diagnostics.
7. Backlog items worth a change: move the plugin host to the adapters layer behind a port; reduce the Spinel miscompilations and report them upstream.

## Decisions

- The planner goes first: measure before improving. 1,231 of 2,130 contributor tool calls were lookups, and no per-run token record exists to tell whether a later change helped.
- Agent frontmatter may name a model tier alias: the cheaper alias for mechanical phases saves tokens (a scout used about 170 thousand tokens per pack), while judgment phases (the contributor and the reviewers) keep the session's model.
- UI defaults: the bars live in the core, an exception to be recorded in `docs/architecture.md` section 13; the leader change is breaking and says so; the UI track comes after `search-and-substitute`.
