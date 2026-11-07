# Proposal

## Why

A user typing a call cannot see which arguments the method takes or which one the cursor is at without leaving insert mode: the language server knows (`textDocument/signatureHelp`), but nothing asks it. This delivers parameter info, part of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 1, a user request).

## What Changes

- In insert mode, typing `(` or `,` asks the current buffer's language server for the signature of the call the cursor is in, when its server advertised `signatureHelpProvider`; the innermost `(` left open before the cursor on its row is the call. The answer opens, at the next idle moment with no key pressed, a one-row bordered float above the cursor (below it when the screen has no room above) showing the active signature's label, the active parameter drawn in `Visual`, which is the group Neovim links `LspSignatureActiveParameter` to.
- While a call is followed, every key that moves the cursor within the call asks again, so the marked parameter follows the cursor across arguments and into and out of nested calls; the float closes when the cursor leaves the call (before its `(`, past its matching `)`, or to another row, window, or buffer), when insert mode is left (`Esc`), and when the server answers no signature.
- Requests are asynchronous: sent at an idle tick once no newer ask was recorded for 0.1 seconds, one in flight, a newer ask or a request unanswered two seconds past its sending cancelled with `$/cancelRequest`; an answer is read only when it answers the request in flight and no newer ask was recorded since it was sent, so an older request's answer is never shown.
- The text is untrusted: the label, the parameter, and the text around it are read with escape sequences and controls dropped, at most 1,024 bytes kept, the active signature and parameter indices checked against the lists, parameter offsets checked against the label.
- No cost per key while no call is followed: one integer comparison after each key and two after each typed character in insert mode, no allocation.
- The initialize request advertises signature help with label offsets.
- Docs: the map, the architecture's services list, compatibility, README, and the backlog entries the plan names.

Out of scope: the signature's and parameters' documentation in the float, a key to cycle overloads, a manual trigger key (Neovim 0.11 binds `<C-s>` in insert mode, which Carat uses for save), calls spanning several rows (the float closes when the cursor moves to another row), parentheses inside strings or comments (the row is scanned as plain bytes; the server answers no signature there), and the server's own trigger characters (Carat triggers on `(` and `,` only).

Assumptions: the float sits at z 900, under the completion popup; it shows one row, its width the label's display width capped at the screen's columns minus two, so a parameter past that width is cut off; the backward scan for the open `(` reads at most 1,024 bytes; an empty answer closes the float with no message, since the user did not ask.

## Capabilities

### New Capabilities

- `parameter-info`: the signature of the call under the cursor in insert mode, its float, following and closing, the request's timing and staleness, and the bounds on its untrusted text.

### Modified Capabilities

None.

## Impact

- New: `carat/domain/signature_request.rb`, `carat/use_cases/docs/` (`RequestSignature`, `ShowSignature`, `FollowSignature`), `test/adapters_signature.rb`, `test/domain_signature_request.rb`.
- Changed: `JsonRpcLanguageGateway` (the capability, the request and answer, `waiting?`, a shared `cancel_request`), `InputController` (the arrived answer at the idle tick), `HandleKey` (the trigger and the per-key follow check), `FloatWindow` and `FramePresenter` (the marked columns of a float's first row), `EditorAssembly`, `test/adapters_assembly.rb`.
- Docs: `docs/codebase-map.md`, `docs/architecture.md`, `docs/compatibility.md`, `README.md`, `docs/backlog.md`.
