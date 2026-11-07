# Design

## Context

The pipeline's trust rests on three things branch code can reach: the local ref `refs/remotes/origin/main` and `.git/config` (the merge gates' worktree, the hooks' `git show origin/main:tools/agent_guard.sh`), the run state file (the resume's `trusted` output, which keeps any record at a supported commit), and the merger's instructions (the merge tool has no hook). The checker runs `make` on the branch outside the guard, so any of them may have been rewritten before the reviews and the merge.

## Goals / Non-Goals

Goals: detect a rewritten `origin/main` or a configuration key that runs a command before a gate or the guard relies on them; a review pass read from a file never skips a review; the merge tool refuses a merge the merge gates did not pass at that head.

Non-goals: a clone whose `.git` the stages cannot write; signing run-state records; the backup's gates.

## Decisions

### One list of risky configuration keys

`RISKY_CONFIG` in `tools/rules.sh`, matched case-insensitively against `git config --local --name-only --list`: keys that run a command (`core.fsmonitor`, `core.hooksPath`, `core.sshCommand`, `core.gitProxy`, `core.pager`, `core.editor`, `core.askPass`, `core.alternateRefsCommand`, `diff.external`, `diff.*.textconv`, `diff.*.command`, `filter.*`, `merge.*.driver`, `sequence.editor`, `credential.*`, `gpg.*`, `uploadpack.*`), redirect origin or the files git reads (`url.*.insteadOf`, `url.*.pushInsteadOf`, `remote.origin.pushurl`, `remote.origin.uploadpack`, `remote.origin.receivepack`, `remote.origin.proxy`, `remote.origin.vcs`, `http.*`, `protocol.*`, `include.*`, `includeIf.*`, `core.worktree`, `extensions.worktreeConfig`). The guard is read from main as a string and cannot source `rules.sh`, so it holds a copy; a `tools/tools_test.sh` case keeps the two equal. Alternative considered: a hash of `.git/config` recorded at the start; rejected, since the record would sit where branch code writes.

### The origin gate

For any base, the configuration list. For a base `origin/NAME` (the default): `remote.origin.fetch` exactly `+refs/heads/*:refs/remotes/origin/*`, so a fetch restores a rewritten ref; an origin URL that is not a local repository (a path, `file:`, or `ext::`), since a fake bare repository would answer `ls-remote` with the fake commit; and `git ls-remote origin refs/heads/NAME` equal to the base's commit, with "fetch, or the ref was rewritten" as the remedy. It runs first in `pre-push` and `merge`; the green line fetches before it adds the worktree, so a stale ref is never the reason. A local base (the tests' `BASE=main`) checks the configuration only.

### The guard's configuration check

Before it judges a call, the guard of every profile lists the project's configuration (`git -C "$CLAUDE_PROJECT_DIR"`) and refuses on a risky key; a directory that is not a repository lists nothing. One local `git config` per call; no network.

### Records this start made

`ran` holds the `phase.*` and `review.*` values `phaseDone` and `reviewed` set in this start. `doneAtHead` and `reviewedAtHead` read `ran` through the pure `passedAt(records, key, head)`; `mergeRecords(ran)` builds the merge gates' `RECORDS`. `state` still carries the file's records for the notes, the quality scope, and the figures. A resume past the push runs `verify()` before the merger when the check, a review, or the benchmark has no pass of this start at the head; a fix there moves the head off the pushed sha, which stops the run before the merger. Alternative considered: authenticating records with a key only the workflow holds; the workflow has no secret store, and the review is cheaper than the risk.

### The merge-tool hook

`gates.sh merge` runs `run_state.sh gated CHANGE clear` first and `gated CHANGE pass` (the full HEAD) when every gate passed; `push` writes `gated` as `none`; `set` refuses `gated`, and no guard profile runs `gated`. The merger's hook adds a matcher for `mcp__github__merge_pull_request`; main's guard refuses that tool for any profile but the merger, and for the merger unless `merge_method` is `squash`, `sha` is 40 hexadecimal digits that a run state under `build/pipeline/` holds as both `pushed` and `gated`, and `origin/main` equals origin's `main`. A push after a check clears any marker branch code planted, and between the push and the merge only main's gates run.

Bootstrap: this change's merge runs main's older guard, which refuses any tool it does not judge. The merge hook line runs main's guard for the merge tool only when that guard's text names `mcp__github__merge_pull_request`, and allows the call otherwise; a rewritten `origin/main` already controls the guard either way. The backlog entry removes the clause after this merge.

## Risks / Trade-offs

- A resume reruns the reviews when this start holds no record of a kind: more tokens on a resume, with no fix round, since a fix commit could not be pushed; a blocking finding there stops the run. A start that ran them keeps its records past the package step's records-only commits, which the merge gates' settled_at allows.
- The gates, the guard, and the green line's fetch and worktree add read no global or system configuration and run no hook, since branch code run by the checks can write `~/.gitconfig` and `.git/hooks`; a hook other than a sample refuses every call and fails the origin gate. The stages still run with a writable `.git` and home directory; running them in a clone they cannot write is the longer-term fix, in the backlog entry on the guard read from `origin/main`.
- `pre-push` now needs the network and a current `origin/main`; the contributor fetches before the push.
- A marker written by `run_state.sh gated` outside the merge gates is still possible for code that runs between the push and the merge; none of the branch's runs there.
