# Tasks

## 1. Palettes

- [x] 1.1 Add `CARAT_DARK` and `CARAT_LIGHT`, make `carat-dark` the default, remove `ALIASES`, and rename `lit16` to `line_bg16` in `carat/domain/themes.rb`; prove with `test/domain_theme.rb` (Default theme, Alias, Unknown theme, Every palette passes, Comments are readable)
- [x] 1.2 Hold cursor-line text to 4.5:1 in `low_contrast` and adjust one_dark, one_light, dark_plus, and light_plus in `carat/domain/themes.rb`; prove with `test/domain_theme.rb` (Every palette passes on the cursor line, Every palette passes in a float, Every palette's selected tab stands out, Every palette's pills pass, Every palette's lsp groups pass)

## 2. Configuration

- [x] 2.1 Ship `option.theme carat-dark` in `config/default.caratrc` and regenerate `carat/domain/default_config.rb` with `make gen-config`; prove with `test/domain_theme.rb` (Default theme) and `test/domain_options_config.rb` (the shipped defaults), and `test/adapters_screen_presenter.rb` (the ruler and the painted Normal)

## 3. Docs and checks

- [x] 3.1 Correct the group comment of `test/domain_theme.rb` and the UI group count in `docs/compatibility.md`, and update `README.md`, `docs/architecture.md`, and `docs/codebase-map.md` for the six palettes; run `make gates` and `make spec-validate`
