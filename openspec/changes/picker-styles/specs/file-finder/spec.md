## ADDED Requirements

### Requirement: The finder keeps its floats across keys
While the finder is open and its boxes keep their size, every key that changes the typed text or moves the highlight SHALL show the new rows and title in the same list float, and the new preview in the same preview float while a preview shows; the preview float SHALL close when no preview shows and open again when one does, and a resize that changes a box SHALL open that float again at its new box.

#### Scenario: Typing keeps the list float
- **WHEN** the finder is open on an 80-column screen and the user types `bet` and three backspaces
- **THEN** the tab page holds one float, the list float the finder opened with, titled `Files 3/3`

#### Scenario: Moving the highlight keeps both floats
- **WHEN** the finder is open on a 120-column screen and the user presses `<C-n>`
- **THEN** the list and the preview are the floats the finder opened with, the preview titled `lib/alpha.rb`

#### Scenario: The preview closes and returns
- **WHEN** on a 120-column screen the user types `zzz`, then three backspaces
- **THEN** after `zzz` only the list float shows, and after the backspaces the list float is the one the finder opened with and a preview shows again

#### Scenario: A resize opens the floats at the new size
- **WHEN** the finder is open on a 120-column screen and the screen narrows to 80 columns
- **THEN** one list float shows, as wide as the list the finder opens on an 80-column screen
