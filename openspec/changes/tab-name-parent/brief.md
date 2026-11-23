# Brief

CHANGE: tab-name-parent   LANE: feature   BRANCH: feature/tab-name-parent   BASE: 69e59b6291d3
WHERE: `carat/adapters/tab_bar.rb:185` (the name from `name_start`), `:33` (`FRAME_CELLS` 4), `:233`; `carat/domain/buffer.rb:130`, `:259` (`icon` set on every path change, read by 0 callers since one-accent-tabs).
WHY: two open `x.rb` files show two identical tabs; neighbouring tabs stand 3 blank cells apart against the spec's 2.
OUTCOME: a dim parent folder precedes the name only while two listed files share it; tabs are 2 blank cells apart; the buffer keeps no unread icon. Covers the backlog entries: "### Neighbouring tabs are three cells apart, not two", "### Buffer#icon may be unused after the tab icon is gone".
ACCEPTED WHEN: `adapters_tab_bar` test rows for `a/x.rb` beside `b/x.rb` and for the gap between two tabs fail before.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME
USER DECISIONS: none
RULES: no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/tab-name-parent.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra.
