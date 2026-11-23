### Stored figures of main trust the saving lane's measuring script
- Location: `tools/run_state.sh` (`base_figures save`), `.claude/agents/benchmark.md` step 1
- Why: the benchmark agent measures the base with the change's own `tools/metrics.sh`, so a change that edits that script could store figures that let a later change's regression pass in another lane; the figures are a performance guard, not a merge gate, so the harm is a missed warning, not a bypass of the gates
- Fix: have `save` run main's own copy of the script from `tmp/.base` (or record which script measured) and refuse a measurement taken by a changed one, or store the figures only from a CI measurement of main

### The check round's carry has no end-to-end workflow test
- Location: `tools/tools_test.sh` (the carried cases), `.claude/workflows/deliver-change.js` (`rounds`)
- Why: the tests prove `carryWanted`, `carriedRun`, the command, and the source order of the carry before the checker start, but `rounds` has no harness, so the wiring (the check record, budget note, and bench phase taking the carried result) is read, not run
- Fix: add a harness for `rounds` with a stub agent and `recordStart`, and assert no checker start and `phase.check` queued at the head when `carried` answers

### The benchmark's release timing needs the base build the change removed from the common path
- Location: `.claude/agents/benchmark.md` step 4
- Why: step 4 now runs only when the brief states a time target, so a slowdown above ten percent on a change with no target is no longer reported (it was never blocking)
- Fix: store the release timing of main beside its figures, measured once per merge, and report against it

### base-figures save is allowed to every read-profile agent
- Location: tools/agent_guard.sh, the read profile's `base-figures` form
- Why: the form is shared by every agent of the read profile, though only the benchmark agent saves; save now builds and measures main's tracked tree itself, so a planted output no longer reaches the stored figures, but any read-profile agent can still trigger the build and the store.
- Fix: give the benchmark its own guard profile (or an `only_profiles` check on `save`) and add the guard cases for the other profiles refusing it.
