# Backlog: carat/domain/terminal_background.rb

### carat/domain/terminal_background.rb:116: hex_value repeats carat/adapters/json_rpc_language_gateway.rb:861 hex_value and the digit decoding inside (sprint-22 sweep quality)

- Location: `carat/domain/terminal_background.rb:116`
- Why: hex_value repeats carat/adapters/json_rpc_language_gateway.rb:861 hex_value and the digit decoding inside carat/domain/json.rb:309 read_hex4: three copies of one hex-digit decoder
- Fix: keep one public domain helper and call it from all three
- Also: carat/adapters/json_rpc_language_gateway.rb, carat/domain/json.rb
- Category: editor
- Added: 2026-11-20
