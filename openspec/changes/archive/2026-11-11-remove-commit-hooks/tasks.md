# Tasks

## 1. Remove the commit hooks

- [x] 1.1 `Makefile` and `.githooks/`: remove the `hooks` target, its call from `toolchain`, and the two hooks. Tested by "toolchain: a clone after make toolchain has no core.hooksPath" and "toolchain: the Makefile has no hooks target and sets no core.hooksPath".
- [x] 1.2 `tools/gates.sh` (origin, content), `tools/agent_guard.sh`, and `tools/rules.sh`: refuse any `core.hooksPath` and any hook but a sample in the common git directory's hooks folder; drop `HOOKS_PATH`, `HOOK_FILES_RE`, and the added-hook refusal. Tested by "gates: origin refuses any core.hooksPath, a tracked .githooks included", "guard: any core.hooksPath, a tracked .githooks included, refuses every call", the relative `.githooks` cases, "gates: origin refuses a hook in the hooks directory", and "guard: a planted hook refuses every call".

## 2. The base's scanner

- [x] 2.1 `.github/workflows/scan.yml` and `tools/pr_scan.sh`: check out the base commit to `base` without credentials and run its `pr_scan.sh` in the head's checkout. Tested by "pr_scan: the base's scanner reads a head that replaces the scanner", "repository: the scan workflow checks out the base's scanner to its own path, without credentials, and runs it in the head", and the adjusted "repository: the scan workflow runs on every pull request edit with read-only contents and no interpolated run line".

## 3. Docs and bookkeeping

- [x] 3.1 CLAUDE.md, README.md, `docs/codebase-map.md` area 1, `.claude/agents/contributor.md`, and the comments of `tools/scan_text.sh`: no commit hooks, the base checkout of the scan. Checked by `make gates` and `make docs-lint`.
- [x] 3.2 `docs/backlog.md` and `docs/queue.md`: the plan notes' removed and refreshed entries, the entries of `build/plan/backlog.md`, and `build/plan/queue.md`. Checked by `make docs-lint`.
