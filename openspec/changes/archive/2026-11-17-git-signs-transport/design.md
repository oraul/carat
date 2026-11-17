# Design

## Context

Three findings of the plugin host's security and quality reviews, each a small change in `carat/use_cases/plugins/`: the program environment of `FileRequests#run_program`, the cleanup of `PluginRegistry#disable`, and the float branch of `WindowRequests#focus_window`.

## Goals / Non-Goals

Goals: no git transport for a plugin's program whatever the git version; no float left behind by a disabled plugin; no focus into a float the plugin does not own.

Non-goals: a transport for a plugin that needs one; changing the `git_signs` command lines.

## Decisions

- `GIT_ALLOW_PROTOCOL=""` in `PROGRAM_ENVIRONMENT`. git reads the variable as the list of allowed transports, overriding `protocol.allow` and every `protocol.NAME.allow` of any configuration file; an empty list allows none, so `file`, `ssh`, `git`, `http`, `ext`, and remote helpers are all refused, including on the fetch git starts for a missing object. The variable exists since git 2.6.1, so it holds where `GIT_NO_LAZY_FETCH` (2.44) does not. The alternative, `-c protocol.allow=never` on each command line, loses to a repository's `protocol.NAME.allow=always`, and a plugin cannot set a variable itself, so the host does it for every program, as it does `GIT_NO_LAZY_FETCH`. git's local commands (`symbolic-ref`, `rev-list`, `cat-file`) use no transport and are unaffected.
- `PluginRegistry#clean_up` calls a new private `close_floats(name)` before it drops the plugin's buffers: it walks every tab page's `FloatLayer` from the top down and closes each float whose window shows a buffer the plugin owns, the ownership `own_float_tab` uses. `FloatLayer#close` gives a focused float's focus back to the layout.
- `focus_window`'s float branch refuses with "No window N" when `own_float_tab(name, id)` is negative and the id is not 0. The wording is the unknown-id answer, so a plugin learns nothing about a float it does not own. Id 0 names the current window, already entered, so answering it enters nothing; the explorer reads the current window's id that way.

## Risks / Trade-offs

- A future plugin running `git fetch` or `git push` through `run_program` fails; that change decides how to allow a transport.
