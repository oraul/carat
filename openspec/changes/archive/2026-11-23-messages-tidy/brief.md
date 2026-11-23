# Brief

CHANGE: messages-tidy   LANE: backlog   BRANCH: chore/messages-tidy   BASE: a985364c9d6b
WHERE: `carat/domain/editor_state.rb:135` show (the `/pattern` echo of `n N * #`), `:42`, `:20`; `carat/domain/notices.rb:76`; `carat/use_cases/handle_key.rb:201`; `carat/domain/message_history.rb:8`, `:29`.
WHY: search echoes fill `:messages`; the two-line unsaved-buffer refusal is dropped from it; the history is built inside EditorState, cleared twice, and keeps levels only tests read.
OUTCOME: echoes stay out of the history, the refusal is kept whole, the history is built once in the assembly with one clear and no unread member. Covers the backlog entries: "## Search echoes fill the message history", "## The message history is built inside EditorState, not the assembly", "## The message history name and a doubled clear", "## MessageHistory stores levels nothing outside the tests reads", "## :messages drops the two-line unsaved-buffer refusal".
ACCEPTED WHEN: an editor test row where `n` echoes and `:messages` lacks it, and one where `:q` is refused and `:messages` shows both lines, fail before.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME
USER DECISIONS: none
RULES: no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/messages-tidy.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra.
