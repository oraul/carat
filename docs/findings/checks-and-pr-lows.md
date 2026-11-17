
### checks-and-pr-lows security Low (4): run_state set still writes any note key
- Location: tools/run_state.sh:1675
- Why: the late-finding stamp is public once the run merges and `set` still writes any note.N key, so code running after the merge with write access to build/pipeline (for example the next change's branch code run by a check, if the run-state directory is reachable from there) can forge `set CHANGE note.N "late-finding MERGED text"`, which passes late_findings and lands in docs/findings and then the backlog the planner reads; LATE_TEXT_RE keeps the text to plain characters, 400 at most.
- Fix: make `set` refuse note.* keys so only add_note writes notes, as it already refuses review.*, phase.* and stage.*; optionally record which start wrote each note or check that note keys are numbered in sequence.

### checks-and-pr-lows security Low (3): open_pr wait records a lone matching pull request of unknown origin
- Location: tools/open_pr.sh:135
- Why: if a fork opens a pull request on the pushed commit before open-pr opens ours (a race the attacker has to automate), that fork's number is recorded with nothing earlier to compare it against, and the merger would read and squash-merge a pull request whose title the attacker controls.
- Fix: have open-pr publish the number it opened where wait can read it (the workflow log, a commit status, or an artifact), or have the merger check that the pull request's head repository is this repository before merging.

### checks-and-pr-lows security Low (5): a planted held-finding note is relabeled as a merged-stamped late finding
- Location: .claude/workflows/deliver-change.js:471
- Why: branch code a check runs can call `sh tools/run_state.sh note CHANGE held-finding TEXT`, since add_note accepts any lowercase kind before the merge; on a resume seed reads it back through heldFindings and the merged close records it with `note late-finding`, stamped with the real squash commit, so it passes the history stamp check and lands in docs/findings/CHANGE.md, bypassing the provenance stamp; the text stays within noteText and 400 characters, and a planted quality-advisory reaches the findings file the same way (design.md, Risks, records this tradeoff).
- Fix: keep held findings where branch code cannot write them, for example notes carrying a token the workflow holds (the reviewed HEAD plus a per-start nonce) checked by heldFindings, or add_note refusing held-finding outside the close profile; at minimum have heldFindings keep only texts shaped like a recorded security Low or quality-advisory note.

### checks-and-pr-lows security Low (4): unpushed-finding notes accepted from any run-state writer before the merge
- Location: .claude/workflows/deliver-change.js:515
- Why: branch code a check runs could plant an unpushed-finding note that an unpushed resume's seed hands to the package step, which appends it to docs/findings/CHANGE.md; the text is held to noteText's shell-safe shape and reaches only the reviewed PR diff, the reach design.md line 36 accepts for held-finding and quality-advisory notes, but that accepted-risk paragraph does not name the new kind.
- Fix: add unpushed-finding to the accepted-risk decision in design.md beside held-finding, or have seed accept an unpushed-finding note only when the run state also records a close phase or stop marker written by the workflow at a commit.

### checks-and-pr-lows test gap: the unstamped forged late-finding note is overwritten before it is checked
- Location: tools/tools_test.sh:986
- Why: the unstamped forged note.7 is overwritten by the following `state note history overrun`, numbered by the note count plus one (7), so the without-a-stamp case of late_findings is never exercised.
- Fix: set the forged notes after the overrun note or at numbers above the next note number.

### checks-and-pr-lows correctness: open_pr wait can replace a recorded pull request number
- Location: tools/open_pr.sh:135
- Why: a single number on the pushed head is taken even when the run state already records a different pr, so a later push can overwrite the branch's pull request number with another one, a fork's included.
- Fix: when pr is recorded, accept only that number and keep waiting otherwise.
