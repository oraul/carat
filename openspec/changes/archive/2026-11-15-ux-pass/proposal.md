# Proposal

## Why

No review of how carat feels in use is recorded: the gates measure code, not use. The user's now-request puts a pleasant UI and UX first, in carat's Facet design language (`docs/goals.md`, goal 1), and sprint 7's head item in `docs/queue.md` (`ux-pass`, tier T2) asks for a review of the real binary, with its screens as evidence, before sprint 9's planning picks the UI work that follows.

## What Changes

- A three-view review (Facet identity, other tools such as Neovim and VS Code, a skeptic who must agree before a finding stays) of six topics: first use, empty and loading states, feedback on a failed key and an unknown ex command, messages, float consistency, and key-to-answer time. It is recorded in this change's `design.md`.
- The evidence: the release binary built with `make build` and driven in a pseudo-terminal as `test/smoke_editor.rb` does, each screen saved with its colors as a rendered cell grid with color runs, one text file per screen under `screens/` in this change's directory, so they are archived with it, plus `screens/timings.txt` with the key-to-answer times for a motion, an insert, and opening each float.
- Each surviving finding, with its reproduction (keys from a named start and the screen file that shows it), appended with `>>` to the end of `docs/backlog.md` for sprint 9's planning.
- At the package step, the planner's queue copied over `docs/queue.md`, restoring `merged-name-guard`'s entry to its original defect without the d180d78de192 sentence, as the brief instructs.

No editor behavior changes, so `skip_specs` is set.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes.

## Impact

- `openspec/changes/ux-pass/`: the review in `design.md` and the screen files under `screens/`.
- `docs/backlog.md`: the surviving findings appended.
- `docs/queue.md`: the planner's queue, at the package step.
- No file under `carat/`, `bin/`, `config/`, `test/`, or `tools/` changes.
- README.md: unchanged, no user-visible change.
- docs/architecture.md: unchanged, no layer, port, or design changes.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.
- docs/codebase-map.md: unchanged, no file under a mapped directory is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a recorded review the user asked for, feeding the UI track's next items.

## Out of scope

- Fixing any finding: each goes to the backlog for sprint 9's planning.
- A real `ruby-lsp`, which the machine lacks: the hover, completion, and starting states are driven by a canned language server, so its times measure carat's side only (`ux-pass-2` in the pool can repeat them with a real server).
- Committing the pseudo-terminal driver or the canned server: the brief allows no change under `tools/` or `test/`, so both lived in a scratch directory; the method is described in `design.md` and every screen file names its keys.

Assumptions recorded here instead of asked: one file per screen is a rendered 24x80 cell grid followed by its color runs per row, which is the "rendered cell grid with color codes" form the brief allows and reads better in review than raw escapes; the skeptic's dropped findings are kept in the review with the reason, not appended to the backlog.
