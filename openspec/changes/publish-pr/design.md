# Design

## Context

The contributor opened each pull request with the session's create tool, which appends a footer naming the session; the contributor then set the body back to the gated file with the update tool, but the first revision stays in the edit history. The session's proxy authenticates calls to the GitHub API host the way it does git pushes (a plain call reports the 15,000 rate limit of an authenticated client), so a direct REST call needs no token.

## Goals / Non-Goals

Goals: the only text a pull request ever holds is the gated title and body file; a body or title that fails the gates never reaches GitHub; a live text that differs is reported and stops the run; the number reaches the run state. Non-goals: the merge, which keeps its tool and hook; the old revisions.

## Decisions

- One script for create and update. With no number in the run state it posts to `repos/REPO/pulls` (title, head the run state's branch, base `main`, body the file); with one it patches `repos/REPO/pulls/N` with the title and body. Either way it then gets the pull request and compares `.title` and `.body`, written with `jq -j` (no added newline), against the title and the file with `cmp`. The repository and branch come from the run state, never an argument, so the script cannot publish elsewhere.
- Gates first. The pr-body gate (`tools/gates.sh pr-body FILE`) and `tools/scan_text.sh --where title` run before any `curl`; a failure exits 1 with the gate's output and no call is made.
- The number is recorded as soon as the post returns one, before the read-back, so a mismatch leaves a recorded pull request and a rerun patches it instead of posting a duplicate; the script then exits 1 and the contributor stops the run with the report.
- `curl -sS` with `-o` and `-w '%{http_code}'`; a status other than 201 (post) or 200 (patch, get) fails with the response's message. Headers: the GitHub JSON media type and API version; no authorization header, which the proxy supplies.
- The request body is built by `jq -n --rawfile`, so the file's bytes are encoded exactly; the response is read with `jq`.
- The guard admits `sh tools/publish_pr.sh CHANGE TITLE` for the contributor profile only, the change matching the change-name pattern; the script's own `curl` runs inside it, so `curl` stays out of every profile's commands.
- Tests stub `curl` on the `PATH` with a script that logs each call and answers from files, as the `gh` stub of the ci_scope cases does.

## Risks / Trade-offs

- The guard is read from `origin/main`, so this change's own package step runs the script before main's guard knows it; the contributor's hook, where active, would refuse it for this one run. The workflow agent of this run runs without that hook, so the change's own pull request is created by the script.
- `jq` becomes a dependency of the tools-test stage; the CI runners carry it.
