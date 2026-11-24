# Backlog: carat/domain/registry_source.rb

### RegistrySource walks the plugin entry lines twice

- Location: carat/domain/registry_source.rb:27 and :40. Sprint-6 sweep, quality advisory. Queue item `plugin-host-tidy`.
- Why: duplication: `column` and `names` repeat the same walk.
- Fix outline: one private entries reader both map.
- Category: editor
- Added: 2026-11-15

### the generated headers (here and in carat/domain/registry_source.rb:199, and so in at bin/carat-gen-config.rb:32 (sprint-32 sweep quality, note 56)
- Location: bin/carat-gen-config.rb:32
- Why: the generated headers (here and in carat/domain/registry_source.rb:199, and so in default_config.rb and plugins/registry.rb) say run: spin run carat-gen-config, but CLAUDE.md requires make gen-config, which also checks the Spinel warnings
- Fix: write run: make gen-config in both and regenerate
- Category: quality
