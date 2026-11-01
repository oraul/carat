require_relative "../carat/test_support"
require_relative "../carat/testing"

# The input ports of the core: the action table and the ex table with
# their registration rules, the ex name matcher, the kinds the grammar
# reads, every registered handler returning an Outcome, and the action
# table kept in step with docs/actions.md.
t = Carat::Testing.new("use_cases_actions")
U = Carat::UseCases
D = Carat::Domain

# A handler that answers its own name, for the table rules.
class EchoHandler < Carat::UseCases::ActionHandler
  # @rbs @text: String

  #: (String, Symbol) -> void
  def initialize(text, kind)
    super(kind: kind, repeat: false)
    @text = text
  end

  # @rbs state: Carat::Domain::EditorState
  # @rbs command: Carat::Domain::Command
  def call(state, command)
    Carat::UseCases::Outcome.success(@text)
  end
end

# An ex handler that answers its own full name.
class EchoCommandHandler < Carat::UseCases::ExHandler
  # @rbs state: Carat::Domain::EditorState
  # @rbs command: Carat::Domain::ExCommand
  def call(state, command)
    Carat::UseCases::Outcome.success(name.full)
  end
end

def state
  Carat::Domain::EditorState.new(Carat::Domain::TabList.new(Carat::Domain::Window.new(Carat::Domain::Buffer.from_text("", nil))), Carat::Domain::Options.new)
end

# ------------------------------------------------------------ action table

table = U::ActionTable.new
t.assert_equal([true, true, false], [table.register("probe.one", EchoHandler.new("one", :motion)), table.register("probe.two", EchoHandler.new("two", :action)), table.register("probe.one", EchoHandler.new("again", :action))], "a name registers once and a second registration is refused")
found = table.find("probe.one")
t.assert_equal(["one", :motion], [found.nil? ? "" : found.call(state, D::Command.plain("probe.one")).message, found.nil? ? :none : found.kind], "find returns the first handler registered for the name")
t.assert_equal([true, :action], [table.find("probe.three").nil?, table.kind_of("probe.three")], "an unknown name has no handler and reads as a plain action")
t.assert_equal([true, false], [table.register_namespace("plugin.", EchoHandler.new("plugin", :action)), table.register_namespace("other.", EchoHandler.new("other", :action))], "one namespace handler registers")
via = table.find("plugin.any.thing")
t.assert_equal(["plugin", true], [via.nil? ? "" : via.call(state, D::Command.plain("plugin.any.thing")).message, table.find("plugins.any").nil?], "a name under the namespace finds its handler and a near miss does not")
t.assert_equal([["probe.one", "probe.two"], 2], [table.names, table.count], "names lists the registered names in order")

# ---------------------------------------------------------------- ex names

t.table([
  ["a spec with a suffix", ["w[rite]", "w"], ["w", "write", true]],
  ["the full name", ["w[rite]", "write"], ["w", "write", true]],
  ["a spelling between", ["vs[plit]", "vsp"], ["vs", "vsplit", true]],
  ["shorter than the abbreviation", ["tabfir[st]", "tabf"], ["tabfir", "tabfirst", false]],
  ["longer than the full name", ["vs[plit]", "vsplitx"], ["vs", "vsplit", false]],
  ["not a prefix", ["clo[se]", "clx"], ["clo", "close", false]],
  ["a spec without brackets", ["new", "new"], ["new", "new", true]],
  ["a spec without brackets abbreviated", ["new", "ne"], ["new", "new", false]],
  ["case matters", ["tabN[ext]", "tabn"], ["tabN", "tabNext", false]]
]) do |input|
  name = D::ExName.parse(input[0])
  [name.short, name.full, name.match?(input[1])]
end
t.assert_equal(["w[rite]", "new"], [D::ExName.parse("w[rite]").to_s, D::ExName.parse("new").to_s], "a name prints in Vim's notation")

# ---------------------------------------------------------------- ex table

commands = U::ExTable.new
t.assert_equal([true, true, false, false], [commands.register(EchoCommandHandler.new(spec: "fi[nd]")), commands.register(EchoCommandHandler.new(spec: "fix")), commands.register(EchoCommandHandler.new(spec: "fi[nd]")), commands.register(EchoCommandHandler.new(spec: "fix[up]"))], "a name or abbreviation registers once")
t.table([
  ["the abbreviation", "fi", "find"],
  ["a spelling between", "fin", "find"],
  ["the full name", "find", "find"],
  ["the second command", "fix", "fix"],
  ["an unknown name", "fo", ""],
  ["an empty name", "", ""]
]) do |typed|
  handler = commands.find(typed)
  handler.nil? ? "" : handler.call(state, D::ExCommand.new(typed, false, "")).message
end
ordered = U::ExTable.new
ordered.register(EchoCommandHandler.new(spec: "ma[rk]"))
ordered.register(EchoCommandHandler.new(spec: "m[ove]"))
first = ordered.find("m")
second = ordered.find("ma")
t.assert_equal(["move", "mark"], [first.nil? ? "" : first.name.full, second.nil? ? "" : second.name.full], "when two names accept a typed name the first registered wins")
t.assert_equal(["fi[nd]", "fix"], commands.names, "names lists the registered names in Vim's notation")

# ---------------------------------------------------- the editor's tables

files = Carat::Doubles::MemoryFiles.new
files.put("a.txt", "one two\nthree\n")
h = Carat::Doubles::EditorHarness.default(files, 12, 40)
actions = h.assembly.actions
t.table([
  ["h is a motion", "cursor.left", :motion],
  ["f reads a character", "motion.find_forward", :find],
  ["d is a pending operator", "operator.delete", :operator],
  ["x completes at once", "operator.delete_char", :action],
  ["iw is a text object", "textobject.inner_word", :text_object],
  ["the register prefix", "register.select", :register],
  ["visual r reads a character", "visual.replace", :char],
  ["a plugin action completes at once", "plugin.hello.greet", :action],
  ["an unknown name completes at once", "nothing.here", :action]
]) do |name|
  actions.kind_of(name)
end

# Every registered handler, run in a fresh editor on a plain command,
# returns an Outcome; the namespace handler too.
names = actions.names
wrong = []
i = 0
while i < names.length
  fresh = Carat::Doubles::EditorHarness.default(files, 12, 40)
  fresh.open("a.txt")
  handler = fresh.assembly.actions.find(names[i])
  if handler.nil?
    wrong << "#{names[i]}: no handler"
  else
    result = handler.call(fresh.state, D::Command.plain(names[i]))
    wrong << names[i] unless result.is_a?(Carat::UseCases::Outcome)
  end
  i += 1
end
t.assert_equal([], wrong, "every registered action handler returns an Outcome")
t.assert_true(names.length >= 100, "the table holds every core action")
plugin = actions.find("plugin.none.go")
outcome = plugin.nil? ? U::Outcome.none : plugin.call(h.state, D::Command.plain("plugin.none.go"))
t.assert_equal([false, "No plugin named none"], [outcome.ok, outcome.message], "the plugin namespace handler returns the host's refusal as an Outcome")

# ------------------------------------------------- docs/actions.md in step

# The action names a section of docs/actions.md lists, from the first
# column of each table row and from the backticked names of the Reserved
# paragraph; the Plugins section is the plugins' own.
def documented(text)
  names = []
  section = ""
  text.each_line do |line|
    if line.start_with?("## ")
      section = line.strip
      next
    end
    next unless section == "## Implemented" || section == "## Reserved"
    cell = line
    if line.start_with?("| ")
      cells = line.split("|")
      cell = cells.length > 1 ? cells[1] : ""
    end
    spans = cell.split("`")
    k = 1
    while k < spans.length
      names << spans[k] if spans[k].match?(/\A[a-z0-9_]+(\.[a-z0-9_]+)+\z/)
      k += 2
    end
  end
  names.uniq.sort
end

# What drifted: the names the table has and the document lacks, and the
# names the document has and the table lacks.
def drift(table_names, doc_names)
  [table_names.sort - doc_names, doc_names - table_names.sort]
end

doc_names = documented(File.read("docs/actions.md"))
t.assert_equal([[], []], drift(names, doc_names), "the action table and docs/actions.md list the same actions")
t.assert_equal([["a.one"], ["b.two"]], drift(["a.one", "c.three"], ["b.two", "c.three"]), "a drift is reported in both directions")
t.assert_equal([false, true], [doc_names.include?("plugin.explorer.toggle"), doc_names.include?("search.forward")], "the Plugins section is not read as core actions and the Reserved one is")

t.finish
