# Tasks

## 1. License

- [x] 1.1 Add the root `LICENSE` with the standard MIT License text and `Copyright (c) 2026 The carat authors`. Proven by `make gates` (the forbidden-text scan of the added lines) and `make docs-lint`.
- [x] 1.2 `README.md`: add the `## License` section, carat under the MIT License (see `LICENSE`) and the credit for `tools/spinel/`. Proven by `make docs-lint` and `make gates`.

## 2. Backlog

- [x] 2.1 Append the entry `### make types leaves build/carat.rbs that breaks every later compile` to the end of `docs/backlog.md` with `>>`, with its Location, Why, and Fix lines. Proven by `make docs-lint`.

## 3. Verify

- [x] 3.1 Run `make lint`, `make docs-lint`, `make gates`, and `make spec-validate`.
