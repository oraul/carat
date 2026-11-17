## REMOVED Requirements

### Requirement: An unclosed block opener is marked without a language server
**Reason**: The whole-buffer check behind the sign made opening a 100,000-line Ruby file five times slower, and the user asked for the sign's removal.
**Migration**: None; a language server's diagnostics report an unbalanced block.

### Requirement: Openers are counted as Ruby reads them
**Reason**: The opener count existed only for the removed sign.
**Migration**: None.
