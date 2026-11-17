# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 14

1. `lsp-container-c` (T2 user request, estimated medium): part c of `lsp-container` (#171, #174). A `language.NAME.lsp.root` line whose root is relative or holds a `.` or `..` segment is kept without a report and covers nothing (`carat/domain/config.rb:218`), against the README's `file:line: message` promise. Fix outline: one domain check of a root, shared by the gateway and the configuration reader, a failing line reported as not a root. Accepted when a configuration test table shows `src`, `/a/./b`, and `/a/../b` reported with their line and `/a/b` kept. Backlog: "### A language.NAME.lsp.root line whose root is not a root is kept without a report".
2. `markdown-reading-d` (T2 user request, estimated medium, part d of 2): in the reading view an indented code block inside a quote (`>     x = 1`, `>     y = 2`) flows into one quote row and loses its line breaks, the four-space check counting only spaces before the markers (`carat/domain/markdown_text.rb:158`); `flow_key` (`:160`), `marker_end` (`:175`), and `block` (`:632` to `:644`) scan quote markers three ways, so a join can cut a line at another byte than the block that classified it, and the NEST_LIMIT cap at `:176` never runs (indent 0 or 1 after `:165`); headings and framed code blocks, 2 of the user's 4 reading-view parts, are next. Fix outline: one marker scan for the three readers, the dead cap dropped, code blocks kept apart in quotes, headings and framed code blocks drawn. Accepted when `test/domain_markdown_text.rb` rows show a two-line indented block in a quote as two rows, a line mixing spaces and markers cut at one byte by all readers, and a heading and a framed code block each with its style. Backlog: "### MarkdownText flow_key copies block's scan and keeps a dead indent cap", "### An indented code block inside a quote still flows into one quote row", "### marker_end can disagree with the quote-marker scans of flow_key and block".
3. `vim-line-commands-a` (T2 user request, estimated medium, pushed back 2, part a of 2): `:m` and `:t` (`:co`) do not exist (`docs/compatibility.md:384`), so `:g` cannot move or copy lines. Fix outline: two ex commands registered in the order of `docs/compatibility.md`, each with a range and a target address, one undo step each. Accepted when their compatibility rows and a table-driven test show `:2m0`, `:1,3m$`, `:t.`, `:co0`, and `:g/x/m0` as Neovim gives them, `E134` for a move into its own range, `E16` for a bad address, and line 384's sentence updated.

## Pool

1. `vim-line-commands-b`, `vim-folds` (T2 user request, estimated medium each; folds pushed back 3, reason: part a goes first as `:g` needs it): b takes `:j`, `:>`, `:<`, `:normal`, and "## The ex commands a global most often runs besides :s and :d".
2. `markdown-reading-e` (T2 user request, estimated medium): rules and list gaps in the reading view.
3. `git-panel` plugin (T2 user request, estimated large, pushed back 2, split at its start): Unstaged, Staged, Recent; after backlog `git-signs-transport`, which puts git's guards, spelled 3 times (`carat/plugins/git_signs/plugin.rb:27`, `:28`, `:42`), in one place.
4. `ux-pass-2` (T2 user now-request, estimated medium, pushed back 2, reason: no item list recorded beyond its name; drawn once the user names it).
5. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics; `:grep :make :cnext :copen`.
6. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
7. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect, goals 1 and 2 first): `json.rb:72`; `test/lint.rb:255`. Backlog: both "### docs/spinel-notes.md:47:" entries.
8. `plugin-protocol-a`, `formatting` (T5, T5 roadmap 14; estimated medium each, pushed back 2): protocol a takes "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
9. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each, S15).
10. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each, not before S15).
11. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4).
12. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
13. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
14. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, "### An untrusted project .caratrc may bind keys to destructive actions".
15. `insert-copy`, `bench-scenarios` (T4, estimated small each): "### make bench without SCENARIOS skips four scenarios".

## Decisions

- Security first clear (T0): sprint-13 review security Medium (6) `tools/run_state.sh:639`, Lows (4), (4), (3), none at confidence 8, none disputed.
- Sprint 14, 3 features, 2 backlog (T2 sprint rule): `lsp-container-c`, `markdown-reading-d`, `vim-line-commands-a`; `tab-close-b` and `merge-record-check` in the backlog lane.
- `lsp-container-c` first (T2, pool 1): one testable part at `config.rb:218`; estimated medium, not small: no feature row of the last 10 under 736,843 total or 47 min.
- `markdown-reading-d` split (T2): 4 user parts and 3 entries over the split rule's 3; d takes code blocks and headings, `markdown-reading-e` the rest; a 1,035,751, b 817,671, c 1,902,958 total, so medium.
- `vim-line-commands-a` ahead of `git-panel` (T2, pushed back 2, aging): `:m` and `:t` named missing at `compatibility.md:384`; 4 or more commands, so split.
- `ex-global-commands` folded into `vim-line-commands-b` (T5 into T2, same ex commands).
- `git-panel` pushed back 2 (T2): a fourth copy of the git guards (3 at `plugin.rb:27`, `:28`, `:42`) until `git-signs-transport`.
- No size up: lsp-container-b 1,004,078 and palette-narrow 736,843, the last two feature rows, under medium's 1,200,000.
