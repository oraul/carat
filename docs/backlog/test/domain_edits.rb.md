# Backlog: test/domain_edits.rb

### A revert test pins folds misaligned with their reverted lines
- Location: test/domain_edits.rb:221
- Why: the assertion 'a revert with no fresh mark puts back no old copy' pins folds [2,3],[4,5] against lines already reverted to six rows, enshrining folds misaligned with their lines as expected.
- Fix: assert only that no stale copy comes back (a fold count or a fold the stale copy would differ in), or shift the folds back in revert_to as the signs are.
- Category: code-quality
- Added: 2026-11-18
