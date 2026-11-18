## 1. The default

- [x] 1.1 Set `option.background theme` in `config/default.caratrc`, regenerate `carat/domain/default_config.rb` with `make gen-config`, and default `Options.new`'s background to `theme` (`carat/domain/options.rb`), proven by "The background is painted by default" in `test/editor_screen.rb`, the defaults and "Unknown value" rows in `test/domain_theme.rb`, and `test/config_sync.rb`
- [x] 1.2 Prove a named background and a named theme kept in `test/editor_screen.rb` ("A named background is kept", "A named theme is kept")
- [x] 1.3 Name the terminal's background in a configuration line in the terminal-background checks of `test/adapters_screen_presenter.rb` and `test/smoke_editor.rb` (a user file under a temporary HOME)

## 2. Docs and findings

- [x] 2.1 Update the option.background row of `docs/compatibility.md` and the colors paragraph of README.md, checked by `make docs-lint`
- [x] 2.2 Append the plan's backlog entries to `docs/findings/background-default.md`
