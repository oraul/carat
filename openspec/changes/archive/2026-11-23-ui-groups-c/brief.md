# Brief

CHANGE: ui-groups-c   LANE: feature   BRANCH: feature/ui-groups-c   BASE: ce04c85875d8
WHERE: `carat/domain/highlight.rb:166` (ModeMsg and MoreMsg, which no painter draws), `test/adapters_status_bar.rb` (NO_COLOR and 16 colors proven on group ids only).
WHY: 2 groups a theme sets change nothing on screen; the bytes a terminal gets at `TERM=xterm` and under NO_COLOR are untested.
OUTCOME: ModeMsg and MoreMsg are drawn where Neovim draws them or removed; the bars' bytes at 16 colors and NO_COLOR are proven. Covers the backlog entries: "### The visual indicator is dim but ModeMsg and MoreMsg are still unused", "### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes".
ACCEPTED WHEN: a pty smoke case at `TERM=xterm` and NO_COLOR comparing StatusLine and StatusLineDim bytes fails before.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME
USER DECISIONS: none
RULES: no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/ui-groups-c.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra.
