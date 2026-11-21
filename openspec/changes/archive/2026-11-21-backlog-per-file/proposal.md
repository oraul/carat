# Proposal

## Why

`docs/backlog.md` is one file of about 1 MB and 1,800 headings, and the sprint planner reads it whole to groom and to pick the backlog lane's items. The user asked on 2026-11-21 that the backlog be split "so the planner won't read 2 MB of backlog": one file per source file, saying what is wrong and why, since the planner already knows which pool and files it needs. This change delivers parts (1), (2), and (5) of the brief; parts (3) and (4), the guard and the contributor's read access, `backlog-index`, and the planner's sprint order, are `backlog-per-file-b`.

## What Changes

- `docs/backlog/` mirrors the tree: every entry of `docs/backlog.md` (a `## ` or `### ` heading to the next heading) moves, its lines unchanged, to `docs/backlog/<path of the first file it names>.md` (a leading dot of each part written `_`, a symbolic link on the way refused), `docs/backlog/_general.md` when it names none, followed by an `- Also:` line naming the other files it names (left out when there are none), a `- Category:` line (design, pipeline, security, editor, ide, plugins, or code-quality; a security entry, by `SECURITY_MARK`, always security), and an `- Added:` date line. `docs/backlog.md` is removed.
- A new `sh tools/run_state.sh backlog-move FILE` files every entry of FILE into the folder, proves that the folder's heading lines and entry lines after the move equal those before plus FILE's (count and set), and only then removes FILE. It made the move.
- `groom` reads the folder and the findings files, files each findings entry into the backlog file of its first named path, applies its removals and merges per backlog file (a file left with no entry is removed), removes the findings files, and files `build/plan/groomed.md`'s entries the same way.
- `backlog-pick` and `backlog-oldest` take files or directories (each `*.md` under a directory, in name order) and order the entries by their `- Added:` date, an undated findings entry last, so the oldest first holds across files; `backlog-dups` reads the folder.
- The planner's sprint mode reads only the backlog files of the files and areas its queue items and pool name, plus the closing sprint's findings files, never the whole folder; `sprint-planning.js` hands it `backlog-oldest` and `backlog-pick` over `docs/backlog`.
- `tools/docs_lint.sh` checks the folder's files as documents, and a backticked `docs/backlog.md`, now retired, may stand in a backlog file or a lane queue.
- CLAUDE.md, README.md, `docs/architecture.md`, `docs/codebase-map.md`, `docs/spinel-notes.md`, the comments of `tools/gates.sh` and `test/lint.rb`, and `docs/queue-backlog.md` name the folder; the user-approved exception line goes under `docs/queue-backlog.md`'s Sprint 25 heading.
- The append log is unchanged: a delivery appends findings to `docs/findings/<change>.md` only.

This is outside the roadmap of `docs/architecture.md` section 12: delivery tooling and records, no editor behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: no spec covers the delivery tooling, so `skip_specs: true`.

## Out of scope

- `tools/agent_guard.sh`, the contributor's read access (`.claude/agents/contributor.md` line 20 and the rules card in `.claude/workflows/deliver-change.js`, which a test keeps equal), `backlog-index`, and the planner's sprint order: `backlog-per-file-b`.
- `tools/rules.sh`: its `docs/backlog\.md$` alternative stays for a later rules change, named in the findings file.
- `docs/queue-feature.md` and `docs/metrics-feature.tsv`, the feature lane's files: the backticked `docs/backlog.md` on `docs/queue-feature.md` line 3 stays, which the docs-lint retired-path rule allows, named in the findings file.
- Assumption: "the first file it names" is the first token, in the entry's text order (heading first), that names a file tracked at HEAD, the backlog and findings files excluded; a path no longer tracked does not place an entry.
- Assumption (extra, named): the `- Added:` line, the date `git blame` gives the entry's heading line in `docs/backlog.md` (groom's date for a folded findings entry), keeps backlog-oldest and backlog-pick oldest-first across files and gives part (4) its age.
- Assumption: a heading with no line under it (16 group headings such as `## Findings of top-rows`) moves as an entry, so the heading set stays equal; the `# ` titles and the opening paragraph are no entries, and each backlog file starts with a `# Backlog: <path>` title.
- Assumption: the categories of entries that are not security come from the first path (or, naming none, from words of the entry), a heuristic the planner may correct by editing the line.

## Impact

`tools/run_state.sh`, `tools/tools_test.sh`, `tools/docs_lint.sh`, `tools/gates.sh` (comments), `test/lint.rb` (a comment), `.claude/agents/planner.md`, `.claude/workflows/sprint-planning.js`, `docs/backlog.md` removed and `docs/backlog/` added, `docs/queue-backlog.md`, `docs/spinel-notes.md`.

- CLAUDE.md: changed, its Status and Backlog lines name the folder.
- README.md: changed, its delivery description names the folder.
- docs/architecture.md: changed, its plugin request list names the folder.
- docs/codebase-map.md: changed, the `tools/run_state.sh` and `tools/docs_lint.sh` lines and the rules line naming the backlog.
