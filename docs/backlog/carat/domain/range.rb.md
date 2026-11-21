# Backlog: carat/domain/range.rb

## Comments that read as changelogs or break the wrap width

- Where: `carat/domain/range.rb` line 3; `carat/use_cases/handle_key.rb` lines 65 and 71 to 72; `carat/domain/editor_state.rb` lines 13 and 15; `carat/domain/highlight.rb` lines 5 to 13; `carat/use_cases/files/open_file.rb` line 20. Periodic quality at e49f63d. Raised again at be4b63a, also handle_key.rb:71, :315, :379.
- Why it matters: ragged or historical comments mislead a reader.
- Fix outline: describe what the class holds now and rewrap each block to its file's width. Queue item: Backlog batches.
- Also: carat/use_cases/handle_key.rb, carat/domain/editor_state.rb, carat/domain/highlight.rb, carat/use_cases/files/open_file.rb
- Category: editor
- Added: 2026-11-10

### Range's comment is stale and its RBS block is missing

- Location: carat/domain/range.rb:4. Sprint-6 sweep, quality. Queue item `input-core-tidy`.
- Why: the comment says only the exclusive charwise kind is used while text objects and Selection build linewise, blockwise, and inclusive ranges, and the record lacks the `# @rbs` instance variable block every other Data record carries.
- Fix outline: rewrite the comment and add the block.
- Category: editor
- Added: 2026-11-15
