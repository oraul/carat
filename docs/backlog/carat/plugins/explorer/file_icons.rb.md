# Backlog: carat/plugins/explorer/file_icons.rb

## The explorer keeps an alias of the file-icon groups

- Where: `GROUPS = Carat::PluginApi::FileIcons::GROUPS` in `carat/plugins/explorer/file_icons.rb` (line 12 at `bars`), and `carat/plugins/explorer/plugin.rb` (line 455) repeating `group_of` as `FileIcons::GROUPS[icon].to_s`. Quality advisory of `bars`.
- Why it matters: an alias kept for one caller and a copy of the API's lookup are two more places to change when the groups do.
- Fix outline: call `PluginApi::FileIcons.group_of` in the explorer, drop the alias, and drop the `Carat::` prefix, which `PluginApi` resolves without.
- Also: carat/plugins/explorer/plugin.rb
- Category: plugins
- Added: 2026-11-05

### comment says the buffer tabs share the file-icon table, but at carat/plugins/explorer/file_icons.rb:9 (sprint-32 sweep quality, note 38)
- Location: carat/plugins/explorer/file_icons.rb:9
- Why: comment says the buffer tabs share the file-icon table, but tabs draw no file icon since tab-name-parent (tab_bar.rb header, plugin_api.rb:422)
- Fix: drop that clause
- Category: quality
