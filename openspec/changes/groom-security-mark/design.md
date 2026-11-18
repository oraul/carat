# Design

## Context

`groom` reads each line of the sprint plan's `groom.txt` and proves it before writing anything. Its security guard was four copies of `backlog_entry "$heading" | grep -q -i -E "$SECURITY_MARK"`, one in each of the `closed`, `gone`, `merged`, and `duplicate` arms, each matching line by line. Merged entries are collected in `$merges` as `@@kept KEPT`, `- Merged: HEADING`, and the body, and an awk in the rewrite takes any line starting `@@kept ` as the next kept heading.

## Goals / Non-Goals

**Goals:**

- Security in any wording, judged in one place, refusing every removal but `listed`, `fixed`, and a merge into another security entry.
- A merged body that no text inside it can redirect or drop.

**Non-Goals:**

- backlog-pick's ranking, which counts any entry naming security, wider on purpose.
- A change to the proofs of `listed`, `fixed`, `closed`, or `gone`, or to the backlog's format.

## Decisions

- Wording: security (the word, bounded by non-letters) and a severity word (`critical|high|medium|low|disputed`, an `s` allowed) both in the entry, in either order, or a severity and confidence pair `(high|medium|low) (N)`. The entry's lines are joined with spaces first, so a severity on another line than the word counts. Kept from groom-proof: a text naming security without a severity, the quoted "Security first" title the sprint-17 retro entry carries, is not one, so that entry still leaves as a duplicate. Alternative rejected: any entry naming security, as backlog-pick ranks; it would again hold that retro entry, which groom-proof was written to let go.
- One place: `security_entry HEADING` is the only test of `SECURITY_MARK`; `groom` calls it once per line, after the heading is proven to stand and before the kinds' proofs, in one `case` on the kind: `closed|gone|duplicate` die naming the kind, `merged` dies unless `security_entry KEPT`. An unknown kept heading of a security entry is refused there too, by the security message; a plain entry's still reaches the merged arm's own "not a heading line" message.
- Channel: every `$merges` line carries a one-character prefix, `@` before a kept heading and `|` before a line to append (the `- Merged:` line and each body line, through `sed 's/^/|/'`). The awk reads the prefix, never the text, so a body line `@@kept X` is appended as `@@kept X` under its own kept heading.

## Risks / Trade-offs

- Wider guard: an entry naming security and a severity word in an unrelated sense (a "low" risk) cannot be closed, gone, or a duplicate; the planner names it `listed` or `fixed`, or merges it into a security entry, which errs toward keeping it.
- A body line starting with a prefix character is unaffected, since only the first character of each channel line is read as the prefix.
