# Backlog: tools/spec_validate.sh

## The spec preview of a failed change is deleted by the next change's

- Where: the loop over `openspec/changes/` in `tools/spec_validate.sh` (line 25 at `package-clean`), which empties `build/spec-preview` for each active change while the header and the failure message promise a failed preview is kept. Quality advisory of `package-clean`. Raised again at be4b63a, a duplicate of the failed spec preview entry (owner `backlog-compaction`).
- Why it matters: with two active changes, the first one's failed preview is gone before anyone reads it, so the message points at a directory holding the wrong change.
- Fix outline: preview each change under `build/spec-preview/<name>`, or stop after the first failure.
- Raised again as "A failed spec preview is deleted by the next change's preview": Where: `tools/spec_validate.sh` line 129. Periodic quality at 8d8832f, queued in `run-budgets-tidy`. Raised again at be4b63a, a duplicate of the spec preview entry (owner `backlog-compaction`). Why it matters: the header promises a failed preview is kept for reading, but each active change resets it. Fix outline: one preview directory per change, or stop resetting after a failure, with a case.
- Category: pipeline
- Added: 2026-11-05

## The spec preview copies symbolic links under openspec/

- Where: the copy of `openspec/` in `tools/spec_validate.sh` (line 26 at `explorer-folder-toggle`), with `cp -R`, which keeps symbolic links. Periodic security Low (3) at 3a99ddd.
- Why it matters: the archive run in `build/spec-preview` writes a merged spec through a link a branch commits under `openspec/specs/` to a file outside the preview.
- Fix outline: refuse a symbolic link under `openspec/` before the copy, or copy with links followed, with a `tools/tools_test.sh` case. Batched with the entry "The spec preview of a failed change is deleted by the next change's" in queue item 41.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-05

## Security Lows of the periodic review at 186ddfb

- Where: `tools/spec_validate.sh` line 17 runs the unpinned `npx -y @fission-ai/openspec@latest`, Low (5), queued in `ci-hardening`; `JsonRpcLanguageGateway#path_of` (`carat/adapters/json_rpc_language_gateway.rb` line 789) keeps `.` and `..` segments, so `VisitTarget`'s lexical inside check passes a path only `ResolveInside` refuses, Low (4), queued in `bidi-controls`; `list_dir` and `read_file` in `carat/use_cases/plugins/file_requests.rb` (lines 47 and 72) take any path with no root, Low (3), queued in `file-access-tidy`.
- Why it matters: a compromised npm release runs with push credentials; one file gets different titles and keys; a plugin joining an unchecked name reads outside the project.
- Fix outline: pin the version in one `OPENSPEC_VERSION` variable used by CLAUDE.md, the Makefile, and the script; return `PluginApi::Paths.normalize(out)` from `path_of` with a `..` row; take a root and require `Paths.inside?` and `ResolveInside`, with rows.
- Merged: ### Security Lows of the periodic review at 186ddfb
- Location: the locations listed under this heading in the backlog; the queue line of review-trust-lows names tools/run_state.sh:201 and the sprint and delivery workflows
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.
- Also: carat/adapters/json_rpc_language_gateway.rb, carat/use_cases/plugins/file_requests.rb, CLAUDE.md, Makefile, tools/run_state.sh, docs/queue-backlog.md
- Category: security
- Added: 2026-11-10

### spec_validate removes a failed preview

- Location: tools/spec_validate.sh:25 (sprint-4 sweep, quality).
- Why: the header promises a failed preview is kept, but the next active change's run removes build/spec-preview.
- Fix: preview each change under its own directory, or stop removing after a failure.
- Category: pipeline
- Added: 2026-11-14

### spec_validate.sh deletes the failed preview it promises to keep

- Location: tools/spec_validate.sh:60, :70 (sweep, quality).
- Why: each preview starts with rm -rf "$preview", deleting an earlier change's failed preview, though the header says it is kept in build/spec-preview.
- Fix outline: preview each change in build/spec-preview/NAME, or stop at the first failure.
- Category: pipeline
- Added: 2026-11-17

### Each active change's iteration runs rm -rf on build/spec-preview (sprint-20 sweep quality, spec_validate.sh:25)

- Location: `tools/spec_validate.sh:25`
- Why: each active change's iteration runs rm -rf on build/spec-preview, so an earlier change's failed preview is deleted by the next one while its message says the preview is in build/spec-preview
- Fix: preview each change under build/spec-preview/NAME
- Category: pipeline
- Added: 2026-11-19

### tools/spec_validate.sh:26: rm -rf of build/spec-preview for every active change removes (sprint-22 sweep quality)

- Location: `tools/spec_validate.sh:26`
- Why: rm -rf of build/spec-preview for every active change removes the preview of an earlier failed change, so the message the preview is in build/spec-preview (line 37) and the header claim a failed preview is kept are wrong with two active changes
- Fix: one preview directory per change (build/spec-preview/NAME), or stop after the first failure
- Category: pipeline
- Added: 2026-11-20

### spec_validate hard-codes the OpenSpec version (sprint-24 sweep quality)

- Location: `tools/spec_validate.sh:18`
- Why: a copy of the Makefile's OPENSPEC_PACKAGE kept equal only by a tools case.
- Fix: pass OPENSPEC_CMD from the target and drop the literal.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-21
