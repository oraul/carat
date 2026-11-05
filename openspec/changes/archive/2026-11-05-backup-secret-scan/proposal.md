# Proposal

## Why

The periodic security review at eb0f1be found that `tools/run_state.sh backup` publishes every unreviewed commit of a run to `refs/backup/BRANCH` on origin before the security review, behind trailer and content gates that know no secret pattern, and that nothing deletes the ref when a run stops or merges without its push deleting it (Medium, confidence 5). The repository is public, so a committed key published there cannot be taken back. Outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery tooling only, ahead of `run-budgets` by the main session's decision.

## What Changes

- The content gate (and through `tools/rules.sh` the docs lint and the pull request body gate) refuses a private key block, the token shapes of common clouds and platforms (an AWS access key id, GitHub, GitLab, Slack, Google API, Stripe live, npm, and `sk-` keys), and a password, passwd, secret, token, or API key assigned a quoted literal of eight characters or more; it reports the file or commit, never the matched text.
- The content gate scans the added lines of every commit of the range, each against each of its parents, not only the net diff, since a push publishes every commit: a secret added and removed again is refused. It refuses an added `.env` or `.env.*` file. `.gitignore` ignores both.
- `backup` finds the branch's base (its first-parent fork point from `main`), records it as `base`, refuses when that base is not on `main` or `HEAD` does not descend from it, runs the backup gates from that base so they cover every commit the push publishes, and pushes the head and `refs/backup-base/BRANCH` atomically.
- `restore` refuses a backup without a recorded base, one whose base is not on `main`, and one with a commit that does not descend from the base.
- The backup refs are deleted after the branch's push (no longer only when a `backup` record exists, and a failed deletion is reported), when the merger records `merged`, and by the new `abandon CHANGE`, which the user runs for a run that will not resume; a stopped run's report says so.
- Bookkeeping of the plan: the two backlog entries this fixes removed, the six entries of the plan added, two stale figures updated, and the planner's queue committed, which takes the secret-pattern part out of `ci-hardening`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery scripts, one agent, and the workflow, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `tools/rules.sh`, `tools/gates.sh` (`content`), `tools/run_state.sh` (`backup`, `restore`, `push`, `set merged`, new `abandon`), `tools/tools_test.sh`, `.gitignore`.
- `.claude/workflows/deliver-change.js` (a stopped run's note), `.claude/agents/merger.md` (what recording `merged` does).
- `README.md`, `docs/codebase-map.md` area 1, `docs/backlog.md`, `docs/queue.md`.

## Out of scope

- The two other Lows of the same review, a detached check runner outliving a stopped run and sharing `build/`, and the check verdict read from a log a read agent could write: neither is a one-line fix, so both go to `docs/backlog.md`, queued in `check-runner-safety` by the plan.
- `CLAUDE.md`, which has 38 bytes left: `abandon` is documented in the script's usage and the README; the restore wording entry stays for `docs-currency`.
- An unquoted assignment (`token = some_value`), which would refuse ordinary code; only quoted literals and `.env` files are refused.

## Assumptions

- "Abandoned" is the user's decision, not a stopped run, which the backup exists to resume: `abandon CHANGE` is a command for the user that no agent profile admits, and a stopped run's report names it.
- The recorded base lives on origin beside the backup (`refs/backup-base/BRANCH`), since a reclaimed container has lost the run state under the ignored `build/`; the run state's `base` records the same commit. A backup made before this change has no base ref and is refused by `restore`.
- The fork point is the parent of the oldest first-parent commit of the branch not on `main`, so a merge of `origin/main` into the branch keeps the same base.
