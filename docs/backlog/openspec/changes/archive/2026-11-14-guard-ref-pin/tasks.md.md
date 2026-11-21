# Backlog: openspec/changes/archive/2026-11-14-guard-ref-pin/tasks.md

### Reword the superseded task 1.1 of guard-ref-pin

- Location: openspec/changes/archive/2026-11-14-guard-ref-pin/tasks.md:5 (quality advisory, docs currency).
- Why: task 1.1 still describes the superseded design (config-free git ls-remote, a local fetch without writing a ref, the guard read at that commit), which task 1.3 replaced, so the archived change contradicts the hook lines.
- Fix: reword 1.1 to the temporary-repository fetch, or mark it superseded by 1.3.
- Category: pipeline
- Added: 2026-11-14
