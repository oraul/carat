# Design

The constant lives in `Domain::Messages`, which already holds text several use cases and adapters show, and has no requires, so every layer may read it. Adapters read it as `Domain::Messages::NO_NAME` after `require_relative "../domain/messages"`. `ListBuffers` kept it private; reading the shared one needs no `private_constant` entry.

The status bar's styling is already the Facet look (pill groups per mode, `StatusLine` panel bar); this part pins it by frame rows in both themes rather than changing it. A theme's groups are resolved by id, so the row's cell groups are the same in both themes and the per-theme check compares each theme's resolved colors.
