# Design

## Context

The check runs every stage in a throwaway clone under `TMPDIR` (`clone_make`), its environment stripped of the run-state, stage, metrics, and project paths (`CLONE_EXEC`). The clone links `tmp/.toolchain` and `tmp/.spinel` to the delivery clone's, which a lane links on to the main checkout. The links are writable and name the delivery clone's absolute path; a stage also learns it from its parent's working directory. A shell runner under the same user cannot stop a process from writing a path it can name, so the change takes away the path the clone itself offers and detects the rest.

## Decisions

- The toolchain is copied, not linked: 56 MB, under a second per check. Spinel installs absolute links (`bin/spinel` to `lib/spinel/spinel` under the shared toolchain), so each link naming the shared toolchain, by its resolved or its unresolved path, is pointed at the same place in the copy; a link elsewhere is kept. Copying the links' targets instead would move the binaries away from the runtime files they find beside them.
- `tmp/.spinel` (1.3 GB) is not linked: no stage reads it (only `toolchain`, `spinel-header`, and `spinel-rev`, none a stage, name `SPINEL_SRC`).
- Detection, after the stages passed and before the pass verdict, so a stage that wrote outside fails the check with a verdict line of the form the workflow reads (`check: stage none failed at HEAD; read LOG`), its paths listed above it:
  - The mark is taken right after the clone is made, before `make stages` runs the branch's Makefile, once a new second began, so nothing written before it counts: the time as `YYYY-MM-DD HH:MM:SS`, held in the runner's memory, which no stage can change; a file counts when its status-change time is later (`find -newerct`, GNU and BSD), which `touch` cannot set back.
  - Scanned: the delivery clone without following links, pruning its `.git` directory, `tmp/` (the lanes, scouts, and toolchain links), and `build/pipeline`, `build/stages`, `build/plan`, and `build/spinel-cache`, which concurrent lanes and the runner write; a linked worktree's `.git` file stays scanned. Then the shared toolchain and Spinel's checkout through their links, the common directory's `hooks` and `config.worktree`, and a linked worktree's whole git directory, which only its own lane writes.
  - The common repository configuration is compared by its listing, less `branch.NAME.remote` and `branch.NAME.merge`, which another lane's `push -u` sets during the check.
  - The run state is compared as lines, commas removed and sorted, every figure (`metric.*`) but the measurements left out, since the checker's line and /deliver's `usage` and `tokens` write figures again while a rejoined check runs, and so are the notes (`note.*`) and the phases a workflow's close records (`phase.plan`, `implement`, `package`, `ci`, `merge`, `retro`, `report`, the workflow's `CLOSABLE` lines), since a workflow that stops while its check runs closes before the resumed one rejoins it, while a measurement (`metric.allocs.*`, `metric.rounds.*`, `metric.us.*`, `metric.analysis_ms.*`), which only the metrics command imports, stays compared: the mark's copy with every stage record the runner wrote since (`stage_record`, its last value per key) put in must equal the file. Other changes' run states, the compile records (`compiled`), and the stage logs stay unchecked: concurrent lanes and the runner write them.
- The waiter's dirty-tree test runs `git status` with `GIT_OPTIONAL_LOCKS=0`, so a rejoining waiter does not refresh the index the scan of a linked worktree's git directory reads.
- Detection runs only on the pass path: a failed stage already fails the check.

## Risks

- A person or agent editing the delivery clone during its check fails it; the checker edits nothing while it waits.
- A hostile stage can still write the runner's job files, another change's run state, the compile records, or the compile cache, or edit `tools/run_state.sh` while it runs: recorded in `docs/findings/check-runner-safety.md`.
- A toolchain change by an absolute path persists after the failed check: the failure lists the path, and `make toolchain` reinstalls.
