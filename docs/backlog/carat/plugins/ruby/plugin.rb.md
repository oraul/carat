# Backlog: carat/plugins/ruby/plugin.rb

### The ruby plugin copies Filetype's tables and misses shebang files

- Location: carat/plugins/ruby/plugin.rb:24, carat/domain/filetype.rb:8 (sweep, quality).
- Why: EXTENSIONS and NAMES copy the domain's; a Ruby script found by its shebang or :set ft=ruby never gets the structure check's sign.
- Fix outline: carry the buffer's filetype in PluginApi::Event (minor API bump), drop the copies, add a shebang case.
- Also: carat/domain/filetype.rb
- Category: plugins
- Added: 2026-11-17
