# Backlog: carat/domain/tab_page.rb

## TabPage#previous? reads the node array directly

- Where: `carat/domain/tab_page.rb` line 103, at 7711421. Periodic quality. Queue item `top-rows`.
- Why it matters: every other walker uses `layout.node_count`.
- Fix outline: use `node_count`.
- Category: editor
- Added: 2026-11-09

## winbar_with? on TabPage reads no tab state

- Location: carat/domain/tab_page.rb:68
- Source: quality advisory, winbar-outline
- Why: winbar_with? reads no TabPage state, the breadcrumbs rule being a function of the mode and a count only, so SplitWindow fetches a tab just to ask it.
- Fix outline: move the rule beside the mode it compares (Options, for example Options#winbars_with?(count)) and keep TabPage#winbar? as the caller passing file_window_count.
- Category: editor
- Added: 2026-11-15
