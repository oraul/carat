### light_plus LineNrFifth is the teal accent
- Location: carat/domain/themes.rb:482 (LIGHT_PLUS DIM 0x1f6b82, FAINT gray)
- Why: LineNrFifth maps to DIM, so in light_plus every fifth number is an accent color rather than a dim gray step.
- Fix: map LineNrFifth to a gray in light_plus or record the choice in the design.
### frame_presenter class comment leaves a short line
- Location: carat/adapters/frame_presenter.rb:57
- Why: the rewrapped class comment leaves a line ending in 'column. With' before 'indentguides' on the next line, which reads badly
- Fix: reflow lines 57 to 59 so the sentence 'With indentguides ...' continues the paragraph
