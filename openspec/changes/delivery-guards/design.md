# Design

## Context

Findings are appended by the contributor and folded into the backlog by `groom`; nothing stops a branch from deleting an entry. The pull request body is written by the contributor and checked for shape and forbidden text only.

## Decisions

- The `findings` gate lists the `### ` headings of `docs/findings/` with `git grep` at the base, at every commit of `base..HEAD`, and at HEAD, and fails on any heading of an earlier tree absent at HEAD, whichever file it was in. A heading edited under the same text, or prose edited beneath it, passes. A change named `sprint-N-records` passes: `groom` is the only remover. Rejected: comparing only the net diff against the base, which misses an entry added and dropped within the branch (the dropped `LineNrFifth` entry).
- The gate joins `merge` as well as `static`, so main's copy of the gates run by the merger checks it.
- The text review reuses the quality reviewer's schema and the session model, with its own call cap `prtext`. Its blocking findings are the quoted claims; the rewrite is the existing `body` mode, since the package start has already pushed; the task text says why, as the contributor file is at its size budget. At most one rewrite and two reviews a run.

## Risks / Trade-offs

An LLM review can miss a claim; it narrows the defect, the gate for findings is mechanical. A review that returns no result is a note, not a stop, to avoid holding a merge on an unavailable reviewer.
