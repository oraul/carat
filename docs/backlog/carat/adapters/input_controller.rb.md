# Backlog: carat/adapters/input_controller.rb

## InputController calls handle twice in pump and checks animating? twice in tick

- Where: `pump` in `carat/adapters/input_controller.rb` (line 62 at `start-screen`) calls `handle(state, @decoder.feed(bytes))` in two branches, and `tick` (line 96) checks `animating?`, which `due?` checks again. Quality review of `start-screen`.
- Why it matters: the duplicated call and guard are more code to keep in step on the per-key path.
- Fix outline: set `shown = @start_screen.showing`, dismiss, then `return handle(...) || shown`, and drop `tick`'s `animating?` guard.
- Category: editor
- Added: 2026-11-05

## The input controller reaches through ShowCompletion for an arrival

- Where: `carat/adapters/input_controller.rb` (line 71 at 376d264), which reads `@show_completion.source.request.arrived`, three objects deep. Quality advisory in `completion-request`, reported twice.
- Why it matters: the adapter depends on the use case's source and its request record, so a change to either breaks the controller.
- Fix outline: inject the shared `Domain::CompletionRequest` (`completions.request` in `EditorAssembly`, checked in `test/adapters_assembly.rb`), or call the show-completion use case unconditionally, since it returns at once when nothing shows or arrived.
- Also: test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-07

## The hover request holders are reached through other use cases

- Where: `carat/adapters/input_controller.rb` line 81 reads the shared `HoverRequest` through `show_hover.hover`, and `carat/use_cases/handle_key.rb` line 93 through `follow_hover.hover`, at b0dd342. Periodic quality. Queued in `hover-tidy`.
- Why it matters: the holder rule and `test/adapters_assembly.rb` never see these holders, so a second instance would pass.
- Fix outline: pass the request from `EditorAssembly` to both, with readers checked in the assembly test.
- Also: carat/use_cases/handle_key.rb, test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-07

## The read timeout cut to a notification's deadline has no test

- Where: `carat/adapters/input_controller.rb` line 152, at the `feedback` change; only the harness pump is exercised. Quality advisory of `feedback`.
- Why it matters: a regression that waits the full timeout leaves a notification on screen past its deadline unnoticed.
- Fix outline: have the terminal double record the timeout of `read_key` and assert it is cut while a notice shows.
- Category: editor
- Added: 2026-11-09

## The start screen check calls handle in both branches

- Where: `carat/adapters/input_controller.rb:128`. Periodic quality.
- Why it matters: duplicated call.
- Fix outline: dismiss when shown, then one handle call. Backlog batches (dead code).
- Category: editor
- Added: 2026-11-10

## InputController hand-writes a reader and repeats a call

- Where: `carat/adapters/input_controller.rb:128`, `:137`. Periodic quality advisory.
- Fix outline: `attr_reader :decoder #: KeyDecoder`; dismiss first, then one `handle`. Backlog batches (copies).
- Category: editor
- Added: 2026-11-10

### InputController calls handle twice

- Location: carat/adapters/input_controller.rb:128 (sprint-4 sweep, quality advisory).
- Why: the start-screen branch and the fall-through each call handle(state, @decoder.feed(bytes)).
- Fix: dismiss the start screen if showing, then one handle call.
- Category: editor
- Added: 2026-11-14

### Asynchronous language features have no extension point (architecture-review H2)

Location: `carat/adapters/input_controller.rb:62` (constructor takes `show_completion`, `show_hover`, `show_definition`, `show_signature`, `signature`); `carat/use_cases/handle_key.rb:92-105` (`follow_hover`, `follow_definition`, `follow_signature`, `follow_palette`). Why: each new feature of this kind (references, rename) widens two constructors, the assembly, and the idle and after-key paths by hand, and the order answers are shown or floats followed is implicit. Fix outline: an ordered list of idle steps (`call(state)` answering whether it showed something) and one of after-key followers, filled by each feature's `register` like the action table, so `InputController` and `HandleKey` walk a list.
- Also: carat/use_cases/handle_key.rb
- Category: editor
- Added: 2026-11-15

### Pump writes handle (sprint-20 sweep quality, input_controller.rb:134)

- Location: `carat/adapters/input_controller.rb:134`
- Why: pump writes handle(state, @decoder.feed(bytes)) twice around the start screen's dismissal
- Fix: dismiss when showing, remember it, and return handle(...) || dismissed once
- Category: editor
- Added: 2026-11-19

### carat/adapters/input_controller.rb:134: duplication: both branches call handle(state, @decoder.feed(bytes)), the start-screen branch (sprint-22 sweep quality)

- Location: `carat/adapters/input_controller.rb:134`
- Why: duplication: both branches call handle(state, @decoder.feed(bytes)), the start-screen branch only adding dismiss and a forced true
- Fix: dismiss when showing, then return handle(...) || dismissed
- Category: editor
- Added: 2026-11-20
