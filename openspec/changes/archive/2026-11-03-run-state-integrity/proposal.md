# Proposal

## Why

The run state is what the delivery workflow and the merge gates trust, and it can be forged: the periodic security review at df5a203 found a Medium (8) at `tools/run_state.sh` `set`, where a key holding a newline writes whole `review.*` and `phase.*` lines that the prefix refusal never sees, and a read-profile agent may run `set`, `metric`, and `note`. Behind it stand three weaker defenses: a resumed workflow trusts any `phase.*` and `review.*` record of the file (Low, `.claude/workflows/deliver-change.js` resume), a stored `merged` value reaches `git log` unchecked, so `--output=<path>` would overwrite a file (Low (5), `newest_pending` and `history_row`), and the merge's records gate passes when it is given no records (`docs/backlog.md`, left by `agent-authority`). The security finding goes to the front of the queue (tier T0).

## What Changes

- Every write of `tools/run_state.sh` refuses a key that is not lowercase letters, digits, `_`, `.`, and `-`, and a key or value holding a newline, carriage return, tab, or other control character, through one check in `write_key`; `valid` refuses a control character before its line-based match, `init` refuses one in the change name, branch, and remote, and `stage` checks its name before it runs the command.
- A new `tools/run_state.sh trusted CHANGE` prints the run state without every `phase.*` and `review.*` record (and `merged`) whose commit is not hexadecimal, names no commit, or is an ancestor of neither `HEAD` nor `BASE` (`origin/main`, where the squash commits of the merged phases are), and names what it left out in an `untrusted` key. The workflow's resume returns that output instead of `init`'s, so a phase with an untrusted record runs again, and notes the keys left out.
- `merged` is used only when it is 7 to 40 hexadecimal digits: `set` refuses another `merged` or `pushed` value, `pending` skips such a state, `review-due` refuses it, and every `git log`, `git show`, and `git diff` of it passes it after `--end-of-options`, followed by `--` where git reads paths.
- A new gate `passed` in the `merge` group refuses a merge unless the run state records `phase.check` and a `pass` of `review.quality`, `review.security`, and `review.bench`, each at a commit settled at the pushed head (`pushed`, which must be `HEAD`); the `records` gate refuses an empty `RECORDS`.
- `tools/tools_test.sh` cases: forging `review.security` and `phase.merge` through `set` (key and value), `metric` (name and value), `note` (kind and text), `review` (summary), `stage` (name), and `init` (branch), each refused with no forged line in the file; `trusted` keeping consistent records and leaving out forged ones; an option-shaped `merged` refused by `set` and harmless to `pending`, `review-due`, `budget`, `bench`, and `history`; `passed` refusing a merge given no records, a blocked review, a record before a code change, and a head that is not the pushed one, and passing the four records; the `merge` group refusing given no records.
- Docs: `docs/codebase-map.md` area 1 (`trusted`, `passed`), `README.md` (the merge gate and the resume), `docs/backlog.md` (two entries removed, three added from the plan, stale line references replaced by names).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This changes the delivery pipeline's scripts and workflow, not the editor's behavior; `skip_specs` is set.

## Impact

- Changed: `tools/run_state.sh`, `tools/gates.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `docs/codebase-map.md`, `README.md`, `docs/backlog.md`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary and its metrics are unchanged.

Outside the roadmap of `docs/architecture.md` section 12: it hardens the delivery pipeline, goal 1 (security first) and goal 13 of `docs/goals.md`.

Out of scope: the guard's text match, the body-file symlink, and `REVIEW_AREAS` (`guard-hardening`); the workflow's records and waits (`workflow-records`, next in the queue); a run state forged by someone who can also write commits on the branch, which no ancestry check can tell from a real record.

Assumptions recorded instead of asked:

- Control characters are refused, not escaped: the acceptance asks to see each forgery refused, and every caller of `set`, `metric`, and `note` writes one line. Tab counts as a control character; `escape` turned it into a space before.
- `git log` reads arguments after `--` as paths, so a revision is passed after `--end-of-options`, which is what "after --" asks: no value reaches git as an option.
- "Exists on the branch and is an ancestor of HEAD" is checked as an ancestor of `HEAD`, or of `origin/main` for the records written at the squash commit (`merge`, `retro`, `report`, the periodic reviews, `merged`), which is on `main` and never on the branch.
- "At the pushed head" means the record's commit is settled at `pushed` as the security gate already reads it: only `openspec/`, `docs/backlog.md`, `docs/queue.md`, `docs/goals.md`, and `docs/metrics.tsv` changed since, which the package step commits after the reviews.
- The check's pass record is `phase.check`, which `tools/run_state.sh check` writes when every stage passed; quality, security, and bench are their `review.*` records.
