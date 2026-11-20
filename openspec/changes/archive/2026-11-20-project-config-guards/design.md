# Design

## Context

`RcConfigGateway#read_file` stats the path (`DiskFiles#stat` tests `File.symlink?`, then follows the link for the kind) and refuses a linked project file, then calls `FilePort#read`, which opens the path again and checks the kind and size on the open handle but follows a link. `Config#binding?` keeps any project keymap line whose value is an action name or `none`. `Options#apply` checks `tabstop` and `shiftwidth` with `width_problem`, `keyhints.delay` and the slot sizes with `range_problem`, each in a five-line branch, and the seven named options each in their own five-line branch; `scroll`, `scrolloff`, `timeoutlen`, and `undolevels` assign `word.to_i`, which `RcValue` limits only to nine digits.

## Decisions

### Refuse the link at the open

A new port method, `read_no_link(path, limit)`, is `read` with `File::NOFOLLOW` added to the open flags, which Spinel maps to `O_NOFOLLOW`; `DiskFiles` shares the open-and-check body between the two through a private `read_open(path, flags, limit)`. The gateway keeps its stat, which gives the precise messages (a link, not regular, too large) in the usual case, and reads the untrusted file with `read_no_link`, whose failure is the existing "cannot be read". Alternative: a third parameter to `read`; rejected, since every caller and double of `read` would change for one caller. Alternative: drop the stat; rejected, it would lose the directory skip and the messages.

### Refused actions by name

`Config::PROJECT_REFUSED` lists `file.save`, `quit.all`, `quit.write_all`, and `window.quit`, and `Config::COMMAND_LINE` the `cmdline.` prefix, so a command-line action added later is refused without an edit. `binding?` checks them after the key-sequence check, for every mode, and `none` stays allowed. The domain cannot ask the action table (an inner layer), so the names are listed; a test checks every listed name is a registered action, so a rename cannot leave the list stale.

### One bounded check, one named check

`bounded(config, line, low, high)` returns the line's number when it lies from low to high, else notes `"#{key} takes a number from #{low} to #{high}"` and returns -1; every low is 0 or 1, so -1 means refused. `named(config, line, word, known, what)` returns the word when `known`, else notes `"unknown #{what} #{word}"` and returns "". Both return values rather than `bool`, so they are not predicates that note problems. Constants: `LINES_MAX = 9999` (scroll, scrolloff), `TIMEOUTLEN_MAX = 10_000`, `UNDOLEVELS_MAX = 10_000`.

## Risks

- A user file with a larger value than the new bounds now gets a report and the default; the bounds are far above useful values.
