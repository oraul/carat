# Backlog: carat/domain/options.rb

## The background option's values are bare literals

- Where: `Options#initialize` in `carat/domain/options.rb` (line 45 at `theme-tokens`), `Themes.find` (`"theme"`), and `BACKGROUNDS` in `carat/domain/themes.rb`, while the theme's default is `Themes::DEFAULT`.
- Why it matters: the default and the painted value are spelled in three places, so renaming or adding a value can leave one behind.
- Fix outline: add `Themes::DEFAULT_BACKGROUND` and a `PAINTED` constant and use them in `Options#initialize` and `Themes.find`.
- Also: carat/domain/themes.rb
- Category: editor
- Added: 2026-11-05

## Two shipped options are accepted and dropped, and Config settings are untyped

- Where: `carat/domain/options.rb:78` (`option.wrap`, `option.clipboard`, set at `config/default.caratrc` lines 23 and 26); `carat/domain/config.rb:27`. Periodic quality at ce6abdb; queue item `project-config-guards`, the type in the batches.
- Why it matters: a user's value for either option is dropped with no note; `settings` is `Array[untyped]` though it holds only `RcLine` values.
- Fix outline: note both as not implemented in `apply` or drop them from `KINDS` and the shipped file, with a `test/domain_options_config.rb` row; type `settings` as `Array[RcLine]` or state the compiler's reason.
- Also: config/default.caratrc, carat/domain/config.rb, test/domain_options_config.rb
- Category: editor
- Added: 2026-11-10
