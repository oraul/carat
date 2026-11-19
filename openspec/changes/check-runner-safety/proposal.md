# Proposal

## Why

`clone_make` (`tools/run_state.sh:971` at e4fb380, not `:529` as the queue line says) links the check clone's `tmp/.toolchain` and `tmp/.spinel` back to the delivery clone's, which in a lane are the main checkout's shared toolchain. A check stage runs branch code (make recipes, test programs), so it can overwrite the Spinel binaries every later check and delivery runs through a path inside its own clone, and the links also hand it the delivery clone's absolute path, through which it can write the delivery clone's git hooks and configuration, its run state, or its tracked files. Nothing notices either write: the check passes and the next one runs on what the stage left.

This is a pipeline defect outside the roadmap of `docs/architecture.md` section 12, the pipeline-defect slot of Sprint 21.

## What Changes

- `tools/run_state.sh`, `clone_make` and `toolchain_copy` (new): the check clone gets its own copy of the shared toolchain, each absolute link into the shared toolchain pointed at the copy, so a stage writing `tmp/.toolchain` changes only its copy; Spinel's checkout, `tmp/.spinel`, which no stage reads, is no longer linked into the clone.
- `tools/run_state.sh`, `escape_mark` and `escaped_paths` (new), `check_run`, `check_stages`: before the stage list is read the runner notes the time, the delivery clone's repository configuration, and its run state; once the stages passed it fails the check, naming the paths, when a file changed since then in the delivery clone (but its run states, stage logs, plans, compile cache, and `tmp/`), in its linked worktree's git directory, in its hooks, in the shared toolchain or Spinel's checkout, when its repository configuration changed (but the upstream a concurrent push sets), or when its run state holds anything but the stage records the runner wrote.
- `tools/run_state.sh`, `stage_record` (new): every stage record the runner writes goes through it, so the runner knows the run state it expects.
- `tools/tools_test.sh`: cases proving the clone's own toolchain copy and its relinked links, Spinel's checkout left out, a relative toolchain write leaving the shared one, and a failed check for a stage that writes, by an absolute path, the shared toolchain, Spinel's checkout, a tracked file, the run state, a stage record, a hook, the repository configuration, or a linked worktree's git directory; and one passing with an upstream written.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The benchmark, which runs branch code in the lane with the toolchain and run states linked (`.claude/agents/benchmark.md`, `LANE_LINKS`): queued as `check-runner-safety-bench`, by the plan's split.
- A stage that rewrites the runner's own files or the shared compile cache, or one that kills or outruns the runner, is not confined: a shell runner under the same user cannot stop it without an operating-system sandbox; the runner detects the writes named above and records the rest as findings.
- No `tools/rules.sh` edit; no file of the feature lane.

## Impact

- README.md: the checker paragraph says the clone has its own toolchain and that a stage writing outside its clone fails the check.
- docs/codebase-map.md: area 1's `tools/run_state.sh` entry names `toolchain_copy` and `escaped_paths`.
- CLAUDE.md: unchanged, it does not describe the check clone, and no command, agent, or rule changes.
- docs/architecture.md: unchanged, no layer, port, or module is touched.
