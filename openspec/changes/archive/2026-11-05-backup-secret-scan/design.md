# Design

## Context

See proposal.md, Why. The scout pack `tmp/scout/build-and-ci-eb0f1be-20261105T075219Z.md` holds the line references; they hold at eb0f1be. `tools/rules.sh` defines the forbidden patterns and `scan`, which the content gate, the pull request body gate, and the docs lint share. `gate_content` scans the added lines of the net diff `BASE...HEAD` and every commit message of `BASE..HEAD`. `backup_branch` runs `gates.sh backup` (trailer and content) with `BASE` from the environment, then pushes `HEAD:refs/backup/BRANCH`; `push_branch` deletes that ref, silently, only when a `backup` record exists; `restore_branch` creates the branch from the ref with no check of its history. The run state lies under the ignored `build/`, so a reclaimed container has none.

## Goals / Non-Goals

**Goals:** no commit reaches origin, as a backup or a branch, with a key, a platform token, a literal password, or an added `.env` file in any of its commits; the backup's refs leave origin when the run merges or is abandoned; a restore takes only a history rooted on `main` at the run's recorded base.

**Non-Goals:** catching every secret shape (entropy scanning, unquoted assignments); keeping the backup off origin; the check runner's Lows.

## Decisions

### The secret patterns live in rules.sh

`KEY_RE` (a `BEGIN ... PRIVATE KEY` block line, with or without a key type, and the PGP `BLOCK` form) and `TOKEN_RE` (the token shapes, each with a fixed prefix and a minimum length, preceded by a non-alphanumeric character or the line start) are matched case-sensitively; `ASSIGN_RE` (a name ending in password, passwd, secret, token, api_key, or apikey, then `=`, `:`, or `=>`, then a quoted literal of eight or more characters without space or quote) case-insensitively. `scan` reports such a line by its label only (the path, `commit H`, or `pr-body`), so a gate log, which CI may print, never repeats the secret. Sharing `scan` makes the docs lint and the pull request body gate refuse them too, which they should. The patterns are written so that `rules.sh` does not match them, as the others are; no tracked file and none of the last 500 commit messages match them at eb0f1be.

Rejected: a separate `secrets` gate in the `backup` group only. A secret in a pushed branch is as public as in a backup ref.

### Every commit, not the net diff

`gate_content` reads `git log -p -m -U0 --no-renames BASE..HEAD`: the added lines of every commit against each of its parents, labelled by path, deduplicated. A merge's diff against its branch parent repeats `main`'s already-gated changes, which is harmless; its diff against `main` shows the branch's side and any resolution. This replaces the net diff, which those diffs contain. Added files come from the same range with `--diff-filter=A --name-only`: a path whose last segment is `.env` or starts with `.env.` is refused (`.envrc` is not). `.gitignore` gains `.env` and `.env.*`.

### The backup's base

`branch_base` is the parent of the oldest first-parent commit of `HEAD` not reachable from `BASE` (`origin/main`), or `HEAD` itself when there is none: the commit the branch forked from, unchanged by a later merge of `origin/main` (the branch stays the first parent). `backup` writes it as `base`, refuses unless it is an ancestor of `BASE` and of `HEAD`, runs `gates.sh backup` with `BASE` set to it, so the gates cover every commit between `main`'s history and the head (a superset of what the push publishes, whatever `BASE` the caller set), and pushes `HEAD:refs/backup/BRANCH` and `BASE_COMMIT:refs/backup-base/BRANCH` with `--atomic`, both without force. The base ref publishes no new object: its commit is on `main`.

`restore BRANCH` fetches both refs. It refuses with exit 1 and the reason when the base ref is missing (a backup older than this change), when the base is not an ancestor of `BASE`, and when `git rev-list --ancestry-path BASE..HEAD` counts fewer commits than `git rev-list BASE..HEAD`: some commit does not descend from the base (an unrelated root, or history merged from elsewhere). `main`'s commits merged into the branch descend from the base, so they pass.

Rejected: reading the base from the run state in `restore`. The restore runs where the run state is gone; the ref on origin is the record a reclaimed container has. Rejected: recomputing the merge base at each backup, which moves when `origin/main` is merged and would make the older branch commits fail the restore.

### Deleting the refs

`drop_backup BRANCH` lists both refs with `git ls-remote`, deletes those present in one `git push --delete`, drops the `backup` record, and reports what it deleted or why it could not. `push` calls it after the branch is pushed whether or not a `backup` record exists (a resumed run's backup was made by a run state that is gone), reporting a failure without failing the push. `set CHANGE merged SHA`, which only the merger runs after the squash merge, calls it too, so a deletion `push` could not do is retried at the merge with no new guard form. `abandon CHANGE` calls it for a run that will not resume and exits 1 when the deletion failed; no agent profile admits it (the guard's default refusal), so only the user abandons a run. The workflow notes the command when a run stops, beside the report.

Rejected: deleting the refs when a run stops. A stopped run is resumed from them; the run state cannot tell a stop the user will resume from one they gave up.

## Risks / Trade-offs

- [A secret shape outside the list, or an unquoted assignment, passes] → the list covers the common platforms; the security review still reads the diff before the push, and `docs/backlog.md` names the limit.
- [A false positive in ordinary text, such as a long `sk-` kebab word] → the prefix needs a non-alphanumeric character before it; an author renames the word. No tracked file matches today.
- [`set merged` now talks to origin] → only when a ref exists; the listing is one `ls-remote`, and a failure is reported, not fatal.
- [A backup from before this change cannot be restored] → it holds at most the commits of one run; the resume creates the branch from `origin/main` and the run starts its phases again, as it does without a backup.
