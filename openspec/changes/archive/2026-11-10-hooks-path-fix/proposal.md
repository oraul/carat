# Proposal

## Why

The periodic security review after #100 found (Medium, confidence 8) that `make hooks` sets `core.hooksPath` to the tracked `.githooks` of the main worktree, so checking out any branch or fork pull request that commits an executable `.githooks/post-checkout`, `post-merge`, or `reference-transaction` runs its code at once in every clone where `make toolchain` or `make hooks` ran. The origin gate and the agent guard look only before a command runs, so they cannot stop a hook the command itself writes and then runs. Two Lows share the same guard: the pull request scan runs the pull request's own scanner, so a pull request that weakens `tools/scan_text.sh` passes its own check (5), and the hooks run the scanner by a relative path, the scanner of whichever worktree commits (3).

## What Changes

- Change `make hooks` to copy `commit-msg` and `pre-commit` from `.githooks` at the current commit (`git cat-file blob HEAD:...`), with the scanner `tools/scan_text.sh` and `tools/rules.sh` beside them, into the hooks directory under the common git directory, which no checkout writes, and to remove any `core.hooksPath`, so the one an earlier `make hooks` set stops pointing into the work tree. `make toolchain` still runs it.
- Change `.githooks/commit-msg` and `.githooks/pre-commit` to run the scanner installed beside them, never the work tree's, and to report a scanner status other than 0 or 1 as a scanner error.
- Change the origin gate of `tools/gates.sh` and `tools/agent_guard.sh` to allow no `core.hooksPath` at all, a work-tree path included (the `RISKY_CONFIG` refusal without its exemption, its message naming `make hooks`), and to allow in the hooks directory only the samples and the installed files `INSTALLED_HOOKS_RE` of `tools/rules.sh` names (copied in the guard, kept equal by a tools case). The check of the main worktree's `.githooks`, which git no longer runs, and its derivation of the main worktree from the parent of the common git directory go away.
- Change `.github/workflows/scan.yml` to check out the base commit to its own path with `persist-credentials: false` and run that checkout's `tools/pr_scan.sh` (and so its scanner and rules) in the head's checkout.
- Add tools cases: a checked-out branch's planted `post-checkout`, `post-merge`, and `reference-transaction` hooks do not run; the commit hooks run the installed scanner after the work tree's is replaced; `make hooks` removes an earlier `core.hooksPath`; the gate and the guard refuse the absolute work-tree `.githooks` and allow the installed hooks; the scan workflow runs the base's scanner.
- Remove the two backlog entries this fixes: the relative scanner path and the main worktree taken as the parent of the common git directory.

Out of scope: recording the periodic review's results in the run state (the workflow records reviews; the contributor never does), the periodic findings' other items (the planner queues them), the archived `url-email-guard` text, which describes history, and a pull request that edits `scan.yml` itself, which the `pull_request` event runs from the head (only `pull_request_target` would run the base's definition, at the cost of the base's secrets; review of the workflow diff covers it).

Roadmap: outside the roadmap of `docs/architecture.md` section 12; a blocking security fix to the delivery tooling, which goes to the front of the queue.

Assumptions:

- The hooks are copied from the current commit, not the work tree, so an uncommitted edit of `.githooks` or the scanner never installs; a clone reruns `make hooks` to pick up a later change of them.
- The contributor does not run `make hooks` in this run: the old target would set the very `core.hooksPath` the change removes, and the new one would install files the guard on `origin/main` refuses until this change merges. A clone where the old target ran is refused by the guard after the merge until `make hooks` runs once by hand, which the refusal says.
- The installed scanner is the two files the hooks need, `scan_text.sh` and `rules.sh`; git runs a hook only by an event's name, so neither is ever run as a hook.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `Makefile` (`hooks`), `.githooks/commit-msg`, `.githooks/pre-commit`, `tools/rules.sh`, `tools/gates.sh`, `tools/agent_guard.sh`, `tools/tools_test.sh`, `.github/workflows/scan.yml`.
- CLAUDE.md: changed, the `hooks` target's line in Commands.
- README.md: changed, the `make hooks` row.
- docs/architecture.md: unchanged, section 10 names the gates by script and does not mention the hooks.
- `docs/codebase-map.md` area 1 and `docs/backlog.md`.
