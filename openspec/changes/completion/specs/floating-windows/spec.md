## ADDED Requirements

### Requirement: A float reopened at the same box shows its own text
A float closed and replaced by another float at the same box, both showing buffers with no edits, SHALL be drawn with the new float's text, so the screen equals a full repaint.

#### Scenario: Reopened at one box
- **WHEN** a float showing "one" is closed and a float showing "two" opens at the same box, after two redraws
- **THEN** the box shows "two" and the screen equals a full repaint
