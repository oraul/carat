# Design

## Context

`tools/run_state.sh` grew by one change at a time, each leaving advisories in the backlog. By the base most of the check sandbox group was already closed by later changes (the runner keeps its jobs in memory, the excerpt of a failing log passes `visible_text`, the escaped verdict allows no path of the main checkout's `build/` by default); the entries remain open on paper, so the work is to prove which are closed and fix the rest.

## Goals / Non-Goals

**Goals:**
- Every fix has a tools-test case that fails before it; each security entry's case is a failing-stage or refusal case.
- Each closed entry is named once in the findings file with how it closed.

**Non-Goals:**
- Any edit of `tools/rules.sh`, which the merge gate reads.
- An operating-system sandbox for the stages.

## Decisions

- A throwaway HOME inside the clone (`tmp/home`) and no `XDG_CONFIG_HOME` is set by `CLONE_EXEC`, the one place a stage's environment is made, so a stage that writes `~` writes its clone; the scan of the real files stays for a stage that finds them by an absolute path. `~/.claude` is not scanned as a whole, since the session writes it; only `settings.json` and `settings.local.json`, which hold the hooks.
- The compile cache key is `stage_key`: the code key of the stage plus the make command, hashed. Alternative: a fourth column in the compiled file; the key is already the one thing compared.
- `main_scan` reads `git ls-files -z` and `find -print0` as byte-1-separated records, since git quotes a tab, quote, or backslash in its line form whatever `core.quotePath` says.
- `push --pr-text` compares the paths changed since the recorded push with the archived `pr.md` of the change; a text review that blocks may rewrite nothing else.
- The fold's helpers `fold_clean` and `removed_refs` are tested through an extract of their text, since the script runs its commands when sourced.

## Risks / Trade-offs

- A stage that needs the user's real HOME now fails; none of the stages read it.
- The check's time limit on `ls-remote` uses `timeout` where it exists and none elsewhere.
