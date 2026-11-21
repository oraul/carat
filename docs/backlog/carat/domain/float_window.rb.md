# Backlog: carat/domain/float_window.rb

### Quality advisory: text_room border parameter is always true (carat/domain/float_window.rb:46)

- Location: carat/domain/float_window.rb:46
- Why: speculative generality; text_room's border parameter is true at every production caller (palette, hover, signature, definition, key hints), only the test passes false.
- Fix: drop the parameter, text_room(cols, style), or pass the spec's border from the caller.
- Category: editor
- Added: 2026-11-14

### Quality advisory: place computes frame_width twice (carat/domain/float_window.rb:80)

- Location: carat/domain/float_window.rb:80
- Why: place computes FloatWindow.frame_width(edge) twice beside side = edge + PAD.
- Fix: compute frame = FloatWindow.frame_width(edge) once and use it for the width cut and the shift.
- Category: editor
- Added: 2026-11-14

## menu-hints quality advisory at carat/domain/float_window.rb:16

Location: `carat/domain/float_window.rb:16`. Why: docs currency; the `centered` member's comment names the palette as the centered float, and the key hints panel now sets `centered` too. Fix outline: name the palette and the key hints.
- Category: editor
- Added: 2026-11-14

## Cursor-anchored floats lose two columns to the centered-float margin

- Where: `text_room` in `carat/domain/float_window.rb:54`, called by `ShowHover`, `ShowSignature`, and `OpenDefinitionFloat`. Sprint-3 quality review.
- Why it matters: `text_room` always subtracts twice the margin, but cursor-anchored floats get no margin from `place`, so they come out two columns narrower than the screen allows, against the comment "Every float sized to the screen asks this".
- Fix outline: size by the float's anchor, or document that cursor floats give up the two columns, with a hover row at the screen's width. Queue item `hover-tidy`.
- Category: editor
- Added: 2026-11-14
