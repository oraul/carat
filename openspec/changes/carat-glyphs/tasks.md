# Tasks

## 1. The unicode default

- [ ] 1.1 Change the default set to `unicode` in `config/default.caratrc` (regenerate `carat/domain/default_config.rb` with `make gen-config`), `carat/domain/options.rb` (the constructor), and `carat/domain/icons.rb` (the unknown-set fallback); prove with `test/domain_icons.rb` (Default set; Nerd stays selectable; Invalid value) and `test/domain_options_config.rb`, and `make check-stage S=config-current`
- [ ] 1.2 Add the table-driven one-cell test over the default set in `test/domain_icons.rb` (Every default glyph is one cell outside the private use areas)
- [ ] 1.3 Update the tests that pinned a nerd glyph under the default configuration to the unicode glyph, and their snapshots with `make snapshots`; prove with `make test`

## 2. ASCII separators and progress bar

- [ ] 2.1 Draw the window separators as `|` and `-` under `option.icons ascii` in `carat/adapters/frame_presenter.rb`; prove with `test/adapters_frame_presenter.rb` (ASCII separators)
- [ ] 2.2 Draw the progress bar as `#` and `-` under `option.icons ascii` in `carat/adapters/status_bar.rb`; prove with `test/adapters_status_bar.rb` (An ascii bar)
- [ ] 2.3 Add the ASCII frame test to `test/adapters_frame_presenter.rb` (No byte above 127 in an ascii frame)

## 3. Docs and checks

- [ ] 3.1 Update `README.md` (the icons section), `docs/plugins.md` (the default set), the comments of `config/default.caratrc`, and `docs/codebase-map.md` where it names the glyphs; run `make docs-lint`
- [ ] 3.2 Run `make gates` and `make spec-validate`
