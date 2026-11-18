# Design

## Context

groom-proof made every removal of `groom` provable: `listed` by the sprint item's bounded heading (`item_lists`), `fixed` by a commit of the sprint's range touching a file the entry names (`touches_entry`), `duplicate` by a repeated heading or a shared location, and a security entry (`SECURITY_MARK`) leaving only by `listed` or `fixed`. Every groom line is checked before anything is written. A near-same note can today only be dropped as a `duplicate` (its own reason lost) or copied by hand into `groomed.md`; an old entry fixed in an earlier sprint cannot leave by `fixed`, which takes only the sprint's range, and an entry whose file is gone has no proof at all.

## Goals / Non-Goals

**Goals:**

- A near-same note merges into its entry by a groom line, groom copying its lines so both reasons and locations stay.
- An old entry closes with evidence: a fixing commit after the entry, or every path it names gone at HEAD; a security entry only by its fixing commit.
- The planner gets the oldest 50 entries by a command, checks them against the head, and writes the lines.

**Non-Goals:**

- Batches of up to 20 small entries and fix-on-touch entries (parts b and c, queued).
- Changing `listed`, `fixed`, `duplicate`, or `backlog-pick`.

## Decisions

- `merged KEPT <= NEAR-SAME`: two headings on one line split at the first ` <= `; a heading holding that text fails the heading check, so no wrong split passes. Groom copies the merge itself (rather than the planner writing `groomed.md`) so nothing depends on the model copying text faithfully. The copied lines go after the kept entry's last non-blank line, before its trailing blank lines, under the first occurrence of a repeated kept heading. A kept heading that another line removes is refused, which also refuses chains (A into B, B into C), since a removed entry would take the merged text with it. A security entry merges only into another security entry, so a severity never ends up under a heading groom's guard and the planner's ranking would read as a plain note.
- `closed COMMIT HEADING` keeps `fixed`'s `touches_entry` proof and replaces the sprint range with the entry's age: `entry_added` finds the oldest commit whose diff changes the count of the heading line in the backlog or the findings directory (`git log -S`), and the fixing commit must descend from it and differ from it. An entry no commit added yet (a findings file not committed) cannot be closed. A commit that adds the finding and touches the file at once is not after it, so it proves nothing.
- `gone HEADING` reads the paths `touches_entry` reads (heading and `Location`/`Where` lines, else the whole entry), with a leading `./`, a `:line`, and closing punctuation dropped. A token counts only when the history ever held it as a path (`git log -1 -- PATH`), so an identifier such as `Buffer.insert` never counts; every counted path must be absent at HEAD and at least one must count. "Location changed" is the `closed` line's commit, so no third proof is invented.
- `backlog-oldest FILE...` takes its files as `backlog-pick` does, never reading the backlog on its own, and counts an entry as `backlog-pick` would see one: a `##` or `###` heading with a path:line in it or a `- Location:` or `- Where:` line. The oldest are the first in file order, since the backlog is only appended and `groom` folds the findings files after it.

## Risks / Trade-offs

- [`git log -S` per `closed` line costs a history walk] At most about 50 lines a sprint over two paths; acceptable for a once-a-sprint step.
- [The same oldest 50 are checked every sprint while they stay valid] The brief asks for the oldest 50; entries still open stay at the front until fixed, which is what the curator should look at.
- [A merged entry grows] Its reasons and locations are kept on purpose; the user asked never to drop a review's reason.
