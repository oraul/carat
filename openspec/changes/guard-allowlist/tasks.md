# Tasks

## 1. Agent guard

- [ ] 1.1 `tools/agent_guard.sh`: a lexer that splits a Bash command into words, operators, and redirections as the shell does and refuses expansions, substitutions, ANSI-C quoting, subshells, here-documents, globs, braces, and a leading `~`. Tested by the `tools/tools_test.sh` bypass cases of every profile.
- [ ] 1.2 `tools/agent_guard.sh`: the forms of the `read`, `merger`, and `contributor` profiles, each simple command judged against its profile's forms, and the shared word rules (parent step, run state's directory). Tested by the per-profile allowed and refused cases and the dry run of each agent's commands.
- [ ] 1.3 `tools/agent_guard.sh`: one write-target judge for redirections, writing commands, and file tools (project, `.git/`, run state's directory, DIR, the body file never a link). Tested by the write-target and body-file cases in a real tree.
- [ ] 1.4 `tools/agent_guard.sh`: the header lists every profile's forms, worded as the code behaves.

## 2. Hooks

- [ ] 2.1 `.claude/agents/*.md`: each hook runs the guard of `origin/main` and exits 2 on any failure; the merger's hook takes no DIR. Tested by the cases "guard: a hook refuses when main has no guard", "guard: a hook refuses when the guard fails", and "guard: a hook runs main's guard".
- [ ] 2.2 `.claude/agents/benchmark.md`: the base is measured with `cd tmp/.base && sh PROJECT/tools/metrics.sh measure ...` and absolute toolchain paths. Tested by the benchmark's dry-run cases.

## 3. Gates

- [ ] 3.1 `tools/gates.sh`: `settled_at` lists paths with `--no-renames`. Tested by the case "gates: security refuses a code file moved into openspec".

## 4. Docs and records

- [ ] 4.1 `docs/codebase-map.md` area 1: the guard's entry (the lexer, the forms, the write-target judge, the hook) and the `tools/tools_test.sh` entry (the guard and the CI wait). Checked by `make docs-lint` and `make gates`.
- [ ] 4.2 `docs/backlog.md`: remove the nine entries this change fixes, narrow the hooks entry to the agent files, set the Queued lines the planner named, and add what the change leaves. Checked by `make docs-lint`.
- [ ] 4.3 Run `make tools-test`, `make lint`, `make docs-lint`, and `make gates`.
