# Design

## Context

`contributor(mode, detail)` loops over starts; on `done` it sets `head = result.head` with no check. `escalate(why)` moves later contributor starts to the session's model once a run. The workflow has no shell: everything it knows of git comes from a start.

## Decisions

- `HEAD12 = /^[0-9a-f]{12}$/` is the form of `git rev-parse --short=12 HEAD`; `headProblem(reported, lane)` returns the refusal reason, empty when the head is well formed and equals the lane's (or the lane's is unread).
- `laneHead()` runs one start through `recordStart(command, label)`, the record-profile start `flush` also uses (its prompt and `RECORDED` schema), on `git -C tmp/.lane-<change> rev-parse --short=12 HEAD`, from the repository root, and returns its output only when it is in `HEAD12` form, else ''; an unread head is a report note and a queued closable `note <change> head-unread "contributor <mode> start <n>: lane head not read"`, so a reader that always fails shows in the run state.
- On a refusal: `escalate('a refused head')`, a report note, a queued `note <change> head-refused "..."` (closable, so the closing start records it), then one restart with the reason in its prompt; a second refusal stops the run with the reason.
- The reported head reaches the queued line only through `safeText` (letters, digits, `.`, `_`, `-`, at most 40), so it can hold no quote or shell character.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

One more small start per done contributor result (the record profile, cap 3). A reader that fails leaves the old behavior, noted `head-unread`, and the check still compares its commit with the head.
