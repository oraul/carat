# Design

## Context

`test/lint.rb` already reads every source file and the code map (`map_spans`, `map_problems`) and runs in `make lint`, `make test`, and CI; `tools/gates.sh` compares the branch with `origin/main` in `make gates` and before the push, and `tools/tools_test.sh` gives each gate cases in temporary repositories. The two code checks go into the lint test, the two diff checks into the gates. The planner's split keeps the other two checks for `implement-contracts-c`.

## Decisions

### The map's method lists

A file's line in `docs/codebase-map.md` reads `` - `path.rb`: `Class`, what it is; `a`, `b?`, `c` (prose). `` The method list is the text after the first `` ; ` `` up to the next top-level `;` or sentence end, parentheses dropped; an item counts only when it is exactly one code span (an optional leading `and ` or `or ` aside) of a method shape (`name`, `name?`, `name!`, `name=`, or `Const.name`). So "trimming at `undolevels`" and "one `require_relative` per plugin" are prose and are skipped, and spans in parentheses (keys, values) are never read. A name is defined when the file has `def name` or `def self.name`, or, for a name without `?` or `!`, an `attr_*` or a `Struct.new` or `Data.define` member of that name. A prototype over the map at df4654c found no false refusal after these two rules, and no absent name; the drift the planner noted at lines 92, 517, and 523 is missing names, which is queue item `docs-index`. Pure helpers (`map_entry_path`, `map_methods`, `defines?`, `map_method_problems`) take text, so the self-checks run on inline lines.

### `Array[untyped]` of program objects

`docs/spinel-notes.md` asks a list of program-class objects to be a class of its own, a pinned `Array[untyped]` read through a typed reader. Two shapes break it and both were blockers: a method taking `Array[untyped]` (`Buffer#diagnostics`, `StatusSlots#count_diagnostics`), and a member pinned `Array[untyped]` that another file assigns by reference (`buffer.styles = docs.styles` in three use cases). The lint refuses a `#:` signature whose parameters hold `Array[untyped]`, except the element reader form `(Array[untyped], Integer) -> T` with a typed `T` (`pending_at`, `child`, `edit_item`), and except files of `UNTYPED_PARAMETERS`, each with its reason: JSON values (`carat/domain/json.rb`) and test table rows (`carat/testing.rb`) are genuinely mixed, the plugin list (`editor_assembly.rb`, `editor_harness.rb`) is the generated registry's, and the edit list of `buffer_requests.rb` is the plugin API's, as `PluginApi::Host#edit_buffer` declares it. It refuses `x.name = ` from a file other than one pinning `@name: Array[untyped]`, `self.name =` being the owner's writer; `UNTYPED_SHARED` exempts `styles` with its owner, queue item `hover-tidy`, which removes the line. `# @rbs name:` lines of overridden methods are left out: they restate the plugin API's boundary.

### Doc prose a change leaves behind

No machine reads whether a paragraph still holds. What the blockers share is that the change altered what a document describes and nobody looked: a spec changed (the editor's behavior) and `README.md` or `docs/architecture.md` did not, or a process file changed and `CLAUDE.md` did not. `gate_docs` now refuses those, unless a proposal in the diff (`openspec/changes/[archive/]NAME/proposal.md`) holds `- README.md: unchanged, REASON` (backticks allowed), which makes the question a recorded decision the reviewers see. Specs are `openspec/specs/*/spec.md` and the delta specs under `openspec/changes/`; process files are `.claude/agents/`, `.claude/workflows/`, top-level `.claude/commands/`, `Makefile`, `tools/gates.sh`, `tools/run_state.sh`, and `tools/agent_guard.sh`.

### Scenarios no test names

`gate_scenarios` reads each delta spec in the diff at `HEAD` (archived ones included, so the gate holds before and after the archive), takes the `#### Scenario:` names under `## ADDED` and `## MODIFIED` sections, and refuses each that `git grep -i -F` finds in no file under `test/` or in `tools/tools_test.sh` at `HEAD`. A name is matched whole, so the test names it in its label or a comment. REMOVED and RENAMED sections are skipped. It joins `static` and `pre-push`; the merge gates rely on the checker's `static` run.

## Risks / Trade-offs

- [A future map line in another shape is read as prose] → the check is strict only for exact single-span items, so it misses rather than refuses; the self-check pins the shapes it reads.
- [The attestation line is a formality] → it is a line a reviewer reads in the proposal, and a run that needs it is visible in the diff.
- [MODIFIED requirements restate old scenarios] → the contributor names them in the test that covers them; one comment line per scenario.
