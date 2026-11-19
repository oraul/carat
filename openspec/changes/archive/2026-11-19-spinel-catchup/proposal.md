# Proposal

## Why

`SPINEL_REF` pins Spinel at c0502112d8cf8c6f57bc7e1ef5a2af1732407036 (2026-11-16), and upstream's default branch has moved 1,045 commits since (296 on its first-parent line, `git rev-list --count` on a history fetched back to 2026-11-01): its head was 0d1a7ca33a6edd44fad3b074e172f8a327697ebb (2026-11-19) when this change started, which `git ls-remote origin HEAD` on the remote `make toolchain` clones reported. The queue's 656 and the user's 889 were earlier counts. The user asked for the bump now (queue item `spinel-bump`, renamed `spinel-catchup` because a change of that name merged as #95): the commits carry GC rooting fixes, String box reads, call-plan and keyword-forwarding work, and the fix for a child waited for inside a Fiber, which the Fiber study and the plugin tasks need.

## What Changes

- `SPINEL_REF` moves from c0502112d8cf8c6f57bc7e1ef5a2af1732407036 to the newest upstream commit that passes `make check` here, 0d1a7ca33a6edd44fad3b074e172f8a327697ebb unless a failure that carat cannot fix small and local forces an earlier one (the tasks record which and why).
- `tools/spinel/spinel_rt_responds_generated.h` is regenerated at the new pin with `make spinel-header`, run with the c0502112 toolchain before `make toolchain`; the output is byte-identical to the vendored file, so the diff leaves it unchanged.
- Carat code changes only where a stage fails at the new pin and the fix is small and local, each named in the tasks; any new pitfall goes to `docs/spinel-notes.md`.
- `docs/spinel-notes.md` notes each open miscompilation the new pin no longer shows; a workaround whose removal is not trivial and tested is recorded in `docs/findings/spinel-catchup.md` for a later `spinel-workarounds` change.

No editor behavior changes: the editor answers as it does on main at c0502112.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a toolchain change; `skip_specs` is set.

## Impact

- `Makefile`: `SPINEL_REF`.
- `tools/spinel/spinel_rt_responds_generated.h`: regenerated with no change, the generator's output at the new pin being byte-identical.
- `tools/spinel/gen_respond_to_tables.rb`: unchanged; Spinel's `tools/gen_respond_to_tables.rb` and `tools/builtin_row_gen.rb` have no commit between the pins, only their inputs (`src/builtin_ops.c`, `lib/spinel_rt.h`) moved.
- `docs/spinel-notes.md`: the rechecked open notes and any new pitfall.
- CI: unchanged; its toolchain and compile caches are keyed on `make spinel-rev`, so the new pin builds a fresh toolchain on the first run.
- CLAUDE.md: unchanged, the commands and the bump procedure are the same; only the pinned value moves.
- README.md: unchanged, it does not name the pin and no command, option, or user-visible behavior changes.
- docs/architecture.md: unchanged, section 2 names `SPINEL_REF` without its value and section 13 records no per-pin decision.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a toolchain bump the user asked for, done in its own pull request as the Makefile requires.

Out of scope: removing carat Spinel workarounds the new pin makes unnecessary, unless trivial and tested (the rest go to the findings file); changing Spinel itself; the queue edits the package step applies from the planner's plan.

Assumptions recorded here instead of asked: "Spinel's main" is upstream's default branch, `master`, whose head is the remote's `HEAD`; the newest commit is the one `HEAD` named when this change started, and a newer upstream commit landing during the run does not move the pin again.
