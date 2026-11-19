### The squash body of #223 claims styling its diff lacks
- Location: the squash commit of cursor-and-messages (#223): its Summary and Changes bullets 4 to 6
- Why: they claim command-line and message styling that the diff does not contain, so the history on main says something untrue.
- Fix: make it true with the message-styling change, which delivers that styling.

### The pull request text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js (prTextReview call after the package step)
- Why: it runs only in the start that packages, so a resume after the push never reviews the text; no verdict of it is recorded
- Fix: record the review's verdict (a phase or a note the run state returns) and run it on resume when none is recorded
### Text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js:1606 and :1616
- Why: the pull request text review runs only in the start that packages; a resume past the package phase skips it silently (still present, recorded instead of fixed)
- Fix: record the text review's verdict and run it on resume when none is recorded
### Findings gate docs say BASE where the code uses the fork point
- Location: tools/gates.sh:29, :505, :524
- Why: the usage line says headings at BASE, the gate_findings comment mixes the fork point with BASE..HEAD, and the failure message says present at the base, while the code reads the fork point and fork..HEAD
- Fix: say the fork point of BASE and HEAD and fork..HEAD in all three
### Design decision on findings is stale
- Location: openspec/changes/archive/2026-11-19-delivery-guards/design.md:9
- Why: the findings decision still lists headings with git grep at the base, not at the fork point of the base and HEAD
- Fix: say the fork point and that a moved main not yet merged is ignored
### Proposal docs currency
- Location: openspec/changes/archive/2026-11-19-delivery-guards/proposal.md:16 and :19
- Why: it says CLAUDE.md is unchanged at its size budget, but the branch edits its push allowance (CLAUDE.md:41), and line 16 repeats the --pr-text push twice
- Fix: say CLAUDE.md is updated, the push allowance names the text fix push, and drop the repeated clause on line 16
### Message styling claimed by 223 is not in its diff
- Location: the squash body of pull request 223 (cursor-and-messages)
- Why: it claims command-line and message styling that its diff does not contain
- Fix: make it true with the message-styling change
