# Design

## Context

The main session is reset during a hold, so its notes are lost. What a later session needs to resume is the queue order, the user's standing decisions, and the open findings. `tools/docs_lint.sh` holds `docs/queue.md` to 17,369 bytes and checks that every item carries a tier and a size; `docs/backlog.md` has no budget but is read by every planner and reviewer.

## Goals / Non-Goals

Goals: the user's order and decisions in tracked files, the hold and its resume stated where a new session looks first, no finding lost. Non-goals: changing a rule in `docs/goals.md`, a budget, or code; compacting the backlog.

## Decisions

- Where each decision goes: the three that are rules (UI then code intelligence, one pipeline change per three features with T0 first, the security reviewer's tier and effort) are already in `docs/goals.md`, so the queue's Decisions section only points to them; the rest (indent guides in the core, the session-link footer, the parked items) are decisions about items, so they stay in the queue's Decisions section, with the footer and `image-viewer` also in their backlog entries. Alternative: copying the rules into the queue; rejected, since two copies drift and the queue has 56 bytes of room.
- `finder-extras` split: the planner split it into grep, then pickers and highlighting, because the whole is large outside the roadmap, as `file-finder` was (2,247,223 total tokens). The user's order is kept around it.
- The resume account: the queue's header says the project holds and that `/status`, then `/deliver` for item 1 resumes it; `README.md` says the same in its paragraph on where the plan lives, which a new session reads. `CLAUDE.md` already points to the queue, so it is not touched.
- Folding the periodic findings: an entry that already names a finding's location gets a "Raised again at ce6abdb" note on its Where line, with any new line numbers and the fix the review proposed, instead of a second entry; only the parts no entry names become new entries. This keeps one entry per finding, which `backlog-compaction` relies on. The stale UI group entry is replaced rather than noted, since its count is wrong.

## Risks / Trade-offs

- The queue is copied at 17,313 bytes, so the next planner must cut text to add an item; `backlog-compaction` and `docs-index` are queued.
- The backlog grows by 8,806 bytes (373,817 to 382,623), against the 12,214 bytes of the planner's entries added whole; it is above the 5 KB per merge `backlog-compaction` targets, a target that starts with that item.
