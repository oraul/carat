# Design

## Context

The repository has no license. The user chose MIT. The scout pack of the build-and-ci area at d180d78 found that no check requires a new root file in `docs/codebase-map.md` (`test/lint.rb` `MAP_ROOTS` and `map_files` cover `carat.rb` and `carat/`, `bin/`, `test/`, `bench/`, `tools/`; `tools/gates.sh` `gate_docs` the same paths), that `tools/docs_lint.sh` `check_paths` checks only backticked paths under its prefix list, and that the MIT text holds nothing the forbidden-text patterns of `tools/rules.sh` match.

## Decisions

- The `LICENSE` text is the standard MIT License, word for word, with the copyright line `Copyright (c) 2026 The carat authors`. A collective holder names no person and needs no address.
- The README gets a `## License` section as its last section: one sentence for carat's license and one for the Spinel-derived files in `tools/spinel/`. A credit line is enough for the generated header; the generator is carat's own, modeled on Spinel's.
- The map stays as it is: no check requires the root file, and the brief adds it only if one does.
- The backlog entry is appended with `>>` exactly as the brief gives it, without reading the file.

## Risks

- The scanner of forbidden text was only read, not run, by the scout: `make gates` runs it over the added lines before the push.
