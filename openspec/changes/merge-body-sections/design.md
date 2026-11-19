# Design

## Context

The merger (`.claude/agents/merger.md`) squash-merges with `mcp__github__merge_pull_request`, passing `commit_title` and `commit_message`; GitHub writes the message as the squash commit's body. Until now the merger made the message itself: it listed the archive with `git ls-tree`, printed `pr.md` with `git show ... | tail -n +3`, and appended a blank line and the trailer. Twice in three merges it passed a one-paragraph summary instead. The guard's `squash_message` compares the message with `pr.md`, but it never judged those calls, and its head check reads `sha` where the tool's parameter is `expectedHeadSha`.

## Decisions

- Build the message with a script, not the agent. `open_pr.sh message CHANGE SHA` prints the exact text the guard admits, so the merger copies one output into one parameter. `open_pr.sh` already owns `pr.md` (write, read); the message is its third reader, beside the workflow's `read`.
- The archive directory is picked as the guard picks it: the archive's own entries at SHA (`git ls-tree --name-only SHA -- openspec/changes/archive/`) named `DATE-CHANGE`, holding a `pr.md` blob, exactly one. Reading the tree at SHA, not the worktree, keeps the message to the pushed head the merge names.
- Trailing blank lines of the body are dropped before the blank line and the trailer, as the guard ignores them on both sides; every other byte, the `## ` headings and `---` dividers included, is kept, with `LC_ALL=C` so no byte is reinterpreted.
- The guard reads `expectedHeadSha` only. A call naming `sha` gives GitHub no expected head, so GitHub would merge whatever head the branch holds; refusing it is the guard's purpose. The merger file names the parameter.
- The guard cannot source `open_pr.sh` (the hook runs main's guard alone from a fetched blob), so the comparison stays in `squash_message`; a test runs the builder's output through the guard so the two cannot drift.

## Risks

- The merger still copies the output into the tool call; a summary remains possible while the hooks do not judge the call. The post-merge check (merge-body-check) is the queued catch, and the finding on the hooks is recorded.
