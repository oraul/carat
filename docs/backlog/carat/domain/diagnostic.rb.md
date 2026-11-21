# Backlog: carat/domain/diagnostic.rb

## The diagnostic severities are mapped in five files

- Where: `carat/domain/diagnostic.rb` (line 8 at fb09c6b) holds the LSP severity numbers 1 to 4, while their meaning is spread over the icon names in `JsonRpcLanguageGateway#apply` (`carat/adapters/json_rpc_language_gateway.rb` line 443), `glyphs[severity - 1]` in `Buffer#set_diagnostics` (`carat/domain/buffer.rb` line 304), `FramePresenter.diagnostic_group` (`carat/adapters/frame_presenter.rb` line 956), the four `paint_count` calls and the group chain of `StatusBar` (`carat/adapters/status_bar.rb` lines 228 to 231 and 281 to 284), and the counts index of `StatusSlots#count_diagnostics`. Periodic quality at fb09c6b.
- Why it matters: a fifth severity or a reordered icon set must be changed in each of the five places, and nothing fails when one is missed.
- Fix outline: named severity constants on `Diagnostic` and one domain table of icon name and highlight group by severity, read by the gateway, the buffer, the presenter, and the bar. Queued in `diagnostics-tidy`.
- Also: carat/adapters/json_rpc_language_gateway.rb, carat/domain/buffer.rb, carat/adapters/frame_presenter.rb, carat/adapters/status_bar.rb
- Category: ide
- Added: 2026-11-07
