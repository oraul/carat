# Tasks

## 1. The palette table

- [x] 1.1 Add `Themes::PALETTES` in the order of `NAMES`, look names up in it in `find`, and remove `palette` and `canonical` (`carat/domain/themes.rb`); verified by `make test-one T=test/domain_theme.rb`, the "find" and "known?" rows unchanged.
- [x] 1.2 Replace the test's own `PALETTES` with `D::Themes::NAMES`, turn the five contrast tables into loops over the names, and add the row failing when `NAMES` and `PALETTES` differ in length or two names share a palette (`test/domain_theme.rb`); verified by `make test-one T=test/domain_theme.rb` and `make snapshots` with its diff read.

## 2. The cursor line on the terminal's background

- [x] 2.1 In `from_palette`, clear the 256-color BG and FG indexes under the terminal's background, give a lit cell with the terminal's foreground over a palette background the palette's text color at 24 bits and 256 colors, and drop `line_bg16` (`carat/domain/themes.rb`); verified by the cursor-line rows of 2.2.
- [x] 2.2 Check the cursor line on both backgrounds at both depths with `low_contrast` reporting an unpaired cell, a row for the scenario The cursor line on the terminal's background, and a row that every palette's Normal has no 256-color index under the terminal's background (`test/domain_theme.rb`); verified failing before 2.1 and passing after with `make test-one T=test/domain_theme.rb`.

## 3. Wording

- [x] 3.1 Reword the Alias row's comment in `test/domain_theme.rb` as the delta spec words it, add the blank line and the `background?` comment, and wrap `themes.rb`'s comments within the width (`carat/domain/themes.rb`); verified by `make lint` and `make diagnose-one T=carat/domain/themes.rb`.

## 4. Verification

- [ ] 4.1 Run `make gates`, `make spec-validate`, and `make test`; all pass.

## Workflow follow-up

- Archive, apply the planner's queue, and package in the package step.
