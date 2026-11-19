# Proposal

## Why

Quality passes its first review in 98 of 176 runs, against 171 for the check and 169 for security. The reviewer is told to report every blocking finding in a first pass, yet a fix round raises new blocking findings on code the earlier review read. Only a re-raise at an earlier advisory's location is recognised (`reRaised`); a new blocking finding on unchanged lines is not recorded as what it is, a miss of the first pass, so the rate cannot be traced to its cause.

## What Changes

- `.claude/agents/quality-reviewer.md`, step 4: the first pass reads every file of the diff to its end and, before returning, re-checks each changed function for the correctness and untested-behavior points; in a later round a new blocking finding, one not among the blocking findings the input lists, on lines unchanged since the commit the input names as the last quality review, carries the words `first-pass miss` right after its location.
- `.claude/workflows/deliver-change.js`: `firstPassMiss` recognises that marker (right after the location, any case) and the pure helper `qualitySplit` separates re-raises of an earlier advisory from misses, a miss being only a new finding, never one the last review left blocking; the quality handler notes the misses as `quality first-pass misses`, beside the re-raise note; the whole-branch review input lists the last review's blocking findings too. The finding still blocks (it is a real defect); only the record is new.
- `tools/tools_test.sh`: cases proving the marker is matched, an unmarked finding is left alone, and `qualitySplit` keeps out re-raises and prior blocking findings.
- `first.quality` and the history's `first_pass` are unchanged: the misses are counted only in the run state's notes, so the mid-tier trial's comparison with 98 of 176 stays like for like.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- Acceptance that quality passes first on 7 of the next 10 runs is measured from the metrics history afterwards, not by this change.
- The last review's commit stands for the first pass: lines unchanged since any earlier read were read by it.

## Impact

- README.md: the pipeline's quality review step names the first-pass miss.
- CLAUDE.md: unchanged, it does not describe the quality reviewer's wording of findings.
- docs/architecture.md: unchanged, no layer or port is touched.
