# Design

## Context

See proposal.md, Why. `append_history` is the only writer of the lane histories; `lane_rows` and `history_rows` read rows by field position and print the script's `HEADER`, never a file's line 1, which is why `/status` never showed the short headers. `merge_main` merges `docs/metrics-*.tsv` with `merge=union`, so both lanes' appended rows are kept.

## Goals / Non-Goals

Goals: both histories consistent with `HEADER`; a later column addition stopped at the first history append and at docs-lint. Non-goals: an automatic migration.

## Decisions

- Refuse, not rewrite: a header that differs from `HEADER` stops `history` before any row is written (the check runs over every lane file before the append loop), with a message naming the file and the fix. Rewriting in place would rewrite older rows on every lane branch, and under `merge=union` two different rewrites of line 1 would both be kept; refusing puts the migration in the change that alters `HEADER`, reviewed once.
- Exact comparison of line 1 with `HEADER` (`sed -n 1p`), so a carriage return, a missing column, or a reordered one all refuse.
- `-s`, not `-f`, decides whether a lane file needs its header, so an empty file gets one instead of a headerless row.
- The docs-lint `histories` check counts tab-separated fields per non-blank row against line 1 of the same file, skipping blank lines as `lane_rows` does (`NF`). It reads `docs/metrics-*.tsv` under the checked root, so the fixture tree of `tools/tools_test.sh` can exercise it and a tree with no histories passes with 0 files.
- The data migration appends `\t-\t-` to rows with exactly 22 fields and rewrites line 1; awk prints every other line unchanged, so the 24-field rows, the feature lane's later appends included, merge without conflict.

## Risks / Trade-offs

- [A run whose base still has a short header refuses its history append] → this change fixes both files on main; a lane branched before it takes it in through `merge-main`, whose union merge keeps the rewritten lines from main since the lane did not touch them.
- [A future change adds a column without migrating] → its own package step's `history` refuses, and docs-lint fails once a longer row lands under the old header.

## Migration Plan

Rewrite both files once in this change (task 3.1). Rollback is a revert of the commit.
