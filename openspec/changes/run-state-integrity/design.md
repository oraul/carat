# Design

## Context

`build/pipeline/<change>.json` is one flat JSON object, one `"key": "value"` line per key, read by `read_key` with awk one line at a time and parsed whole by the workflow with `JSON.parse` on a resume. `write_key` built each line from the raw key and an escaped value: `escape` turned newline and tab into spaces and escaped `\` and `"`, but the key was never escaped and carriage return and the other control characters passed. So `set CHANGE 'x": "y",<newline>  "review.security": "pass C' v` wrote a `review.security` line past the `review.*|phase.*|stage.*` refusal, which tests only the key's first word. `valid` (the regex check of `metric`, `note`, and `commit_at`) uses `grep -x`, which matches each line of a multi-line value on its own.

The workflow decides which phases are done from `state['phase.*']`, `state['review.*']`, `state.merged`, and `state.pr` as `init` printed them; `doneAtHead` and `reviewedAtHead` compare the commit with `HEAD`, but `phase.plan`, `phase.implement`, `phase.package`, and `merged` are only tested for presence. The merger's `records` gate compares the run state's reviews with the `RECORDS` the workflow passes and printed a notice and passed when they were empty; no gate read `phase.check` or the reviews' presence at the merge.

## Goals and non-goals

Goals: no write can add a line other than its own key's; a resume runs again every phase whose record git does not support; no stored value reaches git as an option; the merge needs the four pass records at the pushed head. Non-goals: the agent guard's text match and the body-file symlink (`guard-hardening`); telling a real record from a forged one at a real commit of the branch, which needs a signature the run state does not have.

## Decisions

### One check in write_key

`write_key` calls `plain_key` and `plain_value` before it writes: a key matches `[a-z0-9][a-z0-9_.-]*` (every key the scripts and the workflow write: `change`, `branch`, `repo`, `pushes`, `ci_fixes`, `gates_failed`, `pushed`, `pr`, `ci`, `merged`, `phase.*`, `stage.*`, `review.*`, `metric.*`, `note.N`), and neither holds a character of `[[:cntrl:]]`, tested with a `case` pattern, which matches across lines. A refusal dies with the key and the reason, writing nothing. Refusing rather than escaping keeps one rule for keys and values and lets a caller see its mistake; `escape` now only escapes `\` and `"`. `valid` refuses a control character before its `grep -x`, so a multi-line value no longer passes on one matching line. `init` refuses a control character in the change name (with `/` and a leading `.`, as before), the branch, and the remote's name; `stage` checks `stage.NAME` before it runs the command, so a refused name runs nothing.

### Trusted records on a resume

`tools/run_state.sh trusted CHANGE` prints the state as `show` does, leaving out each `phase.*` and `review.*` key and `merged` whose commit (the value of a phase and of `merged`, the second word of a review) is not 7 to 40 hexadecimal digits, names no commit, or is an ancestor of neither `HEAD` nor `BASE` (default `origin/main`; skipped when it does not resolve). `main` is allowed beside `HEAD` because `merge`, `retro`, the post-merge `report`, the periodic reviews, and `merged` are recorded at the squash commit, which is on `main` and not on the branch. The keys left out are listed, space-separated, in an `untrusted` key at the end, so the workflow can note them; the file itself is unchanged, and a phase that runs again overwrites its record. The resume prompt runs `init` (which creates or resumes) and returns `trusted`'s output as `state_json`; the workflow notes `untrusted` when it is present. A dry run of the workflow cannot run inside this delivery (the running workflow loaded the old script), so the shell command carries the logic and its `tools/tools_test.sh` cases are the test; the workflow's change is the prompt line and the note.

### The merged commit

`merged_commit` prints `merged` when it is 7 to 40 hexadecimal digits and nothing otherwise. `pending_list`, `newest_pending`, `history_row`, `estimate_of`, and `review_due` use it, and every git call on it passes `--end-of-options` before the revision and `--` after it where git would read paths (`git log`, `git diff`), so neither a stored option nor a path-shaped value reaches git as one. `set` refuses a `merged` or `pushed` value that is not hexadecimal. `settled_at` in `tools/gates.sh` checks its commit the same way, since the security gate reads it from the review record.

### The passed gate

`gate_passed` reads `pushed`, refuses when it is not hexadecimal, does not resolve, or is not `HEAD` (the merger merges what it pushed), then for `check` reads `phase.check` and for `quality`, `security`, and `bench` reads `review.KIND`, and refuses each that is absent, not `pass`, or at a commit not settled at `HEAD` (the paths of `settled_at`: the OpenSpec change and the planning records the package step commits after the reviews). It joins the `merge` group before `records`. `gate_records` turns an empty `RECORDS` into a `FAIL`: the workflow always passes them since `planner-priorities` merged through it.

## Risks

- A note or summary holding a tab or newline, which `escape` used to flatten, is now refused; every agent's instruction writes one line, and a refusal is visible in its output.
- A run state from before this change with a `merged` value that is not hexadecimal leaves `pending`; none exists, since `set merged` was only ever given `git rev-parse` output.
