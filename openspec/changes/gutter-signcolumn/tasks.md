## 1. Sign column

- [x] 1.1 Set `Window::SIGN_WIDTH` to 1 and say one cell in `Window#gutter_width`'s comment (`carat/domain/window.rb`), and say one cell in `FramePresenter#paint_row`'s comment (`carat/adapters/frame_presenter.rb`), proven by the sign column rows of `test/adapters_frame_presenter.rb` (scenarios "One sign", "No signs", "The sign column is one cell")
- [x] 1.2 Update the frame rows that show a sign in other tests (the sign colors rows and the scratch window's sign in `test/adapters_frame_presenter.rb`, and any row of the git signs, language server, and plugin tests), proven by `make test`

## 2. Docs

- [x] 2.1 Say the sign column is one cell in README.md (the language server paragraph), `docs/compatibility.md` (beside the sign colors) and in the `FramePresenter` entry of `docs/architecture.md`, checked by `make docs-lint`

## Workflow follow-up

- Archive with `openspec archive gutter-signcolumn -y` at packaging.
