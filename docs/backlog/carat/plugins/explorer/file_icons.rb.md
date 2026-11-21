# Backlog: carat/plugins/explorer/file_icons.rb

## The explorer keeps an alias of the file-icon groups

- Where: `GROUPS = Carat::PluginApi::FileIcons::GROUPS` in `carat/plugins/explorer/file_icons.rb` (line 12 at `bars`), and `carat/plugins/explorer/plugin.rb` (line 455) repeating `group_of` as `FileIcons::GROUPS[icon].to_s`. Quality advisory of `bars`.
- Why it matters: an alias kept for one caller and a copy of the API's lookup are two more places to change when the groups do.
- Fix outline: call `PluginApi::FileIcons.group_of` in the explorer, drop the alias, and drop the `Carat::` prefix, which `PluginApi` resolves without.
- Also: carat/plugins/explorer/plugin.rb
- Category: plugins
- Added: 2026-11-05
