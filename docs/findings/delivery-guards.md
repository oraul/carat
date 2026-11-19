### The squash body of #223 claims styling its diff lacks
- Location: the squash commit of cursor-and-messages (#223): its Summary and Changes bullets 4 to 6
- Why: they claim command-line and message styling that the diff does not contain, so the history on main says something untrue.
- Fix: make it true with the message-styling change, which delivers that styling.

### The pull request text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js (prTextReview call after the package step)
- Why: it runs only in the start that packages, so a resume after the push never reviews the text; no verdict of it is recorded
- Fix: record the review's verdict (a phase or a note the run state returns) and run it on resume when none is recorded
