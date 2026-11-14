# Tasks

## 1. One digit fit

- [x] 1.1 Add `Frame#put_digits_within` in `carat/domain/frame.rb` and use it in `carat/adapters/status_bar.rb` and `carat/adapters/tab_bar.rb`, removing `digits_within` and `put_number`; prove with `test/domain_frame.rb`, `test/adapters_status_bar.rb`, and `test/adapters_tab_bar.rb` (the counts)

## 2. Tabs

- [x] 2.1 Draw `TabLineSel` as `ON_STRONG` on `BLUE`, bold, in `carat/domain/themes.rb`; prove with `test/domain_theme.rb` (Every palette's selected tab stands out) and `test/adapters_screen_presenter.rb` (the tab groups' SGR)
- [x] 2.2 Draw the selected tab's icon in `TabLineSel` and give the mark one cell in `carat/adapters/tab_bar.rb`; prove with `test/adapters_tab_bar.rb` (Two tabs, one modified; The modified mark keeps the tab's width; The selected tab's icon is in the selected group)

## 3. Winbar

- [x] 3.1 Join the symbols with ` › `, ` > ` under `option.icons ascii`, in `carat/adapters/winbar.rb`, passed from `carat/adapters/frame_presenter.rb`; prove with `test/editor_breadcrumbs.rb` (Inside a method of a class; The ASCII separator; Outside every symbol; A flat symbol answer; A hostile answer is bounded)

## 4. Docs and checks

- [ ] 4.1 Update `README.md` (the winbar example) and `docs/codebase-map.md` (frame, tab bar, winbar, status bar lines); run `make bench SCENARIOS=lh-winbar`, `make gates`, and `make spec-validate`
