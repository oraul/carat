fix(pipeline): refuse planted objects and non-https origins at the merge gates

## Summary

Makes the merge gates refuse a planted git object or replace ref before main's gate scripts run, and pins origin by its https form alone in every agent hook and in the green line's origin check. Code a branch runs shares the main checkout's object store, so a loose object planted under the id of a later main's gates.sh blob was what the worktree add wrote into the merge gates' worktree, and the ssh and scp forms of origin let the ssh client's own configuration answer for the hosted repository (security Medium at confidence 5 and the planted-object finding). This is the first part of the split ci-trust-gaps item; the CI scope script, the check clone's toolchain, the fork pull requests of open_pr.sh, and the sprint report's sweep wording follow as ci-trust-gaps-b and ci-trust-gaps-c.

---

## Changes

- Add a git fsck of the whole shared object store to the green line in deliver-change.js, run after the worktree add of origin/main and before main's merge gates, so a planted object stops the merge before any gate script runs.
- Run every git of the green line with no global or system configuration, no hook, and --no-replace-objects, and stop the line before the worktree add when any refs/replace entry stands, since fsck ignores replace refs.
- Change every hook line under .claude/agents/ and the green line's ORIGIN_IDS to pin origin by the blob id of its https form alone, so an ssh or scp origin is refused.
- Change tools/agent_guard.sh to admit the one fsck form to the merger only and --no-replace-objects as a git global option.
- Add tools-test cases for a planted loose object stopping the green line before the gates, a planted replace ref refused, the ssh and scp origin forms refused by the hook and the origin check, and the updated pinned-digest and green-line forms.
- Document the https-only pin and the fsck before the merge gates in README.md, docs/codebase-map.md, and the guard's header.
- Record four non-blocking review findings in docs/findings/ci-trust-gaps.md, and apply the backlog lane's plan and metrics row.

---

## Testing

- Run the security review of the committed diff at 9e6738506a90, pass with no High or Medium finding and one Low, none blocking, after a first round whose replace-ref gap was fixed.
- Run the quality review at 9e6738506a90, pass with no blocking finding, and the benchmark review, pass.
- Run the checker's stages at 9e6738506a90 (diagnose, docs-lint, dev-build, test-build, test-run, tools-test, gates, bench-budget, metrics), all pass.
- Run make spec-validate after the archive, 53 items pass.
- Run make gates and make docs-lint on the packaged branch, all pass.

---

## Notes

An origin cloned over ssh or scp is now refused by every agent hook, so such a clone sets origin to the https form before a delivery. The fsck covers the whole shared store, loose, packed, and alternate objects and the commit graph, so any corrupt or planted object fails the merge closed, at about 2 seconds warm. A process left running by branch code that swaps an object back between the add and the fsck, or rewrites the worktree file on disk, is not covered; both are recorded as security Low findings in docs/findings/ci-trust-gaps.md with a fix outline. The quality advisory that merger.md step 4 omits the fsck is a wording advisory left out of this pull request.
