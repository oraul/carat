# Backlog: openspec/specs/config-files/spec.md

### openspec/specs/config-files/spec.md:27 quoting scenario uses a refused formatter key (quality, spec drift)

- Where: openspec/specs/config-files/spec.md:27, scenario A quoted word, and its row at test/domain_rc_parser.rb:42.
- Why: the scenario still uses a language.ruby.formatter line, which Config now refuses as not supported yet, so the main spec illustrates quoting with a setting it rejects.
- Fix: add a MODIFIED scenario to a delta spec using a still-read key such as language.ruby.lsp ruby-lsp "--config my file.yml", and change the matching row at test/domain_rc_parser.rb:42.
- Also: test/domain_rc_parser.rb
- Category: pipeline
- Added: 2026-11-15

### The unsupported language setting scenario names a file its test does not parse

- Location: openspec/specs/config-files/spec.md:233 (scenario "A language setting not supported yet") against test/domain_rc_parser.rb:100. Sprint-6 review, quality advisory. Queue item `tools-docs-tidy`.
- Why: the scenario expects the user file's label while the test parses a trusted `.caratrc` and checks `.caratrc:1`, so the scenario is not proven as written.
- Fix outline: give the test the user file's label, or word the scenario by the trusted file.
- Also: test/domain_rc_parser.rb
- Category: pipeline
- Added: 2026-11-15
