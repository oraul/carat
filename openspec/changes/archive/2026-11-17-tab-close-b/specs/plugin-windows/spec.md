## ADDED Requirements

### Requirement: A plugin opens a file as the top row's tab
A plugin SHALL open a file as the tab the top row shows: under `option.gt buffers` in the editing window, as opening a file in that window does, so the file becomes a buffer tab, the window focused, a file already listed showing its tab; under `option.gt tabpages`, or when the tab page has no file window, in a new tab page after the current one.

#### Scenario: Open as a tab under buffer tabs
- **WHEN** the explorer is open beside the file window showing "a.md" and the plugin opens "b.rb" as the row's tab
- **THEN** one tab page remains, the file window shows "b.rb" and is current, and "a.md" stays listed

#### Scenario: Open as a tab under tab pages
- **WHEN** `option.gt tabpages` is set and the plugin opens "b.rb" as the row's tab
- **THEN** a second tab page is current and shows "b.rb"
