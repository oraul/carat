# Design

## Context

`Config#binding_problem` judges each keymap line of the untrusted project file: a key sequence is refused, an action outside `PROJECT_BINDABLE` is refused, and `project_bindable_in?(mode, action)` keeps `PROMPT_ACTIONS` (`mode.cmdline`, `palette.open`) to `PROMPT_MODES` (normal and the visual modes). `held_keys` holds every key the trusted files bind to an action `project_bindable_in?` refuses in that mode, or to `mode.cmdline`. The `mode.` family is allowed in every mode, so insert-mode `<CR>` bound to `mode.normal` leaves insert mode on Enter, and then the letters the user goes on typing are normal-mode keys, any of which the project may have bound to `mode.cmdline` or `palette.open`.

## Goals / Non-Goals

Goals: no project binding leaves a text-entry mode; no project binding opens a prompt from keys typed while editing text; a test per security heading that fails before the fix. Drop the `Keymap.leader_from` wrapper; keep `Config`'s settings behind its typed readers.

Non-goals: the split headings (config-guards-e, -f); any change to the defaults or the user file's rules.

## Decisions

1. Text-entry modes take an allowlist of their own. `TEXT_MODES = ["insert", "replace", "cmdline", "completion"]` and `TEXT_BINDABLE`, seventeen action names whole: the completion actions, `insert.newline`, `insert.backspace`, `insert.delete`, `insert.tab`, the four arrows' `cursor.*`, and `scroll.page_down` and `scroll.page_up`, the actions `docs/actions.md` lists for insert mode less `mode.normal` and `file.save`. Named whole, not by family, so a later `insert.*` that leaves the mode (a Ctrl-O) is refused until listed; `test/use_cases_actions.rb` checks every name is a registered, allowed action. `palette.next` and `palette.previous` are left out: on a letter in cmdline mode they would move the palette's choice under the filter the user types, so Enter runs another action. `project_bindable_in?` answers from `TEXT_BINDABLE` in a text-entry mode, and from `PROMPT_MODES` for a prompt elsewhere. An allowlist rather than refusing `mode.` alone: in a text-entry mode the dispatcher runs any action plainly, and `search.forward`, a window or buffer switch, or an operator could also leave the mode. Alternative rejected: refusing only `mode.`, which leaves those paths open.
2. The held keys follow: `held_keys` asks `project_bindable_in?`, so the defaults' insert and cmdline `<Esc>` (`mode.normal`) and cmdline `<C-n>` and `<C-p>` become held, and a project file can neither unbind them (trapping the user in insert mode) nor bind a key starting with them. The completion popup's `<Esc>` runs `completion.close`, which stays bindable, so `held_keys` holds a key bound to `CLOSE_COMPLETION` as it holds `OPEN_COMMAND_LINE`'s; otherwise `keymap.completion <Esc> completion.next` would keep the popup open on every Escape.
3. A prompt opener on keys typed while editing text is refused in `binding_problem`, after the mode check: the keys are parsed with the leader (`KeyNotation.parse`, as `held_key` does) and refused (`typed_while_editing?`) when no code is a function key (`F1` to `F12`), an Alt key, or a control code other than Tab, Enter (CR or NL), Backspace (`<C-h>`), and Escape. So printable characters, multi-byte ones included, Backspace (DEL), the arrows, Home, End, the Page keys, and Delete count as editing keys: a user moving by arrow in normal mode would otherwise open the command line on `<Up>` and recall an earlier command on the next `<Up>`. One holding `<F4>`, a control, or an Alt key cannot fire while text is typed, so `<C-k>p` and `<M-p>` stay allowed. Keys that do not parse are left to the keymap, which reports them and binds nothing. The message names the keys and the action: "<keys> is typed while editing text, so a project file may not bind it to <action>".
4. `Keymap.leader_from` is removed and its five production and test call sites read `config.leader`.
5. `Config`'s `settings` member stays pinned `Array[untyped]`, since Spinel pins arrays only of builtin element types (`docs/spinel-notes.md`); the comment at the pin says so and that the lines are read through `line_at`, typed `RcLine`, and counted through `count`. The language gateway's `@config.settings.length` becomes `@config.count`, so no file outside `Config` reads the member.

## Risks / Trade-offs

- A project file that bound a mode action in insert mode, or a prompt to a printable key, now gets a reported line; that is the point of the rules, and the defaults and the user file are unaffected.
- `<Esc>` in insert and cmdline mode is now held: a project can no longer rebind it to a plain action (a `cursor.left` on `<Esc>` would also have trapped the user).
