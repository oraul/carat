# Proposal

## Why

The user asked for a review of the architecture and its holes: carat should stay expansible, easy to read, and easy to maintain, and some things have become redundant. `docs/architecture.md` says it describes the target system, yet most of it reads as the present, so a reader cannot tell what exists; several of its statements no longer match the code at main (sections name classes, files, ex commands, and a plugin directory that do not exist, a stale API version, a stale JSON reader size), and nothing records where the code itself lacks an extension point, keeps two mechanisms for one job, or carries dead code.

## What Changes

- Add a Findings section to this change's `design.md`, kept with it in the archive: the review of `docs/architecture.md` and `docs/codebase-map.md` against the code at main (a9812b5), each finding with its location, why it matters, and a fix outline, in three groups: holes, redundancy, and reading and maintenance costs, and a list of the documentation corrected here.
- Append every finding this change leaves open to the end of `docs/backlog.md` with `>>`, for the planner's sprint mode to queue and to deduplicate against the sprint-4 sweep.
- Correct `docs/architecture.md` where it disagrees with the code: mark the pieces not built yet as planned (marks, references, rename, formatting, one-shot tools, the plugin gateway, `git_signs/`, `docs/plugin-protocol.md`), the layer diagram's names, the ex commands registered, the plugin API version (pointing to `docs/plugins.md` for its history instead of repeating it), the size of `Carat::Json`, the Makefile's role, which layers talk to ports, the environment reads, the completion menu, and the roadmap's green condition.
- Correct `docs/codebase-map.md` where it disagrees with the code: the environment reads of area 17, a method listed twice in area 4, and a stray mark in area 1.

No code, test, configuration, or behavior changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes, so `skip_specs` is set.

## Impact

- `openspec/changes/architecture-review/design.md`: the review, under Findings.
- `docs/architecture.md`, `docs/codebase-map.md`: corrections only.
- `docs/backlog.md`: appended with `>>`, never read.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.
- README.md: unchanged, no command, option, or user-visible behavior changes.

Outside the roadmap of `docs/architecture.md` section 12: a review the user asked for, the last item of sprint 5.

## Out of scope

- Any code fix, including removing the dead code the report names: the brief allows documentation corrections only.
- Reading `docs/backlog.md` to deduplicate: the planner's sprint mode does it.
- Rewriting the architecture beyond its disagreements with the code, such as adding sections for the parts it omits (floats, the completion menu): the report records them as findings instead.
- Reordering the queue.

Assumptions recorded here instead of asked: one pull request suffices (one report and documentation corrections, no code), so no split; a finding this change corrects in the documentation is listed in the report but not appended to the backlog, since it is closed; the report is the Findings section of the change's `design.md`, so the archive keeps it with the decisions behind it.
