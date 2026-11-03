# Design

## Context

The contributor agent ran the whole loop alone: plan, implement, check, review, push, watch CI, merge, report. Every rule lived in its instructions or in `CLAUDE.md`, and none had a check: the build scout found five progress formats under `build/stages/` with no committed writer, and the process scout found the trailer, the forbidden content, the one push, the footer, the security review, and the docs updates enforced by "agent only" or nothing. `make check` and CI ran different stage lists, neither checked the analysis rounds of `bin/carat.rb`, CI diffed only half of the generated config, and `tools/ci_scope.sh` had no test. The contributor's instructions also contradicted themselves (push exactly once, then push after a CI fix) and `CLAUDE.md` (a "Hard rules checklist" that does not exist; a pull request opened without the explicit ask the Git workflow section requires).

## Goals / Non-Goals

Goals:

- A delivery workflow whose phases are fixed in code, each owned by one narrow agent with a checked result, that resumes after a restart.
- Every rule that can be checked is a gate a script runs, not a sentence an agent must remember.
- One stage list for `make check`, the checker, and CI, with each difference recorded.
- The security review cannot be skipped and blocks the merge on a High or Medium finding at confidence 8 or above.
- Fewer tokens: narrow agents with short instructions, low effort for mechanical phases, phases skipped when the run state says they are done at the current commit.

Non-Goals:

- The planner agent, metrics, retrospectives, and periodic reviews (`planner-and-metrics`); golden examples, generators, and the docs size gate (`authoring-kit`).
- Any change to the editor, the tests' behavior, or the generated OpenSpec files.

## Decisions

### The workflow owns the order; agents own one phase each

`.claude/workflows/deliver-change.js` is plain control flow: read the run state, start scouts for the areas without a current pack, call the contributor to propose and apply, then loop over check, quality, security, and benchmark until all pass or three fix rounds are spent, then package, watch CI (a red run goes back to the contributor with the log, and the fix passes check and security again before its push), merge, and report. Every agent call has a JSON schema, so a phase's verdict is data the script branches on, not prose. A phase whose result is recorded at the current commit is skipped on resume, and a fix moves the commit, so every later phase runs again. The workflow cannot touch files, so the first call is a small agent that runs `tools/run_state.sh init` and `show` and returns the state.

### Narrow agents

Seven new files under `.claude/agents/`, each under 40 lines with a `tools:` list of only what the phase needs: the checker (shell and reading; never edits), the quality reviewer (the `code-review` skill on the committed diff plus the repository's rules: the Ruby way, naming, one public `call`, layers, simple code), the security reviewer (the `security-review` skill, inline when it cannot start sub-tasks), the benchmark agent, the CI watcher, the merger, and the reporter. The user delegated the `model:` setting to the main session, which decided: a short tier alias on that frontmatter line is the one exception to the model-name rule, recorded in the hard rules the way the clone address is, and the content gate allows exactly that line in that place. The scout, checker, benchmark, CI watcher, merger, and reporter do mechanical work and use the cheapest alias; the contributor and the two reviewers leave it out, so code and security judgment run on the session's model. Reviewers and the checker report; only the contributor edits.

### One writer for run state and stage logs

`tools/run_state.sh` owns `build/pipeline/<change>.json`, one flat JSON object of string values, one key per line, written through a temporary file and a rename. Keys: `change`, `branch`, `phase.<name>` (the commit it finished at), `stage.<name>` (exit status, seconds, commit, time), `review.<kind>` (result, commit, summary), `pushes`, `ci_fixes`, `pr`, `ci`, `merged`. `stage NAME CMD...` runs one command with its log in `build/stages/<change>/<name>.log` ending in `EXIT n`; `check` runs `make -s stages` in order, skipping a stage already passed at the current commit and stopping at the first failure, so the checker starts it detached and a restart repeats only what did not pass. `push` runs the pre-push gates, refuses a push beyond one plus one per CI fix, pushes with upstream tracking, and records the count.

### Gates are a script

`tools/gates.sh` checks the branch against `origin/main` (`BASE` overrides it):

- `trailer`: every commit's last line is the co-author trailer, which appears once, and no other trailer line exists.
- `content`: added lines of the diff and every commit message hold no URL, email address other than the trailer's, session id, or model name. The `toolchain` target's clone line is the one URL allowed, and a `model:` line naming a tier alias in an agent's frontmatter the one model name allowed. The script's own patterns are written so that they do not match themselves.
- `snapshots`: a changed `.expected` file has its test and `make test-run` passed at the reviewed commit, which compares the snapshot with the Spinel runner byte for byte, so a snapshot written any other way fails it.
- `docs`: a file added, moved, or removed under the five source roots needs the map in the diff; a new or removed make target or agent, command, or workflow file needs `CLAUDE.md`; a change to the default configuration, the compatibility table, make targets, or the process files needs `README.md`.
- `security`: the security review is recorded with a passing result at a commit whose difference to `HEAD` touches only `openspec/` and `docs/backlog.md`.
- `pushes`: at most one push plus one per CI fix.
- `pr-body FILE`: the template's four sections in order, three separators, no comment, angle bracket, empty bullet, footer, URL, email, session id, or model name, and a Testing line naming the security review.

`make gates` runs the first four, which need only git; `pre-push` adds `security` and the stages; `merge` adds `pushes` and `pr-body`. `tools/tools_test.sh` tests each gate in a temporary repository, both its pass and its refusal.

### One stage list

`CHECK_STAGES` in the Makefile: `doctor build dev-build config-current test-build test-run diagnose no-cruby bench-budget tools-test gates`. `make check` depends on it in order and `make stages` prints it for the checker. `dev-build` now checks the analysis budget of `bin/carat.rb` from its own timing report, as `test-build` does for the runner, so both roots are checked without a second analysis. `config-current` regenerates and then fails on any difference to `HEAD` in the config mirror or the plugin registry. CI runs the same targets except: the release `build` only on `main` (pull requests smoke test the development build, ci-speed-2); `diagnose` (a second analysis of every root, about a minute, kept off pull requests to hold them near two minutes; the checker runs it before every push); and `gates` (they need the branch history and the run state, which a pull request's checkout does not have; the checker and the merger run them). The reasons are comments beside `CHECK_STAGES` and in `ci.yml`.

### Conflicts resolved

- One push, plus one per CI fix, enforced by `run_state.sh push`.
- The contributor runs the gates instead of the "Hard rules checklist" that `CLAUDE.md` never had.
- `CLAUDE.md`'s Git workflow and Pull requests sections say that running the contributor or `/deliver` counts as being asked for the pull request and the merge.

### Planning state in the repository

`docs/goals.md` holds the planner's charter in priority order, security first, and `docs/queue.md` the ordered queue with a reason per item and the decisions behind the order, so the plan no longer lives in the main session's notes. `/status` prints the queue; `planner-and-metrics` adds the agent that keeps both.

### No URL outside the exception

`spinel-rev` printed the pin or asked the remote by its full address. It now resolves a branch or tag name through the toolchain checkout's `origin`, which `make toolchain` set from the one allowed address, and fails with a message when there is no checkout.

## Risks / Trade-offs

- `make check` gains `dev-build`, `bench-budget`, `doctor`, `tools-test`, and `gates`: about half a minute more, for checks CI already ran and the analysis budget of `bin/carat.rb`.
- The content gate's model-name pattern is a short list of family names; a new name needs a line in the script.
- The workflow is not exercised by this change, since this change cannot be delivered through it; its first run is the next change.
