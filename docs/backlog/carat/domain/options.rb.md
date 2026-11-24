# Backlog: carat/domain/options.rb

## The background option's values are bare literals

- Where: `Options#initialize` in `carat/domain/options.rb` (line 45 at `theme-tokens`), `Themes.find` (`"theme"`), and `BACKGROUNDS` in `carat/domain/themes.rb`, while the theme's default is `Themes::DEFAULT`.
- Why it matters: the default and the painted value are spelled in three places, so renaming or adding a value can leave one behind.
- Fix outline: add `Themes::DEFAULT_BACKGROUND` and a `PAINTED` constant and use them in `Options#initialize` and `Themes.find`.
- Also: carat/domain/themes.rb
- Category: editor
- Added: 2026-11-05

### wrap and clipboard are still accepted and dropped by the configuration
- Location: carat/domain/options.rb (KINDS, assign), the queue entry's backlog heading "Two shipped options are accepted and dropped, and Config settings are untyped"
- Why: set-options split apply into problem and assign but left wrap and clipboard as kinds with no member, so a line setting them is checked and dropped silently, and :set answers E518 for them; the heading's problem is unchanged.
- Fix: either drop the two names from KINDS (a line then reports unknown option) or give them members when a change reads them; config-guards-b in the backlog lane names them.
- Category: editor
- Added: 2026-11-22

### KINDS, problem, assign, and value_of are four parallel lists at carat/domain/options.rb:98 (sprint-26 sweep quality, note 7)

- Location: carat/domain/options.rb:98
- Why: KINDS, problem, assign, and value_of are four parallel lists keyed by option name, so a new option needs four edits that nothing checks against each other (a member missing from value_of answers an empty value to :set)
- Fix: a test that every KINDS name that is a member round-trips through assign and value_of, and rewrap the class comment, whose line 17 breaks mid-paragraph
- Category: editor
- Added: 2026-11-22

### listchar_code scans to the comma by hand at carat/domain/options.rb:234 (sprint-28 sweep quality, note 9)

- Location: carat/domain/options.rb:234, :492
- Why: item_stop already finds byte 44.
- Fix: stop = item_stop(text, at) and loop while at < stop.
- Category: editor
- Added: 2026-11-22

### the class comment grew by insertions and now breaks lines at carat/domain/options.rb:17 (sprint-32 sweep quality, note 58)
- Location: carat/domain/options.rb:17
- Why: the class comment grew by insertions and now breaks lines mid-sentence (line 17 ends in the middle of the undolevels sentence, line 33 ends with winborder is the)
- Fix: rewrap the paragraph
- Category: quality
