### No case for a merged sha git cannot resolve
- Location: tools/tools_test.sh:311
- Why: the proposal counts a reported merged sha git cannot resolve (a mistyped hash) as a disagreement, but only a resolvable pushed head is tested, so a regression in that path would pass tools-test.
- Fix: add an expect running phase CHANGE merge merged with a hex value naming no commit and checking that the squash commit is recorded and the merge-disagreement note is written.
