# Backlog: carat/plugins/hello/plugin.rb

### The hello plugin's opened count is always 1 at activate and misses earlier buffers (plugin-lazy-activate quality)
- Location: carat/plugins/hello/plugin.rb:49
- Why: read_buffer(0) resolves the current buffer, which always exists, so the ternary is a dead branch always giving 1, and buffers opened before the first greeting other than the current one are not counted (":e b.txt" then hh from a.txt reads "1 buffer opened").
- Fix: write "@opened = 1" with a comment saying it counts the current buffer, or count the listed buffers at activate if a host request offers them.
- Category: plugins
- Added: 2026-11-18
