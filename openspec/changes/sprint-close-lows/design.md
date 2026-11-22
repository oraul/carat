# Design

## Context

`sprint-planning.js` starts the security reviewer once more over the files its first start left at its cap and merges the two results (`mergeSecurity`), keeping only the second start's files that the first also listed, by exact string. The quality reviewer is one start; its `not_reviewed` makes the quality record `partial`. The skeptic is told to return again only the security findings it disputes, while its agent file also asks for what both missed; its notes are recorded as free text and never reach the blocking count. The records change, `sprint-N-records`, is delivered whenever a plan exists and the results were recorded. Every run records each security finding of the reviewer's result as a `note`, and `add_note` dedupes only `quality-advisory`.

## Goals / Non-Goals

Goals: a file left unreviewed is never dropped for its spelling; a capped sprint quality review continues as the security review does; a security finding both reviewers missed is asked for, recorded, and blocks when it would block from the reviewer; no queue is applied past a blocking sprint security finding; a rerun adds no duplicate security note.

Non-goals: the merge path's headings (`merge-path-lows`); disputes resolving a blocking finding; deduplicating quality or overrun notes.

## Decisions

- Path matching by a normalized key with a boundary-suffix match, not a resolved path: the workflow has no file system access, and a reviewer's spellings differ in a leading `./`, quotes, a line suffix, or a worktree or absolute prefix. A suffix match can only keep more files left, so it fails closed. The first start's spelling is kept, so the record and the report name the diff's paths.
- One `reviewContinued(kind, schema, done, merge)` for both reviewers instead of a second copy of the security block; `mergeQuality` concatenates blocking and advisory findings and keeps the files left by `stillLeft`.
- `security_missed` is a structured field of the skeptic's schema (the reviewer's finding shape), so severity and confidence are typed and the blocking rule (`blockingOf`) applies unchanged; the notes stay for quality findings and disputes. The missed findings are recorded with the skeptic's notes, in the same guarded record start, since their text also quotes reviewed code.
- The records gate holds on `blocking` (the reviewer's and the skeptic's missed ones) or a non-empty `security_first`, whichever the planner wrote; the report names the hold and the resume, and `.claude/commands/sprint.md` tells the main session to resume only after the fix merged. Holding rather than delivering keeps the plan waiting, which `review-due` already treats as not due.
- The rerun duplicates are refused in `add_note`, where the `quality-advisory` precedent lives, for kind `security` by its whole text, since a security note carries no leading commit; a disputed note is a different text and still recorded.

## Risks / Trade-offs

- A boundary-suffix match keeps a short first-start name (`x.rb`) left when the second names `lib/x.rb`; that is a partial review recorded, the safe side.
- A sprint whose blocking finding is a false positive the skeptic disputes waits for the planner's call and a manual `/deliver sprint-N-records`; the cost of one resume against applying a queue past a real High.
- A rerun's security finding worded differently is recorded again; only identical texts are one note.
