# Design

## Context

`run_state.sh bench` compares the check's measurement with main's recorded figures (the newest merged change without a history row, else the last history row); any difference starts the benchmark agent, which builds main in `tmp/.base` and measures it every run. The checker start always runs `check`, then `spent` and `bench`, though a contributor's pass at the head leaves every stage a pass record the check only skips.

## Goals / Non-Goals

**Goals:**
- Measure main once per merge, compare every later run with the stored figures.
- Start no checker when its work is already done at the head.

**Non-Goals:**
- The pull request text check and the prompt prefix order (the planned change cache-reuse-b); the gates, which stay as they are.

## Decisions

- The stored figures are one file keyed by the full commit of main in its first line; a figure file for another commit is stale and ignored, so a merge invalidates it without any bookkeeping. `base-figures save` measures `tmp/.base` itself with that worktree's own tracked `tools/metrics.sh`, only when the worktree is at main's commit and its tracked files are unchanged, so the file holds neither figures of another tree nor a measurement anyone wrote; the figures are never copied from a file.
- With stored figures `bench` decides on `make metrics-compare`'s own verdict (more allocations or rounds fail), since those are measured at main itself; a difference that is not a regression needs no agent. Without them the old comparison with recorded figures stands, so the first run after a merge behaves as before and stores the figures for the rest.
- The carry is a command, not workflow logic: the workflow has no shell, only the runner start that runs one command. `carried` reads the stage list as text (the Makefile's FAST_STAGES line at HEAD, as `check_stages` and the gates read it), never by running make in the working tree, and refuses while an untracked makefile stands; it mirrors the first decision of `check_stages` per stage (a pass record at HEAD, backed by the workflow's claim; `diagnose` only scoped out and still out of scope), so a head the check would run anything for is never carried. Its output carries the spent line and the benchmark comparison, so the workflow fills the same fields the checker's result would, and the rest of the round (verdict, budget note, bench phase) is unchanged.
- The carry is tried only on the contributor's claim at the head (`claimedPass`) with no settle or moved line, the only case where every stage record at the head can exist and be trusted; the cost of a refused attempt is one runner start.
- The release-level timing of the benchmark agent needs the base build; it is kept for a brief that states a time target, as its blocking rule already said.
