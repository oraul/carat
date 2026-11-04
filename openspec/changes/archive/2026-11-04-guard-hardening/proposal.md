# Proposal

## Why

The agent guard and the periodic review's trigger each have a known gap, recorded as Low security findings and a periodic quality advisory (`docs/queue.md` item 1, T3). The guard reads a command's text as written, so under the read profile `git 'push' origin x`, `"git" push`, and `"gh" pr merge` pass its git and gh rules although the shell runs exactly the refused command (security review of `agent-authority`, Low (7)). The contributor's and the merger's pull request body file can be made a link to `build/pipeline/CHANGE.json`, after which a write to the body file overwrites the run state (security review of `workflow-trim`, Low (6)). `REVIEW_AREAS` names neither the composition root `bin/carat.rb`, nor the shell tools, nor the agents and workflows under `.claude/`, nor CI (periodic security, Low (3)), while its config loading area matches every edit of `config/default.caratrc` and its mirror, so the key-binding-only `window-ctrl-keys` made the periodic review due although no loader changed (periodic quality advisory at df5a203).

Folded in, from the same delivery tooling: each quality review replaces the workflow's advisory list, so the advisories of an earlier round (a fix-diff review, or a review after a CI fix) never reach `docs/backlog.md` (advisory lost by `workflow-records`, pull request 44). Three small advisories of that pull request are fixed beside it: `tools/ci_wait.sh` ignores a failing `sleep` and repeats its refusal text, the `tools-test` help omits `tools/ci_wait.sh`, and the header of `tools/tools_test.sh` wraps unevenly.

## What Changes

- `tools/agent_guard.sh`: the text of a Bash command is matched with its quotes and backslashes removed, as the shell joins them into one word, so a quoted or escaped `git` write, `gh` command, run state record, environment override, or run state path is refused like the plain one.
- `tools/agent_guard.sh`: the contributor and merger profiles refuse a command that links, moves, or copies onto the body file, and any command or file edit naming a body file that is a link; a file edit is judged by its real path as well (existing directories and a final link resolved), and a path with a parent step is refused, so a linked directory cannot reach the run state's directory and a read or merger agent cannot write outside its directory through a link. `tools/gates.sh pr-body` refuses a body file that is a link.
- `tools/run_state.sh`: `REVIEW_AREAS` gains `entry point` (`bin/carat.rb`) and `tooling and CI` (`tools/`, `.claude/`, `.github/workflows/`), and the config loading area gains the generator `bin/carat-gen-config.rb`; `review-due` leaves out `config/default.caratrc` and its mirror `carat/domain/default_config.rb` when the change's edit of `config/default.caratrc` adds or removes only key bindings, comments, and blank lines.
- `.claude/workflows/deliver-change.js`: the advisories of every quality review of the run are merged in order without duplicates, seeded on a resume from every `quality-advisory` note; the package step gets them with the security findings, and the push of a CI fix gets the findings that arrived after the package step, which the contributor puts into `docs/backlog.md` before pushing (`.claude/agents/contributor.md`, push mode).
- `tools/ci_wait.sh`: a failing `sleep` exits 1 with a message; the range refusal has one text. `Makefile`: the `tools-test` help names every tool `tools/tools_test.sh` tests. `tools/tools_test.sh`: the header rewrapped.
- Docs: the review areas named in `README.md`, `docs/goals.md`, `.claude/commands/review.md`, and the periodic review workflow's description; the map's area 1 lines for the changed tools; `docs/backlog.md` loses the three entries this change fixes and gains the advisories of pull request 44 left for later.
- Every behavior has a `tools/tools_test.sh` case.

## Capabilities

### New Capabilities

None. The change alters only the delivery tooling, which no spec under `openspec/specs/` describes; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

Outside the roadmap of `docs/architecture.md` section 12: delivery tooling under goal 1 (security first) and goal 13 (the pipeline never forgets a finding). No file under `carat/`, `bin/`, `test/`, or `config/` changes, so the editor and its benchmarks are unaffected.

Out of scope: a command hidden behind a variable, a glob, `$'...'` escapes, or a script file stays outside a text match, as the guard's header says; the records gate and branch protection stand behind it. The `/status` phase display during the CI wait and the merger's reliance on a foreground sleep stay in `docs/backlog.md` for `workflow-cost`, where the planner placed them. Restoring the non-blocking security findings on a resume is not part of this change.

## Assumptions

- "Keymap-only" means the changed lines of `config/default.caratrc` are `keymap.*` lines, comments, or blank lines; any other changed line there, the mirror changed alone, or the generator changed still makes the review due by area.
- `bin/carat.rb` gets an area of its own, `entry point`, rather than joining process spawning, so the due line names what changed.
- An advisory found after the package step reaches `docs/backlog.md` through the CI fix's push, the only later commit of the branch; a backlog-only commit keeps every review settled (`settled_at` in `tools/gates.sh`).
