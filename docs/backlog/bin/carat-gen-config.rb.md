# Backlog: bin/carat-gen-config.rb

## The generated config header names spin run, and the write step is copied

- Where: `bin/carat-gen-config.rb` line 39 (the header written into `carat/domain/default_config.rb` line 2) and line 48, copied for the registry at line 57, at c1b3a12 (periodic quality). Queued in item 46, generators.
- Why it matters: the header sends readers to a command CLAUDE.md forbids, and the write-only-when-changed block has two copies.
- Fix outline: name make gen-config and regenerate; one write-if-changed helper for both targets.
- Merged: ### gen-config repeats its write-if-changed block
- Location: bin/carat-gen-config.rb:87 and :96 (sprint-4 sweep, quality advisory).
- Why: the block is written twice.
- Fix: one write_if_changed(path, text, summary).
- Merged: ### Generated config headers tell the reader to run spin directly
- Location: bin/carat-gen-config.rb:32; the headers of carat/domain/default_config.rb:2 and carat/plugins/registry.rb:2 (through carat/domain/registry_source.rb:57); docs/architecture.md:222. Sprint-6 sweep, quality. Queue item `tools-docs-tidy`.
- Why: `make gen-config` is the one documented way, with tools/noruby first on the PATH.
- Fix outline: say make gen-config in both renderers and the architecture, then regenerate.
- Also: carat/domain/default_config.rb, CLAUDE.md, carat/plugins/registry.rb, carat/domain/registry_source.rb, docs/architecture.md
- Category: editor
- Added: 2026-11-09

### The generated config header says spin run carat-gen-config

- Location: bin/carat-gen-config.rb:118, carat/domain/default_config.rb:2, docs/architecture.md:222 (sweep, quality).
- Why: spin run skips the Spinel-warnings check make gen-config adds, against the CLAUDE.md Commands rule.
- Fix outline: say make gen-config in all three.
- Also: carat/domain/default_config.rb, docs/architecture.md, CLAUDE.md
- Category: editor
- Added: 2026-11-17

### carat-gen-config writes a spin run header (sprint-16 sweep quality)

- Location: bin/carat-gen-config.rb:32, the header of carat/domain/default_config.rb.
- Why: it says to run spin run carat-gen-config where CLAUDE.md allows only make gen-config.
- Fix outline: write make gen-config in the header and regenerate.
- Also: carat/domain/default_config.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-18

### The generated header of default_config.rb (sprint-20 sweep quality, carat-gen-config.rb:32)

- Location: `bin/carat-gen-config.rb:32`
- Why: the generated header of default_config.rb (and registry_source.rb:57 for registry.rb) says to run spin run carat-gen-config, while CLAUDE.md and the map name make gen-config, the one way
- Fix: write make gen-config in both headers and regenerate
- Also: CLAUDE.md
- Category: editor
- Added: 2026-11-19
