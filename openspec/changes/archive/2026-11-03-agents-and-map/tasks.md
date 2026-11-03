# Tasks

## 1. The code map

- [x] 1.1 Write `docs/codebase-map.md` with one section per area (What, Flow, Files with key methods, Tests, Designs, Rules, Bench) and the Delivered changes section; verify that every file of the five roots is in one area with `make lint`.
- [x] 1.2 Add the coverage rule to `test/lint.rb` (`map_spans`, `map_file?`, `map_files`, `map_problems`, and their self-checks) and count the map in `tools/ci_scope.sh`; verify with `make lint`, with a probe file under `tools/` that fails it, and with `make snapshots`, whose only diff is the lint snapshot's two new lines.

## 2. CLAUDE.md

- [x] 2.1 Slim `CLAUDE.md`: Status, Layout, Agents, Stack, Commands, and Coding conventions as `design.md` lists; verify the size before and after and the rule list in `design.md` against the old file, and diff the unchanged sections.

## 3. Agents

- [x] 3.1 Add `.claude/agents/scout.md` with its frontmatter, limits, steps, and pack shape; verify by reading it against the request.
- [x] 3.2 Rewrite `.claude/agents/contributor.md` with the improvements `design.md` lists; verify by reading it against the request and that it does not repeat `CLAUDE.md`.

## 4. Docs

- [x] 4.1 Point the README at the map; verify by reading it.

## Workflow follow-up

- Run `make check` on the committed tree as detached stages with a line each in `build/stages/agents-and-map/progress`.
- Run the security review on the committed branch diff.
- Push once, open the pull request, strip any footer, wait for CI, and squash-merge.
