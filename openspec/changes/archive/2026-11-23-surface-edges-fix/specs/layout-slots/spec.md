## MODIFIED Requirements

### Requirement: A slot's header lists its views
Each slot window SHALL show a header row at its top listing, in the order they opened, the titles of the views opened in the slot since its window was placed, the shown view in the selected tab highlight and the others in the tab highlight; the view's text SHALL start on the row below the header. The left sidebar is the exception of the requirement "The left sidebar is headed by the project and branch".

#### Scenario: Header of one view
- **WHEN** a plugin's view opens in the right slot
- **THEN** the first row of the right window reads its title in the selected tab highlight and the view's text starts on the second row

#### Scenario: Header of two views
- **WHEN** views "list" and then "other" open in the left slot
- **THEN** the header reads " list  other ", "other" in the selected tab highlight

## ADDED Requirements

### Requirement: The left sidebar is headed by the project and branch
The left sidebar's first row SHALL read the project and branch (requirement "The sidebar's head reads the project and branch" of the buffer tabs) in place of a title while it holds one view and no tab row shows. While it holds one view and a tab row shows, the sidebar SHALL have no header row: the tab row reads the head over it and the view's text starts on the row under the tab row. From two views it SHALL keep its header row listing them.

#### Scenario: A one-view left sidebar reads the head
- **WHEN** the explorer opens in the left slot with no tab row, and again with two files listed
- **THEN** the first row of the left window reads the project in the sidebar's layer and the tree starts on the second row, and with the tab row the tree starts on the first row under it, the tab row reading the head

#### Scenario: The head over the header of two views
- **WHEN** views "list" and then "other" open in the left slot with two files listed
- **THEN** the tab row reads the head, the row under it reads " list  other ", and the window starts below that
