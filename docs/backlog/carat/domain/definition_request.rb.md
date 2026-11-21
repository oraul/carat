# Backlog: carat/domain/definition_request.rb

## DefinitionRequest's OWNER comment names a view it no longer makes

- Where: `carat/domain/definition_request.rb` line 34, the comment on `OWNER`. Quality advisory in `gd-ghost-tab`.
- Why it matters: it still says the owner holds the read-only views of files outside the project, but since `gd-ghost-tab` an outside target opens as a read-only file buffer, so a reader looks for scratch views that no longer exist.
- Fix outline: say the owner holds the scratch buffers of the peek float and the pick list.
- Category: editor
- Added: 2026-11-10
