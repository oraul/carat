# Design

## Context

The explorer's `open_path` sends `t` straight to `host.open_as_tab`, before it looks at the editing window; `l` and `<CR>` look first and, when `editing_window` answers 0, call `open_in_tree_window`, which shows the file in the tree's window and opens the tree again at the edge. The host's `open_as_tab` (`carat/use_cases/plugins/window_requests.rb`) opens a tab page under `option.gt tabpages` and also under `buffers` when no window shows a file, so from a lone tree it leaves a tab page of only the tree. The finder's `open_path` calls `host.open_in_tab` for `<C-t>`, always a tab page.

## Goals / Non-Goals

Goals: no explorer `t` and no finder `<C-t>` leaves a tab page without a file window; the finder's `<C-t>` follows `option.gt` as the explorer's `t` does.

Non-Goals: a host API change; the finder keeping the tree when it opens a pick from a lone tree.

## Decisions

- The explorer checks `editing_window` first for every `how`, `:tab` included: with no file window it calls `open_in_tree_window`, as `l` does, under both option values. A host-side fallback could not reopen the tree at the edge, which is the explorer's own layout, so the decision stays in the plugin.
- The finder takes `editing_window` once: with a file window `<C-t>` asks `open_as_tab`, which already holds the `option.gt` rule; with none it falls to the same `open_file` call as `<CR>`, the current window taking the pick, so it never opens a tab page beside a tab page of plugin windows only.
- The host's `open_as_tab` and its comment are kept: its no-file-window fallback is now never reached by the shipped plugins, and changing a request's contract would need an API version step for no shipped caller.

## Risks / Trade-offs

- A third-party plugin calling `open_as_tab` from a lone sidebar still gets a tab page; `docs/plugins.md` already documents that, and the explorer's pattern is the example to follow.
- Under `option.gt tabpages`, `t` from a lone tree no longer opens a tab page; a tab page there would leave the first holding only the tree, which is the state the flows reject.
