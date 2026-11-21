# Backlog: test/editor_cmdline_complete.rb

### The cmdline completion test comment says labels are joined by a space (sprint-25 review quality)
- Location: `test/editor_cmdline_complete.rb:30`
- Why: the comment of `typed` says the popup's labels are joined by a space, but `popup` (line 50) joins them with `,`.
- Fix: say `,`.
- Category: docs
