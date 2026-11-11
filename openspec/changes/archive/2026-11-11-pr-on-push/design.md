# Design

## Context

The cloud session's network layer appends a footer to every pull request created or edited over GitHub's API, and its git proxy refuses tag pushes and ref deletes while it allows a branch push (decision 19 of `tmp/briefs/pipeline-skeptic.md`). So the request to open the pull request travels inside the branch push itself, as a file of the commit, and a workflow on GitHub's runners turns it into the pull request.

## Decisions

- One script, `tools/open_pr.sh`, holds both ends so `tools/tools_test.sh` proves them: `write` and `wait` for the contributor, `read`, `gate`, and `open` for the workflow. The yml only wires the steps.
- `write CHANGE TITLE` gates first (the title is one line the title scan passes, `build/pipeline/CHANGE.body.md` passes `tools/gates.sh pr-body`), then writes the title, a blank line, and the body file to `pr.md` in the one archive directory `openspec/changes/archive/DATE-CHANGE/`; no archive, or more than one, is refused.
- `read BRANCH DIR` refuses a branch outside the Conventional Branch pattern before the name reaches git, says there is nothing to open when the branch is gone from origin (a merged branch deleted), fetches only its tip (`--depth=1`, no tags), and lists `openspec/changes/archive/*/pr.md` in that tree; a file whose path HEAD's tree (main's checkout) also holds is an older change's record and is skipped. None left: nothing to open, `DIR` stays empty and the later steps are skipped; more than one: refused. The one file is read with `git show`, never checked out, into `DIR/title` (its first line, not empty), `DIR/body` (from its third line, not empty), with a blank second line required.
- `gate DIR TOOLS` runs `TOOLS/gates.sh pr-body` on the body and `TOOLS/scan_text.sh --where title` on the title, TOOLS being main's tools in the workflow.
- `open BRANCH DIR` asks `gh pr list --head BRANCH --state open` first and does nothing when a pull request is open (a CI fix's push, or one opened by hand); otherwise `gh pr create --base main --head BRANCH --title ... --body-file DIR/body`, then `gh pr view` of the title and the body into `.live` files, and fails unless both equal the files but for trailing newlines.
- Two workflows, so no code of the pushed commit runs beside `PR_TOKEN` (the split kept from `pr-by-tag`). `branch-push.yml` runs on the push from the pushed commit's copy, so a branch controls it: `permissions: {}`, no environment, no checkout, one `true` step, skipped on a deletion. `open-pr.yml` is a `workflow_run` on its successful completion, which GitHub runs only from main's copy: its one job declares `environment: AI` (the environment allows main alone as a deployment ref), keeps `contents: read`, checks out main alone, and passes the branch name from `workflow_run.head_branch` through `env:` to main's script; the token reaches only the `open` step. A concurrency group per branch keeps two pushes from racing to create.
- `wait CHANGE [SECONDS]` polls origin with `git ls-remote 'refs/pull/*/head'` every `WAIT_STEP` seconds (10) for at most 540, under the shell tool's ten-minute limit, and records the highest N whose head is the pushed head with `tools/run_state.sh set CHANGE pr N`; otherwise it fails naming open-pr's log and the contributor stops, never opening the pull request another way.
- The guard's contributor form is `sh tools/open_pr.sh write CHANGE TITLE` and `wait CHANGE [SECONDS]`; `read`, `gate`, and `open` are refused to every agent. The contributor's one push is `tools/run_state.sh push` again, and `mcp__github__create_pull_request` stays out of its tools.

## Risks

- A protection rule of the environment `AI` holds or refuses the job; `wait` times out and the run stops with the reason, and the user reads the Action's log.
- A pull request opened by hand before the push is left alone by open-pr, so its text is not the gated one: the package step sets it with the update tool and reads it back. This bootstrap's pull request 108 is that case, since open-pr runs only once it is on main.
- A later body fix (the body mode) edits the pull request and the body file, not `pr.md`, which records the text the pull request was opened with.
