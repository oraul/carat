# Design

## Context

Every delivery's package step adds its findings to `docs/backlog.md`, the planner reads the file by its headings, and the contributor removes the entries its change fixes. With 681 entries no agent can see whether a finding is already entered, so the same finding is entered again by a later review (the periodic quality notes of #96 and #102 list several sets). The user chose to stop reading the file during deliveries and to leave its upkeep to the periodic review.

## Goals / Non-Goals

Goals: one entry per finding now; a written rule that keeps deliveries from reading or rewriting the file.

Non-goals: a budget, guard enforcement, the periodic backlog step itself, the cadence change (`periodic-council`), dropping fixed or stale entries.

## Decisions

- A merge keeps the earliest entry (its heading, owner, and history first) and adds one bullet per merged entry, `Raised again as "HEADING": ...`, carrying that entry's Where, Why it matters, and Fix outline text unchanged; the merged entry is removed. The file already records repeats as `Raised again` bullets (the Makefile entry), so no new form is introduced and nothing a merged entry said is lost. The alternative, rewriting both into one new text, would reword entries, which the brief forbids.
- A duplicate that is one clause of a grouped entry (the resize event inside `Plugin, grammar, and generator findings at df4654c`, the group count inside `The code map is behind the code`) moves to the standalone entry: the clause leaves the grouped entry's Where and Fix outline, and the standalone gains an `Also listed` bullet with it. Removing the grouped entry would drop its other findings.
- Two entries are a duplicate when they name the same code or document place and the same defect. Entries about neighboring defects in one place (a third copy of a clamp in a different method is still the same clamp duplication; a comment wrap beside a refused panel is not) are judged by the defect, and the entries the periodic notes named as duplicates are merged.
- The contributor appends by a shell redirection (`>>`), which the guard already allows for a contributor; it writes nothing else into the file. The planner's `build/plan/backlog.md` is appended whole the same way.
- The planner keeps writing `build/plan/backlog.md` with locations, from the run states' notes and the brief; it never opens `docs/backlog.md`. A finding already entered may be appended again; the periodic backlog step merges it.
- A queue item may be only backlog entries (the backlog batches) and keeps locations out of the item, so the contributor and the scouts of such an item grep `docs/backlog.md` for the entries it names, by heading or keyword, and read only those; the file is never read whole. The alternative, copying the locations into the queue, would grow the queue past its budget.
- The periodic quality reviewer is the one reader left: it reports entries fixed, duplicated, or naming gone code as findings, which the periodic backlog step of `periodic-council` will apply.

## Risks / Trade-offs

- Until `periodic-council` delivers the backlog step, nothing removes fixed entries, so the file only grows; accepted by the user's decision, and the next queue item delivers the step.
- Appending without reading can repeat a finding; the periodic step merges repeats, which is cheaper than every delivery reading the file.
