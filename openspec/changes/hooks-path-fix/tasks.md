# Tasks

## 1. The hooks

- [x] 1.1 `Makefile` (`hooks`): copy the two hooks and the scanner from `HEAD` into the common hooks directory and unset `core.hooksPath`. Tested by "hooks: make hooks installs the hooks and the scanner under the git directory and sets no core.hooksPath" and "hooks: make hooks removes the core.hooksPath an earlier target set".
- [x] 1.2 `.githooks/commit-msg` and `.githooks/pre-commit`: run the installed scanner beside them, a status other than 0 or 1 an error. Tested by "hooks: the hooks run the installed scanner, not the work tree's" and the commit-msg, pre-commit, and clean-commit cases.
- [x] 1.3 A checked-out branch's planted hooks do not run. Tested by "hooks: a checked-out branch's planted post-checkout, post-merge, and reference-transaction hooks do not run".

## 2. The gate and the guard

- [x] 2.1 `tools/rules.sh`, `tools/gates.sh` (origin), and `tools/agent_guard.sh`: no `core.hooksPath` exemption, the hooks directory limited to the samples and `INSTALLED_HOOKS_RE`, the `.githooks` check and its derivation removed. Tested by "gates: origin refuses core.hooksPath as the work tree's .githooks", "guard: core.hooksPath as the work tree's .githooks refuses every call", "gates: origin allows the installed hooks", "guard: the installed hooks pass", and "guard: the guard's installed hook names are the gates'".

## 3. The pull request scan

- [x] 3.1 `.github/workflows/scan.yml`: the base checked out to its own path without credentials, its `pr_scan.sh` run in the head's checkout. Tested by "repository: the scan workflow runs the base commit's scanner over the head".

## 4. Docs and bookkeeping

- [x] 4.1 CLAUDE.md, README.md, and `docs/codebase-map.md` area 1 describe the installed hooks; `docs/backlog.md` loses the two fixed entries.
