# Design

## Context

The pull request is opened by `.github/workflows/open-pr.yml` from the `pr.md` the package step commits (`pr-on-push`), because a pull request created or edited over GitHub's API from a session reaches GitHub with a footer. Two paths still edit it from the session: the body mode (`contributor.md`, `### body`) and the package step's hand-opened case, both through `mcp__github__update_pull_request`, which the contributor's tools grant and no hook covers (its matcher is `Bash|Edit|Write|NotebookEdit`). `deliver-change.js` runs the package step unless the run state holds both `pushed` and `pr`, so a resume after a push whose `tools/open_pr.sh wait` failed reruns archive, records, and push, which `tools/run_state.sh push` refuses.

## Goals / Non-Goals

Goals: no session write path to a pull request; a title or body fix still reaches it; a resume past the push without a number only waits; `contributor.md` under 7,000 bytes.

Non-goals: changing the merger, CI, or the scan; changing the push count rule.

## Decisions

- open-pr edits as well as opens. `tools/open_pr.sh open` counts the branch's open pull requests: none opens it as before; one compares its live title and body with `pr.md`'s (trailing newlines aside) and, when either differs, runs `gh pr edit BRANCH --title --body-file`; either way it reads the text back and fails unless equal; more than one is refused. The edit runs on GitHub's runners with `PR_TOKEN`, so it arrives clean, and its `edited` event reruns the scan. Alternative rejected: a session edit through `gh` over the proxy, which gets the same footer.
- The body mode pushes. It rewrites `pr.md` (`tools/open_pr.sh write`, which gates the title and body), commits, and pushes with `--ci-fix`; the merger's red line recorded `ci red`, so the run state allows it. The diff is under `openspec/`, the records-only paths, so the pre-push gates find the checks and reviews settled. `keepPushed` keeps a body start's sha, and the merge loop's next start waits at it. The workflow still allows one body fix per run.
- The contributor's grant drops both GitHub tools; its hook matcher adds `mcp__.*`, and `tools/agent_guard.sh` already refuses a tool it does not judge, so a re-granted tool is still refused (main's guard).
- `packageStep(state)` in the workflow names the step: `merge` when `pushed` and `pr` are both recorded, `wait` when only `pushed` is, `package` otherwise. `wait` starts the contributor's new `wait` mode (cap 6), with no verify before it: the merge phase reruns the check and the reviews on a resume past the push; a wait returning no number stops the run as the package step's does.
- `contributor.md` is shortened by moving nothing out of reach: repeated phrases go, and the package step's detail on the planning records stays in the workflow's package prompt, which already states it. `tools/docs_lint.sh` holds `.claude/agents/contributor.md` at 6,999 bytes.

## Risks / Trade-offs

- open-pr runs main's copy, so the edit path works from the merge of this change on; this change's own pull request is opened by main's current open-pr.
- A person's edit of the pull request text on GitHub is reset by the next push: accepted, `pr.md` is the record the squash body is checked against.
- Between the body push and open-pr's edit the scan reads the old text red; the merger keeps the latest run per check name and CI runs far longer than the edit takes.
