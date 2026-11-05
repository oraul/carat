#!/bin/sh
# The generators behind make new-use-case, new-action, new-ex-command,
# new-test, and new-plugin: each writes the file of one kind in the shape
# of its golden example in docs/examples.md, with its inline RBS
# signatures, and wires it into every place the checks read, so the tree
# compiles and passes lint and the tests at once and the author fills in
# the behavior. Shell and awk only; no Ruby interpreter runs. Every name,
# file, and anchor line is checked before anything is written, so a refusal
# leaves the tree as it was.
#
# Usage: sh tools/new.sh KIND ARGS
#   use-case NAME AREA [DIR]   carat/use_cases/[DIR/]NAME.rb, its require in
#                              carat.rb, a Files bullet in map area AREA
#   action NAME ACTION [AREA]  carat/use_cases/actions/NAME_handler.rb for the
#                              action ACTION, its requires and registration,
#                              its docs/actions.md row, a bullet in AREA (5)
#   ex-command NAME SPEC [AREA]
#                              carat/use_cases/ex/NAME_command_handler.rb for
#                              the Vim name SPEC (sor[t]), its requires and
#                              registration, its docs/compatibility.md row,
#                              a bullet in AREA (12)
#   test NAME AREA             test/NAME.rb with a table, its snapshot, its
#                              runner lines, and an entry on AREA's Tests line
#   plugin NAME [AREA]         carat/plugins/NAME/plugin.rb, its
#                              config/plugins.caratrc and enabled lines, its
#                              docs/actions.md row, a bullet in AREA (15);
#                              make new-plugin then runs make gen-config
#
# NAME is snake_case. NEW_ROOT names the tree to write into (default this
# repository); tools/tools_test.sh points it at a copy.
set -u

root=${NEW_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$root" || exit 2
MAP=docs/codebase-map.md
ASSEMBLY=carat/adapters/editor_assembly.rb
RUNNER=test/runner/run_all.rb

die() {
  echo "new: $*" >&2
  exit 2
}

usage() {
  sed -n '/^# Usage:/,/^# NAME is/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

# camel NAME: snake_case to CamelCase.
camel() {
  printf '%s\n' "$1" | awk -F_ '{ for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), substr($i, 2); print "" }'
}

check_name() {
  printf '%s\n' "$1" | grep -q -E '^[a-z][a-z0-9]*(_[a-z0-9]+)*$' ||
    die "NAME must be snake_case, as split_window: '$1'"
}

absent() {
  [ ! -e "$1" ] || die "$1 exists; pick another NAME"
}

# anchor FILE TEXT: FILE has a line containing TEXT, the place an insertion
# goes next to.
anchor() {
  grep -q -F -- "$2" "$1" || die "$1 has no line containing '$2' to insert next to; update tools/new.sh"
}

check_area() {
  printf '%s\n' "$1" | grep -q -E '^[0-9]+$' || die "AREA must be the number of a section of $MAP: '$1'"
  grep -q -E "^## $1\. " "$MAP" || die "$MAP has no area $1"
}

# put_after FILE LINE TEXT: TEXT as the line after line LINE (0: first).
put_after() {
  AT=$2 TEXT=$3 awk 'BEGIN { at = ENVIRON["AT"] + 0; text = ENVIRON["TEXT"] }
    NR == 1 && at == 0 { print text }
    { print }
    NR == at { print text }' "$1" > "$1.new" && mv "$1.new" "$1"
}

# before FILE ANCHOR TEXT: TEXT before the first line containing ANCHOR.
before() {
  n=$(grep -n -F -- "$2" "$1" | head -1 | cut -d: -f1)
  put_after "$1" $((n - 1)) "$3"
}

# after FILE ANCHOR TEXT: TEXT after the last line containing ANCHOR.
after() {
  n=$(grep -n -F -- "$2" "$1" | tail -1 | cut -d: -f1)
  put_after "$1" "$n" "$3"
}

# sorted FILE REGEX KEY TEXT: TEXT before the first line matching REGEX
# whose first double-quoted string sorts after KEY, else after the last.
sorted() {
  n=$(RE=$2 KEY=$3 LC_ALL=C awk 'BEGIN { re = ENVIRON["RE"]; key = ENVIRON["KEY"] }
    $0 ~ re { split($0, q, "\""); last = NR; if (!first && q[2] > key) first = NR }
    END { print first ? first - 1 : last }' "$1")
  put_after "$1" "$n" "$4"
}

# section_line AREA REGEX [LAST]: the line number in area AREA of the map of
# the first line matching REGEX, or with LAST of the last one after the
# "Files:" line and before "Tests:".
section_line() {
  AREA=$1 RE=$2 LAST=${3:-} awk 'BEGIN { head = "## " ENVIRON["AREA"] ". " }
    index($0, head) == 1 { on = 1; next }
    on && /^## / { exit }
    on && ENVIRON["LAST"] == "" && $0 ~ ENVIRON["RE"] { print NR; exit }
    on && ENVIRON["LAST"] != "" && /^Files:/ { files = 1 }
    on && ENVIRON["LAST"] != "" && /^Tests:/ { exit }
    on && files && $0 ~ ENVIRON["RE"] { n = NR }
    END { if (ENVIRON["LAST"] != "" && n) print n }' "$MAP"
}

# map_file AREA PATH TEXT: a bullet for PATH after the last bullet of the
# area's Files list.
map_file() {
  n=$(section_line "$1" '^- ' last)
  [ -n "$n" ] || die "area $1 of $MAP has no Files list"
  put_after "$MAP" "$n" "- \`$2\`: $3"
}

# map_test AREA PATH: PATH added at the end of the area's Tests line.
map_test() {
  n=$(section_line "$1" '^Tests: ')
  [ -n "$n" ] || die "area $1 of $MAP has no Tests line"
  P=$2 N=$n awk 'NR == ENVIRON["N"] + 0 { sub(/\.$/, ""); $0 = $0 ", `" ENVIRON["P"] "`." } { print }' "$MAP" > "$MAP.new" &&
    mv "$MAP.new" "$MAP"
}

# fill TOKEN=VALUE...: standard input with each @TOKEN@ replaced.
fill() {
  script=""
  for pair in "$@"; do
    script="$script s|@${pair%%=*}@|${pair#*=}|g;"
  done
  sed "$script"
}

# ------------------------------------------------------------------ kinds

use_case() {
  name=$1 area=$2 dir=${3:-}
  check_name "$name"
  check_area "$area"
  [ -z "$dir" ] || check_name "$dir"
  path=carat/use_cases/${dir:+$dir/}$name.rb
  absent "$path"
  anchor carat.rb 'require_relative "carat/use_cases/actions/action_handler"'
  [ -n "$(section_line "$area" '^- ' last)" ] || die "area $area of $MAP has no Files list"
  class=$(camel "$name")
  up=../ outcome=outcome
  [ -z "$dir" ] || { up=../../ outcome=../outcome; }
  mkdir -p "$(dirname "$path")" && fill CLASS="$class" UP="$up" OUTCOME="$outcome" > "$path" <<'EOF' || die "cannot write $path"
require_relative "@UP@domain/editor_state"
require_relative "@UP@domain/command"
require_relative "@OUTCOME@"

module Carat
  module UseCases
    # TODO: what @CLASS@ does, in the editor's terms: the keys or command
    # that run it and the state it leaves. A collaborator is a required
    # keyword of initialize with a reader, as SplitWindow's are.
    class @CLASS@
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        Outcome.none
      end
    end
  end
end
EOF
  before carat.rb 'require_relative "carat/use_cases/actions/action_handler"' "require_relative \"${path%.rb}\""
  map_file "$area" "$path" "\`$class#call\`; TODO: one line on what it does."
  echo "wrote $path; required it in carat.rb; listed it in area $area of $MAP"
  echo "next: build it in EditorAssembly and hand it to the handler that calls it; describe it in the map; test it (make new-test)"
}

action() {
  name=$1 action=$2 area=${3:-5}
  check_name "$name"
  check_area "$area"
  printf '%s\n' "$action" | grep -q -E '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$' ||
    die "ACTION must be dotted snake_case, as window.equalize: '$action'"
  case "$action" in plugin.*) die "a plugin action is declared in its manifest (make new-plugin)" ;; esac
  ! grep -q -F "\`$action\`" docs/actions.md || die "docs/actions.md already lists $action"
  path=carat/use_cases/actions/${name}_handler.rb
  absent "$path"
  anchor carat.rb 'require_relative "carat/use_cases/actions/plugin_action_handler"'
  anchor "$ASSEMBLY" 'require_relative "../use_cases/actions/plugin_action_handler"'
  anchor "$ASSEMBLY" 'UseCases::PluginActionHandler.register(@actions'
  anchor docs/actions.md '## Implemented'
  class=$(camel "$name")Handler
  mkdir -p "$(dirname "$path")" && fill CLASS="$class" ACTION="$action" > "$path" <<'EOF' || die "cannot write $path"
require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # TODO: what @ACTION@ does. A handler that runs a use case takes it as
    # a required keyword, as TabHandler does, and register passes it on.
    class @CLASS@ < ActionHandler
      #: () -> void
      def initialize
        super(kind: :action, repeat: false)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        Outcome.success("Not implemented: @ACTION@")
      end

      #: (ActionTable) -> void
      def self.register(table)
        table.register("@ACTION@", @CLASS@.new, "TODO: short description")
      end
    end
  end
end
EOF
  before carat.rb 'require_relative "carat/use_cases/actions/plugin_action_handler"' "require_relative \"${path%.rb}\""
  before "$ASSEMBLY" 'require_relative "../use_cases/actions/plugin_action_handler"' "require_relative \"../use_cases/actions/${name}_handler\""
  before "$ASSEMBLY" 'UseCases::PluginActionHandler.register(@actions' "        UseCases::$class.register(@actions)"
  n=$(awk '/^## Implemented/ { on = 1; next } on && /^## / { exit } on && /^\| `/ { n = NR } END { print n }' docs/actions.md)
  put_after docs/actions.md "$n" "| \`$action\` | normal | TODO: the effect |"
  map_file "$area" "$path" "\`$class.register\` (\`$action\`); TODO: one line on what it does."
  echo "wrote $path; required and registered it; listed $action in docs/actions.md and the handler in area $area of $MAP"
  echo "next: bind it with keymap.<mode> <keys> $action in config/default.caratrc and run make gen-config; fill in its docs/actions.md row; write the behavior and its test"
}

ex_command() {
  name=$1 spec=$2 area=${3:-12}
  check_name "$name"
  check_area "$area"
  printf '%s\n' "$spec" | grep -q -E '^[a-z]+(\[[a-z]+\])?$' ||
    die "SPEC must be a Vim name, as sor[t] or new: '$spec'"
  full=$(printf '%s' "$spec" | tr -d '[]')
  ! grep -q -E "\`:$full( |\`|\[)|\`:$(printf '%s' "$spec" | sed 's/\[.*//')\[" docs/compatibility.md ||
    die "docs/compatibility.md already lists :$spec"
  path=carat/use_cases/ex/${name}_command_handler.rb
  absent "$path"
  anchor carat.rb 'require_relative "carat/use_cases/ex/plugin_command_handler"'
  anchor "$ASSEMBLY" 'require_relative "../use_cases/ex/plugin_command_handler"'
  anchor "$ASSEMBLY" 'UseCases::PluginCommandHandler.register(@commands'
  anchor docs/compatibility.md '| unknown |'
  class=$(camel "$name")CommandHandler
  mkdir -p "$(dirname "$path")" && fill CLASS="$class" SPEC="$spec" FULL="$full" > "$path" <<'EOF' || die "cannot write $path"
require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # TODO: what :@FULL@ does and the messages it reports, as Neovim does.
    class @CLASS@ < ExHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        Outcome.success("Not implemented: :@FULL@")
      end

      # Registers :@FULL@ in the order of docs/compatibility.md, which is
      # its precedence; a handler that runs a use case takes it as a
      # required keyword here and in initialize.
      #: (ExTable) -> void
      def self.register(table)
        table.register(@CLASS@.new(spec: "@SPEC@"))
      end
    end
  end
end
EOF
  before carat.rb 'require_relative "carat/use_cases/ex/plugin_command_handler"' "require_relative \"${path%.rb}\""
  before "$ASSEMBLY" 'require_relative "../use_cases/ex/plugin_command_handler"' "require_relative \"../use_cases/ex/${name}_command_handler\""
  before "$ASSEMBLY" 'UseCases::PluginCommandHandler.register(@commands' "        UseCases::$class.register(@commands)"
  before docs/compatibility.md '| unknown |' "| \`:$spec\` | TODO: the behavior | \`Not implemented: :$full\` | \`use_cases_ex\` |"
  map_file "$area" "$path" "\`$class.register\` (\`:$spec\`); TODO: one line on what it does."
  echo "wrote $path; required and registered it last before the plugin commands; added its docs/compatibility.md row before unknown; listed it in area $area of $MAP"
  echo "next: move its registration and its row to Vim's precedence when another command shares its abbreviation; write the behavior and a table-driven test"
}

test_program() {
  name=$1 area=$2
  check_name "$name"
  check_area "$area"
  path=test/$name.rb
  absent "$path"
  absent "$path.expected"
  ! grep -q -F "when \"$name\"" "$RUNNER" || die "$RUNNER already runs $name"
  anchor "$RUNNER" 'require_relative "../'
  anchor "$RUNNER" 'case ARGV[0]'
  [ -n "$(section_line "$area" '^Tests: ')" ] || die "area $area of $MAP has no Tests line"
  module=$(camel "$name")Test
  mkdir -p "$(dirname "$path")" && fill MODULE="$module" NAME="$name" > "$path" <<'EOF' || die "cannot write $path"
require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module @MODULE@
  # A typed helper: a table value is untyped, and an untyped argument
  # widens the library method it reaches for every test (docs/spinel-notes.md).
  def self.length_of(text)
    text.to_s.length
  end

  def self.main
    t = Carat::Testing.new("@NAME@")

    # Rows are [label, input, expected]. TODO: the rows of the behavior
    # under test; then make snapshots and review the diff.
    t.table([
      ["an empty line has no characters", "", 0],
      ["a word counts its characters", "abc", 3]
    ]) do |text|
      length_of(text)
    end

    t.finish
  end
end

@MODULE@.main if __FILE__ == $0
EOF
  fill NAME="$name" > "$path.expected" <<'EOF'
ok   an empty line has no characters
ok   a word counts its characters
@NAME@: 2 passed, 0 failed
EOF
  sorted "$RUNNER" '^require_relative "\.\./' "../$name" "require_relative \"../$name\""
  sorted "$RUNNER" '^when "' "$name" "when \"$name\" then $module.main"
  map_test "$area" "$path"
  echo "wrote $path and its snapshot; added its runner lines; listed it in area $area of $MAP"
  echo "next: replace the rows, run make test-one T=$path, then make snapshots and review the diff"
}

plugin() {
  name=$1 area=${2:-15}
  check_name "$name"
  check_area "$area"
  dir=carat/plugins/$name
  path=$dir/plugin.rb
  absent "$dir"
  ! grep -q -E "^plugin\.$name( |\.)" config/plugins.caratrc config/default.caratrc ||
    die "config/ already names plugin.$name"
  anchor config/plugins.caratrc 'plugin.'
  anchor config/default.caratrc 'plugin.'
  anchor docs/actions.md '## Plugins'
  class=$(camel "$name")
  mkdir -p "$(dirname "$path")" && fill CLASS="$class" NAME="$name" > "$path" <<'EOF' || die "cannot write $path"
require_relative "../../plugin_api"

module Carat
  module Plugins
    module @CLASS@
      # TODO: what the plugin adds, in the editor's terms. It requires only
      # the plugin API and files in its own directory (docs/plugins.md).
      class Plugin < Carat::PluginApi::Plugin
        NAME = "@NAME@"
        RUN = "plugin.@NAME@.run"

        # @rbs @host: Carat::PluginApi::Host?

        #: () -> void
        def initialize
          @host = nil
        end

        # Returns the manifest: default bindings and options are
        # configuration lines here, so the user's configuration wins.
        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(name: NAME, version: "0.1.0", api_version: Carat::PluginApi::VERSION, actions: { "plugin.@NAME@.run" => "TODO: what the action does" }, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: [])
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        #: (String, Carat::PluginApi::Context) -> void
        def on_action(name, context)
          host = @host
          return if host.nil?
          host.message("Not implemented: #{name}", false) if name == RUN
        end
      end
    end
  end
end
EOF
  after config/plugins.caratrc 'plugin.' "plugin.$name $name/plugin Carat::Plugins::$class::Plugin"
  n=$(grep -n '^plugin\.' config/default.caratrc | tail -1 | cut -d: -f1)
  put_after config/default.caratrc "$n" "plugin.$name.enabled true"
  n=$(awk '/^## Plugins/ { on = 1; next } on && /^## / { exit } on && /^\| `/ { n = NR } END { print n }' docs/actions.md)
  [ -n "$n" ] || n=$(grep -n '^## Plugins' docs/actions.md | cut -d: -f1)
  put_after docs/actions.md "$n" "| \`plugin.$name.run\` | \`$name\` | none | TODO: the effect |"
  map_file "$area" "$path" "\`$class::Plugin\`; \`manifest\`, \`activate\`, \`on_action\`; TODO: one line on what it adds."
  echo "wrote $path; listed it in config/plugins.caratrc, enabled it in config/default.caratrc, added plugin.$name.run to docs/actions.md, listed it in area $area of $MAP"
  echo "next: make gen-config (make new-plugin runs it); declare bindings and options in the manifest; give a plugin of substance its own map area and test (make new-test)"
}

[ $# -ge 2 ] || usage
kind=$1
shift
case "$kind" in
  use-case) [ $# -ge 2 ] || usage; use_case "$@" ;;
  action) [ $# -ge 2 ] || usage; action "$@" ;;
  ex-command) [ $# -ge 2 ] || usage; ex_command "$@" ;;
  test) [ $# -ge 2 ] || usage; test_program "$@" ;;
  plugin) plugin "$@" ;;
  *) usage ;;
esac
