# Brief

CHANGE: explorer-rows   LANE: feature   BRANCH: feature/explorer-rows   BASE: 6f0ecc34bd9d
WHERE: `carat/plugins/explorer/tree.rb:114` (the root row naming the project, which `carat/adapters/tab_bar.rb:130` now heads the column with), `tree.rb:171` (the current file's one-cell mark).
WHY: the user's first feature of Sprint 32; the tree spends its first row repeating the head, and its current row differs from `docs/design.md:136` (full-width highlight, sapphire bar).
OUTCOME: the tree starts at the root's entries, and the current row reads as `docs/design.md:136` says. Covers the backlog entries: none.
ACCEPTED WHEN: `editor_explorer` test rows for the tree's first row and its current row fail before.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME
USER DECISIONS: none
RULES: no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/explorer-rows.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra.
