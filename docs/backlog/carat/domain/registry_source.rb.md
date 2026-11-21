# Backlog: carat/domain/registry_source.rb

### RegistrySource walks the plugin entry lines twice

- Location: carat/domain/registry_source.rb:27 and :40. Sprint-6 sweep, quality advisory. Queue item `plugin-host-tidy`.
- Why: duplication: `column` and `names` repeat the same walk.
- Fix outline: one private entries reader both map.
- Category: editor
- Added: 2026-11-15
