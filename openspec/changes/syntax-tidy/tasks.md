# Tasks

## 1. Ruby nesting

- [x] 1.1 `carat/plugins/ruby/tokenizer.rb` counts paired delimiters and interpolation braces in full within a line and clamps them in `frame_bits`; the `carat/plugins/ruby/line_state.rb` header says so (proved by "nesting deeper than the state holds", "braces nested deep in interpolation", and "a depth past seven is held to seven across lines" in `test/plugins_ruby.rb`; the first two fail with the caps restored)

## 2. Filetype indexes and the one basename

- [x] 2.1 `carat/domain/filetype.rb` `program_name` cuts the version by bytes and `program_type` uses it (proved by the program-name table of `test/domain_filetype.rb`, whose two multi-byte rows fail with character indexes)
- [x] 2.2 `carat/domain/filetype.rb` cuts names with `PluginApi::Paths.basename`, `Filetype.base` removed, and `carat/domain/buffer.rb` `name_start` agrees with it on the root (proved by the existing rows of `test/domain_filetype.rb` and by "the name starts at the byte Paths.basename cuts, after a multi-byte directory, and at 0 for the root" in `test/domain_buffer.rb`, which fails before for the root)

## 3. Docs and records

- [x] 3.1 `docs/codebase-map.md` area 14 names `program_type`, `program_name`, and the clamp at packing (proved by `make lint` and `make docs-lint`)
- [x] 3.2 `docs/findings/syntax-tidy.md` records the two split-off headings (proved by `make gates`)
