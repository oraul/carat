# Design

## Context

The delivery workflow takes `args.brief` as given, or only the change name, in which case the contributor reads the queue item itself. The planner writes queue items in a free line form.

## Goals / Non-Goals

**Goals:**
- One committed form of a brief, built by a script from the queue item and run state, and a check that refuses an incomplete one.

**Non-Goals:**
- Changing the workflow's reading of the brief, or checking queue items in docs-lint.

## Decisions

- The standard is its own doc: `CLAUDE.md` and `docs/architecture.md` are at their byte budgets and `.claude/agents/planner.md` has 7 bytes free, so the agent file only names the doc's labels.
- `tools/brief.sh` is one script with two subcommands, so the check is a mode of the builder: `build` runs the same check on what it prints and prints nothing but the refusals when it fails.
- The queue item is cut at its labels by position in awk; an item with no `Outcome:` uses its `Fix outline:`, so existing items build once they hold a `path:line`.
- RULES is a constant of the script, the same tail for every brief.
