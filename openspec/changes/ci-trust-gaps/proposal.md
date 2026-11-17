# Proposal

## Why

Two trust gaps on the merge side of the delivery pipeline (T1 pipeline defect, security Medium (5) and the planted-object finding): code a branch runs shares the object store of the main checkout, so a loose object it plants under the id of a blob of a later `main` (git keeps an existing loose object when a small fetch arrives) is what `git worktree add` writes into the merge gates' worktree `tmp/.merge-gates`, replacing main's `tools/gates.sh` with the branch's; and every hook line under `.claude/agents/` and the green line's `ORIGIN_IDS` accept origin's ssh form (`git@host/path` after an ssh scheme) and scp form (`git@host:path`), whose transport reads the ssh client's own configuration, which no `GIT_CONFIG_GLOBAL=/dev/null` pins, so a host alias can answer for the hosted repository.

## What Changes

- The green line of `.claude/workflows/deliver-change.js` (`mergeLines`) runs `git fsck --no-dangling --no-progress origin/main`, with no global or system configuration and no hook, after the worktree add and before main's merge gates: fsck hashes every object of the store, loose, packed, and alternate, and checks the commit graph, so a planted object fails the line before any gate script runs.
- `tools/agent_guard.sh` admits that one fsck form, to the merger only.
- Every hook line under `.claude/agents/` pins origin by the blob id of its https form alone; `ORIGIN_IDS` holds that id with and without `.git`; an ssh or scp origin is refused by every hook and by the green line's origin check.
- `tools/tools_test.sh`: a planted loose object under the id of main's `tools/gates.sh` blob stops the green line's tail before the gates (and the plain worktree add is shown to have written the planted text); the ssh and scp forms are refused by the hook and by the origin check; the pinned-digest and green-line cases follow the new forms.
- `docs/codebase-map.md` and README.md describe the single pinned form and the fsck before the merge gates; the guard's header says the same.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline's guard and merge gates, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `tools/agent_guard.sh`, every agent file under `.claude/agents/` (the hook lines' pins only), `tools/tools_test.sh`, `docs/codebase-map.md`, README.md.
- CLAUDE.md: unchanged, the Agents section and the hard rules name neither the hook pins' forms nor the merge gates' object check.
- README.md: changed, the pipeline section says the merge gates' worktree is checked by fsck before main's gates run.
- docs/architecture.md: unchanged, it describes the editor's architecture and test machinery, not the delivery guard.
- docs/codebase-map.md: changed in its descriptions only; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1) from the backlog, Sprint 15's first backlog item, split at its start. One reviewable pull request.

Minor assumptions: an origin cloned over ssh or scp is now refused by every agent's hook, so such a clone sets origin to the https form (`git remote set-url origin` with the https address) before a delivery; fsck runs over the whole shared object store rather than main's objects alone, since only a whole-store check also covers packs, alternates, and the commit graph, so a corrupt or planted object anywhere stops the merge (fail closed), at about 2 seconds warm on the current store.

## Out of scope

- ci-trust-gaps-b: CI running the branch's own `tools/ci_scope.sh` and the check clone's writable toolchain.
- ci-trust-gaps-c: open_pr.sh counting and editing a fork's pull request of the same branch name, and the sprint report's wording of a half-run sweep.
- The guard's `local_origin` test of fetches, which keeps accepting any hosted-looking form; the hook pin in front of it is what refuses the ssh and scp forms.
