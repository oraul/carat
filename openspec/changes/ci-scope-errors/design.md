# Design

## Context

`tools/ci_scope.sh` decides `run=true|false` for CI's spin job. Its push branch asks `gh api` for the pull request of the pushed commit (head sha, number), the head's tree sha, and the count of successful spin runs on the head; its pull request branch asks for the pull request's commit shas and, per candidate, the count of successful spin runs. Each call keeps stdout only (`2>/dev/null`, `|| true` or `|| echo 0`), so a failed call whose body reaches stdout leaves that body in the variable. Only the pull request branch validated its answers (hex per sha line, digits per count). In run 246 the number query answered a 5xx body that `answer` wrote into `GITHUB_OUTPUT`, and the step failed.

## Goals / Non-Goals

Goals: no gh answer is used unless it is the kind of value asked for; an unknown answer runs the checks; `GITHUB_OUTPUT` always holds one `run=` and one `reason=` line.

Non-goals: changing which paths count as documentation, the lookups, or the workflow.

## Decisions

- Two small filters, `digits` and `hex`, print their argument when it is non-empty and made only of digits or of lowercase hex digits, and nothing otherwise (a `case` pattern, so a line break fails the match). Every gh answer goes through one at the assignment: `head`, `head_tree`, and each listed sha through `hex`; `number` and both `passed` counts through `digits`. An empty result is the unknown answer the code already handled for a failed call.
- The push skip needs all four answers: `head`, `number`, and `head_tree` non-empty and `passed` above zero. Before, an empty `number` still allowed the skip; both answers come from the same endpoint, so requiring it changes nothing when the API answers, and an error body in it now runs the checks as the header promises.
- `answer` flattens its reason with `tr '\r\n' '  '` and writes it to `GITHUB_OUTPUT` and stdout with `printf '%s'`, never `echo`: CI runs the script with dash, whose `echo` expands backslash escapes, and git quotes a path holding a line break as `"x\ny"`, which `echo` would turn back into a line break. The run value is always the literal `true` or `false` from the callers.
- The test stub is a second `gh` in its own directory that prints the error body and exits 1 for queries matching `FAKE_FAIL`, and hands every other query to the existing stub, so the cases reuse the push fixture's tree and pass count.

## Risks / Trade-offs

- An uppercase sha would now be refused and run the checks; GitHub answers lowercase shas, and the pull request branch already refused uppercase.
- Flattening hides a line break the reason might carry; the reason is a log line, and the run value decides the job.
