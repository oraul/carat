# Design

## Context

`groom` reads each line of `groom.txt`, splits its kind from the rest, checks the heading stands, judges a security entry, then proves the kind; any `die` before the write loop leaves every file as it was. `backlog_oldest` and `backlog_pick` share `load_groomed`, which marks every whole heading line a `groom.txt` line ends in.

## Decisions

- Refusal, not silence: a `stale` or `closed` line dies at the parse with a message naming the evidence kinds, so a plan written before this change cannot remove entries for their age, and the planner learns what to write instead.
- The reason follows the heading after ` -- `, split at the last occurrence: the heading is the backlog's text, which may hold ` -- `, while the planner writes the reason and can avoid it. A reason of only blanks is no reason. The check runs at the parse, before the heading and security checks, so a reasonless line is named as such.
- The path proof of `gone` stays: a reason is needed in addition, not instead.
- `load_groomed` cuts a `gone ` line at its last ` -- ` before marking headings, so backlog-oldest and backlog-pick still leave out an entry the plan removes.
- `backlog-oldest` is kept at its constant `PRUNE_COUNT` of 50: the guard's read profile and the sprint planner's prompt call it, and its entries remain what the planner checks against HEAD for evidence. Only the whole-backlog switch is removed, with the helpers no other code reaches.
- The old entries `fixed` cannot reach (a fix in an earlier sprint) stay until a `gone` line with a reason, a `duplicate`, or a `merged` one covers them: the user's rule prefers a long backlog to a lost bug.

## Risks

- The backlog grows faster without age pruning; the planner's triage and the evidence kinds are the only way out, by the user's choice.
