### The squash trailer repeats the gates' trailer
- Location: tools/agent_guard.sh:964 (SQUASH_TRAILER), tools/gates.sh:78 (TRAILER)
- Why: quality advisory, duplication: two copies of the trailer line that must stay equal, or the merge hook and the gates disagree on the squash message.
- Fix: a tools_test.sh case comparing the two lines, as "the guard's risky keys are the gates'" does for RISKY_CONFIG; this change's head already carries it as "guard: the squash trailer is the gates' trailer", so the grooming may close this entry once it confirms the case on main.

### Two JSON string decoders in the guard
- Location: tools/agent_guard.sh:970 (json_text), tools/agent_guard.sh:153 (field)
- Why: quality advisory, duplication: json_text repeats field's key match, escape loop, and hex decoding, two JSON string decoders to keep in step.
- Fix: have field decode through json_text and apply its folding of newlines and non-ASCII after.

### Two lookups of the archived pr.md
- Location: tools/agent_guard.sh:1027 (merge hook lookup), tools/open_pr.sh:167
- Why: quality advisory, one clear way: the hook finds the archived pr.md by a non-recursive listing and a cat-file check while open_pr.sh still lists the whole archive with ls-tree -r, two lookups of the same file that grow apart.
- Fix: give open_pr.sh the same non-recursive listing of the archive's entries, or share one lookup.
