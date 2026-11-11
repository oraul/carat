# Design

## Context

The package step created the pull request with the session's GitHub tool, and the cloud session's network layer appends a footer to every create made over GitHub's API (decision 18 of `tmp/briefs/pipeline-skeptic.md`). Git pushes reach GitHub unchanged, so the request to create the pull request travels as a git object: an annotated tag, which a GitHub Actions workflow on GitHub's runners turns into the pull request.

## Decisions

- One script, `tools/pr_tag.sh`, holds both ends so `tools/tools_test.sh` can prove them: `push` and `wait` for the contributor, `read`, `branch`, `gate`, and `same` for the workflow. The yml only wires the steps and calls `gh`.
- The tag message is the title, a blank line, and the body file, written with `git tag -a --cleanup=verbatim`, since the default cleanup would strip the body's `## ` headings as comments. `read` takes the message from `git cat-file tag`, after the header's blank line, and refuses a lightweight tag, a tag outside `pr/`, an empty title, a second line that is not blank, and an empty body.
- `push` gates before it tags: the run state's `pushed` must be HEAD, the body file passes `tools/gates.sh pr-body`, and the title is one line the scanner passes. It refuses a tag `pr/<branch>` already on origin (the workflow pending or failed), and pushes only `refs/tags/pr/<branch>`.
- `wait` polls origin with `git ls-remote` every `WAIT_STEP` seconds (10) for at most 540, under the shell tool's ten-minute limit: once the tag is gone and a `refs/pull/N/head` is the pushed head, it records the highest such N with `tools/run_state.sh set CHANGE pr N`. Otherwise it fails naming the open-pr workflow's log, and the contributor stops; it never falls back to a pull request tool.
- The workflow's `open` job declares `environment: AI` and sets `GH_TOKEN` from the environment's `PR_TOKEN`, a token of the user's, so the pull request's events start CI and the scan; `GITHUB_TOKEN` is never used to create it. It checks out the tagged commit and, to `main/`, main's tools, and calls `gate` with `main/tools`. Every value from the tag reaches the shell through files and `env:`, never written into a script.
- `gate` runs `GATES/gates.sh pr-body` on the body and `GATES/scan_text.sh --where title` on the title, as `tools/pr_scan.sh` scans a title; `branch` refuses a name outside the guard's Conventional Branch pattern and one `git ls-remote --heads origin` does not list.
- The `delete` job needs `open`, holds `contents: write`, checks out nothing, and deletes the tag ref through the API with `GITHUB_TOKEN`; a deletion starts no workflow, which is wanted.
- The guard's new form is `sh tools/pr_tag.sh push CHANGE TITLE` and `wait CHANGE [SECONDS]`, contributor only. The guard's `git push` form stays the merger's branch deletion.
- The workflow stops a run whose package step returned no pull request number instead of starting the merger on none.

## Risks

- A protection rule of the environment `AI` (required reviewers, allowed refs or tags) holds or refuses the job; `wait` times out and the run stops with the reason, and the user reads the Action's log.
- The workflow and script of a branch run with `PR_TOKEN`: a branch could change them. Only the contributor pushes tags, through the guard, and the gates applied are main's.
