# Spec Delta

## MODIFIED Requirements

### Requirement: Options are set with option lines
The options `number`, `relativenumber`, `expandtab`, `autoindent`, `ignorecase`, `smartcase`, `hlsearch`, `incsearch`, and `wrap` SHALL take `true` or `false`; `tabstop`, `shiftwidth`, `scroll`, `scrolloff`, `timeoutlen`, and `undolevels` SHALL take a number; `clipboard`, `icons`, and `theme` SHALL take one word. A setting no file names SHALL keep Vim's default.

#### Scenario: Shipped options
- **WHEN** the editor starts with the shipped defaults
- **THEN** tabstop is 2, timeoutlen is 500, scroll is 0, and line numbers are shown

#### Scenario: timeoutlen from a line
- **WHEN** the project file holds "option.timeoutlen 100"
- **THEN** an ambiguous key prefix waits 100 milliseconds

#### Scenario: scroll from a line
- **WHEN** the project file holds "option.scroll 4"
- **THEN** `<C-d>` scrolls by 4 lines
