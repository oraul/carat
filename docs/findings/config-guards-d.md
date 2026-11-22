### make types leaves a signature file that breaks the next compile
- Location: Makefile:414 (`types` writes `$(TYPES_RBS)`, build/carat.rbs)
- Why: after `make types`, `make test-one` fails with "spinel_rbs_extract: parse failed in build/carat.rbs, expected a token pCOLON" and refuses to compile, since the `--rbs` scan of the project directory reads the emitted file, whose class names such as `Carat::::Domain::::Range` do not parse; a contributor who inspects the inferred types must delete the file by hand before any build.
- Fix: write the types output outside the scanned tree (under tmp/.types or a hidden build directory the `--rbs` scan skips), or delete it at the end of the `types` recipe after printing it.
