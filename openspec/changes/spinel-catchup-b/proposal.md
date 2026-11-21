# Proposal

## Why

`SPINEL_REF` pins Spinel at 0d1a7ca33a6edd44fad3b074e172f8a327697ebb (2026-11-19, the spinel-catchup pin), and upstream's default branch has moved 654 commits since (229 on its first-parent line, `git rev-list --count` on a history fetched back to 2026-09-01): its head was 2f6c24864127a5609533a786a6af120b7438de08 (2026-11-22) when this change started, which `git ls-remote origin HEAD` on the remote `make toolchain` clones reported. The queue's 5,476 commits behind 2b080f6cad does not hold: 2b080f6cad is 635 commits after the pin and 19 before the head. The user asked for a bump this sprint (queue item `spinel-catchup-b`, named so because spinel-bump, spinel-rebump, spinel-update, and spinel-catchup already merged): Spinel's fixes and new library support since the pin reach carat only through a bump.

## What Changes

- `SPINEL_REF` moves from 0d1a7ca33a6edd44fad3b074e172f8a327697ebb to the newest upstream commit that passes `make check` here, 2f6c24864127a5609533a786a6af120b7438de08 unless a failure that carat cannot fix small and local forces an earlier one (the tasks record which and why).
- `tools/spinel/spinel_rt_responds_generated.h` is regenerated at the new pin with `make spinel-header`, run with the 0d1a7ca3 toolchain before `make toolchain`; the output is byte-identical to the vendored file, so the diff leaves it unchanged.
- Carat code changes only where a stage fails at the new pin and the fix is small and local, each named in the tasks; any new pitfall goes to `docs/spinel-notes.md`.
- `docs/spinel-notes.md` notes each open miscompilation the new pin no longer shows; a workaround whose removal is not trivial and tested is recorded in `docs/findings/spinel-catchup-b.md` for a later `spinel-workarounds` change.

No editor behavior changes: the editor answers as it does on main at 0d1a7ca3.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a toolchain change; `skip_specs` is set.

## Impact

- `Makefile`: `SPINEL_REF`.
- `tools/spinel/spinel_rt_responds_generated.h`: regenerated with no change, the generator's output at the new pin being byte-identical.
- `tools/spinel/gen_respond_to_tables.rb`: unchanged; Spinel's `tools/gen_respond_to_tables.rb` and `tools/builtin_row_gen.rb` have no commit between the pins, only their inputs (`src/builtin_ops.c`, `lib/spinel_rt.h`) moved.
- `docs/spinel-notes.md`: the rechecked open notes and any new pitfall; `private_constant` is enforced since Spinel ae6a3602, so its note is no longer open, and its backlog entry is handed to the planner through `docs/findings/spinel-catchup-b.md`.
- CI: unchanged; its toolchain and compile caches are keyed on `make spinel-rev`, so the new pin builds a fresh toolchain on the first run.
- CLAUDE.md: unchanged, the commands and the bump procedure are the same; only the pinned value moves.
- README.md: unchanged, it does not name the pin and no command, option, or user-visible behavior changes.
- docs/architecture.md: section 5's use case rule no longer says Spinel does not enforce `private_constant`, only that it refuses the read when it runs; section 2 names `SPINEL_REF` without its value and section 13 records no per-pin decision, so neither changes.
- test/lint.rb: its comment on the private constant rule says the same; the rule is unchanged.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a toolchain bump the user asked for, done in its own pull request as the Makefile requires.

Out of scope: removing carat Spinel workarounds the new pin makes unnecessary, unless trivial and tested (the rest go to the findings file); changing Spinel itself; the queue edits the package step applies from the planner's plan.

Assumptions recorded here instead of asked: "Spinel's main" is upstream's default branch, `master`, whose head is the remote's `HEAD`; the newest commit is the one `HEAD` named when this change started, and a newer upstream commit landing during the run does not move the pin again.
