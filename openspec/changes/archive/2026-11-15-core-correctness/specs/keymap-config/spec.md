# Spec Delta

## ADDED Requirements

### Requirement: Unbinding with none leaves no empty prefix
A `none` line SHALL remove the binding of its keys and leave no prefix that leads to no binding, so the shorter keys keep their own binding and dispatch at once; keys that were never bound SHALL stay unbound, and longer bindings that begin with the unbound keys SHALL stay.

#### Scenario: A two-key none unbinding leaves no prefix
- **WHEN** the configuration binds "x" in normal mode, then has the line "keymap.normal xy none"
- **THEN** "x" matches its own binding and is not a prefix, and "xy" is unbound

#### Scenario: A none unbinding keeps the longer bindings
- **WHEN** the configuration binds "xyz" in normal mode, then has the line "keymap.normal xy none"
- **THEN** "xy" is a prefix and "xyz" still matches

### Requirement: A binding resolved by timeoutlen is followed as a typed key
When timeoutlen resolves the pending keys, the editor SHALL follow the result as it follows a typed key: the completion menu, the documentation float, the definition float, the signature help, the palette, and a plugin prompt each update or close as they would after the same action typed in full.

#### Scenario: A timeoutlen binding closes the hover
- **WHEN** the documentation float shows, a binding that moves the cursor is also a prefix of a longer binding, its keys are typed, and timeoutlen passes
- **THEN** the cursor moves and the documentation float is closed
