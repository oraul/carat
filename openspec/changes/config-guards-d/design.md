# Design

## Context

`Config#binding_problem` judges each keymap line of the untrusted project file: a key sequence is refused, an action outside `PROJECT_BINDABLE` is refused, and `project_bindable_in?(mode, action)` keeps `PROMPT_ACTIONS` (`mode.cmdline`, `palette.open`) to `PROMPT_MODES` (normal and the visual modes). `held_keys` holds every key the trusted files bind to an action `project_bindable_in?` refuses in that mode, or to `mode.cmdline`. The `mode.` family is allowed in every mode, so insert-mode `<CR>` bound to `mode.normal` leaves insert mode on Enter, and then the letters the user goes on typing are normal-mode keys, any of which the project may have bound to `mode.cmdline` or `palette.open`.

## Goals / Non-Goals

Goals: no project binding leaves a text-entry mode; no project binding opens a prompt from keys typed as text; a test per security heading that fails before the fix. Drop the `Keymap.leader_from` wrapper; keep `Config`'s settings behind its typed readers.

Non-goals: the split headings (config-guards-e, -f); any change to the defaults or the user file's rules.

## Decisions

1. Text-entry modes take an allowlist of their own. `TEXT_MODES = ["insert", "replace", "cmdline", "completion"]` and `TEXT_BINDABLE = ["completion.", "cursor.", "insert.", "palette.next", "palette.previous", "scroll."]`: the families the defaults bind in those modes, less the ones a project already may not bind (`cmdline.*`, `file.save`) and `mode.normal`. `project_bindable_in?` answers from `TEXT_BINDABLE` in a text-entry mode, and from `PROMPT_MODES` for a prompt elsewhere. An allowlist rather than refusing `mode.` alone: in a text-entry mode the dispatcher runs any action plainly, and `search.forward`, a window or buffer switch, or an operator could also leave the mode; an allowlist refuses any family added later. Alternative rejected: refusing only `mode.`, which leaves those paths open.
2. The held keys follow without new code: `held_keys` asks `project_bindable_in?`, so the defaults' insert and cmdline `<Esc>` (`mode.normal`) become held, and a project file can neither unbind them (trapping the user in insert mode) nor bind a key starting with them.
3. A prompt opener on keys typed as text is refused in `binding_problem`, after the mode check: the keys are parsed with the leader (`KeyNotation.parse`, as `held_key` does) and refused when every code is a text key: `Key.printable?`, Tab, Enter (CR or NL), or Backspace (DEL or `<C-h>`). Only a sequence made of such keys can fire while the user types text; one holding `<F4>`, a control, or an Alt key cannot, so `<C-k>p` stays allowed. Keys that do not parse are left to the keymap, which reports them and binds nothing. The message names the keys and the action: "<keys> is typed as text, so a project file may not bind it to <action>".
4. `Keymap.leader_from` is removed and its five production and test call sites read `config.leader`.
5. `Config`'s `settings` member stays pinned `Array[untyped]`, since Spinel pins arrays only of builtin element types (`docs/spinel-notes.md`); the comment at the pin says so and that the lines are read through `line_at`, typed `RcLine`, and counted through `count`. The language gateway's `@config.settings.length` becomes `@config.count`, so no file outside `Config` reads the member.

## Risks / Trade-offs

- A project file that bound a mode action in insert mode, or a prompt to a printable key, now gets a reported line; that is the point of the rules, and the defaults and the user file are unaffected.
- `<Esc>` in insert and cmdline mode is now held: a project can no longer rebind it to a plain action (a `cursor.left` on `<Esc>` would also have trapped the user).
