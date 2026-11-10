# Design

## Context

`tools/rules.sh` held the patterns and a `scan` function over "LABEL<TAB>TEXT" lines, called by the content gate (each commit's `+` lines, read with an awk that took any `+++ ` line for a path header), the pr-body gate (the body file), and the docs lint. Hits printed whole lines. Nothing ran at commit time, and nothing read the pull request on GitHub. `core.hooksPath` is in `RISKY_CONFIG`, so the origin gate and the agent guard refuse any value, and both looked for planted hooks with `git rev-parse --git-path hooks`, which follows `core.hooksPath`.

## Goals / Non-Goals

Goals: one scanner every check runs; hits named precisely and without repeating a secret; the scan at each commit, at the push, at the merge, and on every change of the pull request's text. Non-goals: refusing binary files, preventing the footer (it comes from the pull request tool outside the repository).

## Decisions

### One scanner, the patterns in rules.sh

`tools/scan_text.sh` sources `rules.sh` for the patterns and turns its input into rows (where, line, path, text) with one awk program: in text mode a row per line; in `--diff` mode a row per added line at its new line number, a `+++ ` line read as a header only between `diff --git` and the first `@@`, a `Binary files` or `GIT binary patch` line noted. It then writes one text per check (the clone line blanked for the URL check, an agent's tier alias for the model check, a URL's user and password stripped for the address check) and runs `grep -n -o`, mapping each line number back to its label. Alternative considered: matching in awk; rejected, since mawk's interval expressions vary and the patterns use them.

A URL hit prints the URL up to whitespace, a quote, a bracket, or a backtick, through a sed that masks `KEY_RE` and `TOKEN_RE` shapes and a URL's user part; `ASSIGN_RE` needs a quote, which a printed hit cannot hold. A secret prints by label only, as before.

### A URL split where a line wraps

For two consecutive lines, the last word of the first joined to the first word of the second (after a comment or bullet marker) is checked when it is a URL and neither word is; it is reported at the first line. Prose ending a sentence at a line end does not form a host and path, which a case checks.

### The hooks and core.hooksPath

`make hooks` sets `core.hooksPath` to the absolute path of `.githooks`, the tracked directory, in the main worktree (the parent of `--git-common-dir`), and `make toolchain` runs it. A relative value would be read from the top of whichever worktree git runs in, so a hook planted in a linked worktree `tmp/.NAME` would run on a read agent's checkout there; the absolute value makes every worktree use the one checked directory. Hooks there run branch code at a commit, which the contributor already runs through the checks; a hook that runs on a checkout, a merge, or a fetch would run a branch's code for whoever switches to it, so only `commit-msg` and `pre-commit` may be there: the origin gate and the guard refuse any other file in the directory, and the content gate refuses a commit adding one. `RISKY_CONFIG` keeps `core.hookspath`; the gate and the guard drop it only when its one value is exactly that absolute path, and check that directory, and look for planted hooks in `--git-common-dir`'s `hooks`, not the configured path. The guard holds copies of `HOOKS_PATH` and `HOOK_FILES_RE`, kept equal by a case. The workflow's own git calls keep `-c core.hooksPath=/dev/null`. Until this merges, main's guard refuses a repository with the setting, so this change's own run does not run `make hooks` in the delivery clone; its cases use temporary repositories.

### The pull request scan

`.github/workflows/scan.yml` runs on `pull_request` (never `pull_request_target`) with `contents: read` only and the checkout's credentials not persisted. The title, body, and the two commits reach `tools/pr_scan.sh` through `env:`; the run line names no expression, so no text of theirs becomes script. The script checks both commits are hexadecimal and exist before git reads them, strips the body's carriage returns, and scans the title, the body, each commit message, and `git log -p -m` of the range. A run on the edited event follows each title or body edit.

## Risks / Trade-offs

- A hook edited on a branch runs at that branch's next commit: accepted, the same trust as the checks the contributor runs.
- The top-level-domain list misses a rarer domain without a scheme: accepted, a scheme or a www host still matches.
- A binary file is noted, not refused; the refusal stays with `content-gate-gaps`.
