# Brief

CHANGE: render-text-lows   LANE: backlog   BRANCH: bugfix/render-text-lows   BASE: ce04c85875d8
WHERE: `carat/adapters/line_painter.rb:48` (format, bidirectional, and zero-width code points painted raw); `carat/domain/display_width.rb:49` code_of.
WHY: a file's U+202E reorders the terminal's row and U+200B hides text (Low (6) at sprint-22, Low (3) at sprint-30); decoding sits in the width table. NO_NAME (one copy), of_char, and icon_group are already gone at 6f0ecc3.
OUTCOME: such code points show as visible markers in file text; one decoder; the three gone entries closed. Covers the backlog entries: "### bidirectional marks and zero-width code points in a file at carat/adapters/line_painter.rb:48 (sprint-30 sweep security Low (3), note 3)", "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))", "## code_of decodes UTF-8 inside DisplayWidth", "## The [No Name] text is defined in both bars", "## TabBar#icon_group scans every group name on each frame", "## DisplayWidth.of_char has no caller".
ACCEPTED WHEN: an `adapters_frame_presenter` test row painting U+202E and U+200B fails before.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME
USER DECISIONS: none
RULES: no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/render-text-lows.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra.
