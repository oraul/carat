# Tasks

## 1. open-pr sets an open pull request's text

- [x] 1.1 `tools/open_pr.sh` `open`: one open pull request gets its title and body set to `pr.md`'s when they differ, read back equal; more than one is refused; the header states the one rule. Proved by `tools/tools_test.sh` "open_pr: an open pull request equal to pr.md is left as it is", "open_pr: open sets an open pull request's title and body to pr.md's", "open_pr: an open pull request gets no create", "open_pr: an edit read back with a footer is refused", and "open_pr: more than one open pull request is refused".
- [x] 1.2 `.github/workflows/open-pr.yml`: its comment and step name state the same rule. Checked by `make gates`.

## 2. The contributor and the workflow

- [x] 2.1 `.claude/agents/contributor.md`: no GitHub tool granted, the hook matches `mcp__` tools, the body mode pushes `pr.md` as a CI fix, a `wait` mode, under 7,000 bytes. Proved by "agents: the contributor holds no GitHub tool", "guard: the contributor hook refuses a pull request update tool", "agents: the body mode pushes pr.md, never a tool", and "agents: the contributor file is under 7000 bytes" (`tools/docs_lint.sh` budget).
- [x] 2.2 `.claude/workflows/deliver-change.js`: `packageStep` resumes past a push with no number in the `wait` mode; `keepPushed` keeps a body start's sha; caps for `wait` and `body`. Proved by "workflow: a resume past the push with no number only waits" and "workflow: a body start's pushed sha is kept".

## 3. Docs

- [x] 3.1 CLAUDE.md, README.md, `docs/codebase-map.md`: the one rule and open-pr's edit. Checked by `make gates` and `make docs-lint`.
