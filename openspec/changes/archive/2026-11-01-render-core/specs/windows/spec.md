## ADDED Requirements

### Requirement: Window geometry is current after every key
After every key, and after a file is opened, every window of the current tab page SHALL have the rectangle the layout gives it in the current terminal size and SHALL be scrolled to keep its cursor visible, whether or not a frame was drawn, so a window command, a split's size, and the screen motions "H", "M", and "L" use the windows as they are after the previous key.

#### Scenario: Two splits with no frame between them
- **WHEN** the editor shows one window with 22 text rows in a 24-row terminal and `<C-w>s<C-w>s` is typed with no frame drawn between the keys
- **THEN** there are three windows of 5, 5, and 10 text rows, the top one current

#### Scenario: Screen motion after a jump with no frame between
- **WHEN** a window of 8 text rows over forty lines with scrolloff 0 is at the top, "30G" is typed and then "H" with no frame drawn between them
- **THEN** the cursor is on line 23, the top line the window shows after the jump
