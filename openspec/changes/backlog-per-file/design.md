# Design

## Context

`tools/run_state.sh` held one backlog path, `backlog_file`: `folded_backlog` printed it and the findings files, `groom` rewrote it with one awk pass and appended `groomed.md`, and `backlog-pick` and `backlog-oldest` read the files given in order, the file order being the age order.

## Decisions

- One filing function, `file_entries`, used by the move, by groom's fold of the findings files, and by groom's `groomed.md`: an awk pass that splits its input into entries (a `## ` or `### ` heading to the next heading of any level; `# ` titles and text before the first entry dropped), finds the files each names against `git ls-files` (records paths excluded), and appends the entry, trailing blank lines cut, to `BACKLOG_DIR/<first path>.md` or `_general.md`, adding `- Also:`, `- Category:`, and `- Added:` lines unless the entry already carries a `- Category:` line (a re-filed entry stays as it is). A new file starts with a `# Backlog: <path>` title.
- The move proves itself: `backlog-move` compares the sorted heading lines and the sorted entry lines (the added lines left out) of the folder plus FILE before with the folder after, and removes FILE only when both match; on a mismatch it dies and keeps FILE, the folder in git to restore.
- Dates: the move takes each heading's date from `git blame --date=short` of FILE; groom dates a folded entry with the day it runs (`TODAY`, else `date -u`). `backlog_stream` orders the entries of the files given by that date, stably, an undated entry last, so `backlog-pick` and `backlog-oldest` keep their oldest-first rules across files.
- Groom's rewrite runs the existing removal and merge awk once over every backlog file, each preceded by a marker line, writing each file's new text to a temporary file beside it, so a repeated heading keeps its first entry across the folder and a merge reaches its kept heading in any file; a merged entry's own `- Category:` and `- Added:` lines are dropped, the kept entry's stand. A file left without an entry is removed.
- Categories: security by `SECURITY_MARK` over the joined entry; else by the first path (`.claude/`, `.github/`, `tools/`, `openspec/`, `Makefile`, `CLAUDE.md`, and the queue, metrics, goals, sprints, and contributor-notes documents pipeline; a plugin path plugins; a language-server, diagnostic, completion, hover, or RuboCop path ide; `test/` and `bench/` code-quality; other `docs/` and `README.md` design; the rest editor); an entry naming no file by words of its text in that order, design when none match.

## Risks

- A groom that dies part way leaves the folder half written; the change is in git and the records change restores it before a retry.
