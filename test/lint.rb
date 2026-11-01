# Checks the rules the Spinel compiler does not enforce by itself:
# the layer dependency rule, the plugin rule (a plugin requires only
# carat/plugin_api.rb and its own directory; the generated registry may
# require any plugin), forbidden constructs, and hard-coded bindings.
# Prints every violation; the snapshot is the empty report.
require_relative "../carat/testing"

t = Carat::Testing.new("lint")

# The rank of each layer: a file may name or require only its own rank or
# a lower one. The plugin API sits in the innermost ring beside the
# entities; ports rank below the use cases that depend on them; the
# doubles and the drivers both sit at the edge and never name each other.
LAYER_RANK = {
  "domain" => 0,
  "plugin_api" => 0,
  "ports" => 1,
  "use_cases" => 2,
  "adapters" => 3,
  "doubles" => 4,
  "drivers" => 4,
  "plugins" => 9
}

# The namespace that names each layer in code.
NAMESPACE_LAYER = [
  ["Domain::", "domain"],
  ["PluginApi::", "plugin_api"],
  ["Ports::", "ports"],
  ["UseCases::", "use_cases"],
  ["Adapters::", "adapters"],
  ["Doubles::", "doubles"],
  ["Drivers::", "drivers"],
  ["Plugins::", "plugins"]
]

FORBIDDEN = [
  ["eval(", "eval is not compiled by Spinel"],
  ["instance_eval", "instance_eval is not compiled by Spinel"],
  ["class_eval", "class_eval is not compiled by Spinel"],
  ["method_missing", "method_missing is not compiled by Spinel"],
  ["define_method", "define_method under a runtime condition is refused by Spinel"],
  ["instance_variable_get", "computed ivar access is not compiled by Spinel"],
  ["instance_variable_set", "computed ivar access is not compiled by Spinel"],
  ["const_get", "runtime constant lookup is not compiled by Spinel"],
  ["IO.popen", "IO.popen is refused by Spinel; use Process.spawn with IO.pipe"],
  ["require \"json\"", "use Carat::Json, Spinel bundles no json library"],
  ["require 'json'", "use Carat::Json, Spinel bundles no json library"],
  ["Ractor", "Ractor is not available in Spinel"]
]

# A buffer's line array changes only inside carat/domain/buffer.rb,
# through its primitives. Anywhere else, in the library, the executables,
# and the tests, assigning lines, assigning one of its elements, or calling
# a mutating method on it is a violation.
LINES_MUTATORS = ["<<", ".insert(", ".delete_at(", ".push(", ".append(", ".prepend(", ".pop", ".shift", ".unshift(", ".concat(", ".clear", ".replace(", ".slice!(", ".delete(", ".delete_if", ".keep_if", ".fill(", ".map!", ".collect!", ".select!", ".filter!", ".reject!", ".sort!", ".sort_by!", ".reverse!", ".compact!", ".flatten!", ".uniq!", ".rotate!", ".shuffle!"]

def assigns?(tail)
  tail.start_with?("=") && !tail.start_with?("==") && !tail.start_with?("=~")
end

def lines_mutation?(stripped)
  rest = stripped
  at = rest.index(".lines")
  until at.nil?
    rest = rest[(at + 6)..-1]
    unless rest.match?(/\A[A-Za-z0-9_?!]/)
      tail = rest.lstrip
      return true if assigns?(tail)
      if tail.start_with?("[")
        close = tail.index("]")
        return true if !close.nil? && assigns?(tail[(close + 1)..-1].lstrip)
      end
      LINES_MUTATORS.each { |m| return true if tail.start_with?(m) }
    end
    at = rest.index(".lines")
  end
  false
end

# A plugin names nothing of the editor's layers, even without requiring
# it: the namespaces of the entities, use cases, adapters, drivers, and
# doubles are refused outside comments.
PLUGIN_REFERENCES = ["Domain::", "UseCases::", "Adapters::", "Drivers::", "Doubles::"]

def plugin_reference?(stripped)
  return false if stripped.start_with?("#")
  PLUGIN_REFERENCES.each { |name| return true if stripped.include?(name) }
  false
end

# A concern (a module under carat/<layer>/concerns/) holds behavior only:
# no instance variables, no constructor, no extend, no included hook, and
# no define_method; the reason for a refused line, or "".
def concern_problem(stripped)
  return "" if stripped.start_with?("#")
  return "a concern has no instance variables" if stripped.match?(/(^|[^A-Za-z0-9_"])@[a-z_]/)
  return "a concern has no constructor" if stripped.start_with?("def initialize")
  return "a concern does not extend" if stripped.start_with?("extend ")
  return "a concern has no included hook" if stripped.include?("included do")
  return "a concern does not define methods at run time" if stripped.include?("define_method")
  ""
end

# The names of the methods a class body in text defines, from the line
# opening the class to the end of its indentation level.
def defs_of(text, opener)
  names = []
  inside = false
  indent = 0
  text.each_line do |line|
    if !inside && line.strip.start_with?(opener)
      inside = true
      indent = line[/\A */].length
      next
    end
    next unless inside
    break if line.strip == "end" && line[/\A */].length == indent
    stripped = line.strip
    if stripped.start_with?("def ") && line[/\A */].length == indent + 2
      names << stripped.sub("def ", "").split("(")[0].strip
    end
  end
  names
end

def layer_of(path)
  return "plugin_api" if path == "carat/plugin_api.rb"
  parts = path.split("/")
  return nil unless parts[0] == "carat" && parts.length > 2
  parts[1]
end

# The code of a line: string literals emptied and a trailing comment
# dropped, so a namespace inside a string or a comment is not a reference.
def code_of(line)
  out = +""
  quote = ""
  i = 0
  while i < line.length
    ch = line[i, 1]
    if quote.empty?
      break if ch == "#"
      quote = ch if ch == "\"" || ch == "'"
      out << ch
    elsif ch == "\\"
      i += 1
    elsif ch == quote
      quote = ""
      out << ch
    end
    i += 1
  end
  out
end

# Why a line of code in a file of the layer names a layer it may not, or
# "": a lower layer naming a higher one, the doubles and the drivers
# naming each other, and the plugin API naming any layer.
def reference_problem(from_layer, code)
  return "" unless LAYER_RANK.key?(from_layer) && from_layer != "plugins"
  NAMESPACE_LAYER.each do |namespace, layer|
    next unless code.include?(namespace)
    next if layer == from_layer
    return "the plugin API names no layer" if from_layer == "plugin_api"
    return "#{from_layer} may not name #{layer} (outer layer)" if LAYER_RANK[layer] > LAYER_RANK[from_layer]
    return "#{from_layer} may not name #{layer} (the doubles and the drivers stay apart)" if LAYER_RANK[layer] == 4 && LAYER_RANK[from_layer] == 4
  end
  ""
end

def source_files
  files = []
  files.concat(Dir.glob("carat.rb"))
  files.concat(Dir.glob("carat/**/*.rb"))
  files.concat(Dir.glob("bin/*.rb"))
  files.sort
end

# ------------------------------------------------------------- naming
#
# Ruby's naming conventions, the mechanical part: one public class or
# module per file, named after the file, in the namespace of its layer
# directory (feature subdirectories add none; a plugin's directory adds
# Plugins::<Name>); CamelCase classes; upper snake case constants;
# snake_case methods without unclear abbreviations; predicates ending in
# "?" and returning bool, and no get_, is_, or has_; "!" only beside its
# safe twin; no set_ method taking one value; alternate constructors
# named from_; and the suffixes of handlers, ports, doubles, and concerns.

LAYER_MODULE = {
  "domain" => "Domain",
  "ports" => "Ports",
  "use_cases" => "UseCases",
  "adapters" => "Adapters",
  "drivers" => "Drivers",
  "doubles" => "Doubles"
}

# Files that do not declare one class named after them, and why.
DECLARATION_EXCEPTIONS = {
  "carat/domain/json.rb" => "Carat::Json, the shared JSON library of architecture section 5.4",
  "carat/domain/default_config.rb" => "generated, a constant only"
}

ABBREVIATIONS = ["cls", "fwd", "bck", "bckend", "inc", "dec", "ws", "buf", "cnt", "idx", "tmp", "msg", "cmd", "num", "str", "val", "obj", "mgr", "ctx"]

# Methods that return bool but are commands, not questions: the result
# says whether the command did something.
BOOL_COMMANDS = {
  "pump" => "reads and handles the keys that are ready",
  "handle" => "handles decoded keys",
  "begin_transaction" => "opens a transaction",
  "decode_escape" => "decodes an escape sequence",
  "decode_csi" => "decodes a CSI sequence",
  "decode_utf8" => "decodes a UTF-8 sequence",
  "reveal" => "expands the tree down to a path",
  "next_tab" => "moves to the next tab page",
  "resized" => "reads and clears the resize flag",
  "terminated" => "reads and clears the termination flag",
  "flag" => "reads a boolean option from the configuration",
  "forward_word" => "a word motion step",
  "backward_word" => "a word motion step",
  "end_word" => "a word motion step",
  "backward_word_end" => "a word motion step",
  "skip_class" => "a word motion step",
  "register" => "registers a handler",
  "register_namespace" => "registers the namespace handler"
}

# Files whose set_ methods are the plugin API's request names.
SET_EXCEPTIONS = ["carat/plugin_api.rb", "carat/use_cases/plugins/plugin_link.rb"]

# Classes under carat/doubles/ that are not doubles, and why.
DOUBLE_EXCEPTIONS = { "EditorHarness" => "assembles the editor over the doubles; it is not one" }

def camel(snake)
  out = +""
  snake.split("_").each { |part| out << part[0, 1].upcase << part[1, part.length - 1] }
  out
end

# The namespace modules a file under carat/ opens and the class or module
# it must declare, or [] when the rule does not apply.
def expected_declaration(path)
  return [] if DECLARATION_EXCEPTIONS.key?(path)
  parts = path.split("/")
  return [] unless parts[0] == "carat" && parts.length > 2
  base = camel(File.basename(path, ".rb"))
  if parts[1] == "plugins"
    return [["Carat", "Plugins"], base] if parts.length == 3
    return [["Carat", "Plugins", camel(parts[2])], base] if parts.length == 4
    return []
  end
  return [] unless LAYER_MODULE.key?(parts[1])
  [["Carat", LAYER_MODULE[parts[1]]], base]
end

# The name a class or module line declares, "" for another line.
def declared_name(stripped)
  return "" unless stripped.start_with?("class ") || stripped.start_with?("module ")
  stripped.split(" ")[1].split("(")[0].split("<")[0].strip
end

# The problems of a file's declarations: the namespace modules it opens,
# and exactly one class or module at the namespace level, named after the
# file.
def declaration_problems(lines, namespaces, expected)
  problems = []
  depth = namespaces.length
  i = 0
  while i < depth
    want = (" " * (2 * i)) + "module " + namespaces[i]
    problems << "opens no module #{namespaces[0, i + 1].join("::")}" unless lines.any? { |l| l.rstrip == want }
    i += 1
  end
  declared = []
  lines.each do |l|
    indent = l.length - l.lstrip.length
    name = declared_name(l.strip)
    declared << name if !name.empty? && indent == 2 * depth
  end
  if declared.length != 1
    problems << "declares #{declared.length} classes or modules at its namespace level (#{declared.join(", ")}); one per file"
  elsif declared[0] != expected
    problems << "declares #{declared[0]} where the file name says #{expected}"
  end
  problems
end

# Why a class or module name declared in the file breaks a rule, or "".
def class_problem(path, stripped)
  name = declared_name(stripped)
  return "" if name.empty?
  return "class and module names are CamelCase" unless name.match?(/\A[A-Z][A-Za-z0-9]*\z/)
  handler = stripped.match?(/<\s*(Carat::)?(UseCases::)?(ActionHandler|ExHandler)\b/)
  return "a handler's name ends in Handler" if handler && !name.end_with?("Handler")
  return "a port's name ends in Port" if path.start_with?("carat/ports/") && stripped.start_with?("class ") && !name.end_with?("Port")
  if path.start_with?("carat/doubles/") && stripped.start_with?("class ") && !DOUBLE_EXCEPTIONS.key?(name)
    return "a double's name starts with Fake, Memory, Manual, or Fixed" unless name.match?(/\A(Fake|Memory|Manual|Fixed)/)
  end
  if path.include?("/concerns/") && stripped.start_with?("module ") && name != "Carat" && !LAYER_MODULE.values.include?(name)
    return "a concern is named by an adjective or an -ing word" unless name.match?(/(ed|ing|able|ible)\z/)
  end
  ""
end

# Why a constant assignment breaks the upper snake case rule, or "".
def constant_problem(stripped)
  return "" unless stripped.match?(/\A[A-Z][A-Za-z0-9_]* = /)
  name = stripped.split(" ")[0]
  name.match?(/\A[A-Z][A-Z0-9_]*\z/) ? "" : "constants are upper snake case"
end

# The method name of a def line, without self., "" for another line.
def method_name(stripped)
  return "" unless stripped.start_with?("def ")
  rest = stripped[4, stripped.length - 4]
  rest = rest[5, rest.length - 5] if rest.start_with?("self.")
  rest.split("(")[0].split(" ")[0]
end

# The number of parameters of a def line.
def parameter_count(stripped)
  open = stripped.index("(")
  return 0 if open.nil?
  inner = stripped[open + 1, stripped.length - open - 1].split(")")[0].to_s.strip
  inner.empty? ? 0 : inner.split(",").length
end

# Why a method's name breaks a rule, or "", given its def line, the return
# type its signature names ("" when none), and the text of its file.
def method_problem(path, stripped, returns, text)
  name = method_name(stripped)
  return "" if name.empty? || !name.match?(/\A[a-z_]/)
  return "method names are snake_case" unless name.match?(/\A[a-z_][a-z0-9_]*[?!=]?\z/)
  return "a predicate ends in ? instead of starting with get_, is_, or has_" if name.match?(/\A(get|is|has)_/)
  bare = name.delete("?!=")
  bare.split("_").each { |part| return "#{part} is an unclear abbreviation" if ABBREVIATIONS.include?(part) }
  return "a predicate returns bool" if name.end_with?("?") && !returns.empty? && returns != "bool"
  if returns == "bool" && !name.end_with?("?") && !BOOL_COMMANDS.key?(name)
    return "a method returning bool is a predicate ending in ?, or a command listed in BOOL_COMMANDS"
  end
  if name.end_with?("!")
    twin = name[0, name.length - 1]
    has_twin = text.include?("def #{twin}(") || text.include?("def #{twin}\n") || text.include?("def self.#{twin}(") || text.include?("def self.#{twin}\n")
    return "#{name} has no safe twin #{twin}" unless has_twin
  end
  return "a setter of one value is name=, not set_name" if name.start_with?("set_") && parameter_count(stripped) == 1 && !SET_EXCEPTIONS.include?(path)
  if stripped.start_with?("def self.") && (["build", "create", "make"].include?(name) || name.match?(/\A(new_|build_from|create_from|make_from)/))
    return "an alternate constructor is a from_ class method"
  end
  ""
end

# ------------------------------------------------------- constructors
#
# A behavior class takes its collaborators as required keyword
# arguments, built once in the composition root; a default only for a
# collaborator that takes no arguments, keeps no state, and does no I/O.
# Records keep positional construction. The files below still take
# positional arguments and are converted by the state-and-ports change;
# the list only shrinks.
PENDING_CONSTRUCTORS = [
  "carat/adapters/input_controller.rb",
  "carat/adapters/screen_presenter.rb",
  "carat/domain/json.rb",
  "carat/doubles/fake_terminal.rb",
  "carat/drivers/ansi_terminal.rb",
  "carat/drivers/main_loop.rb",
  "carat/use_cases/files/file_ops.rb",
  "carat/use_cases/files/open_file.rb",
  "carat/use_cases/files/quit.rb",
  "carat/use_cases/plugins/buffer_requests.rb",
  "carat/use_cases/plugins/file_requests.rb",
  "carat/use_cases/plugins/plugin_events.rb",
  "carat/use_cases/plugins/plugin_link.rb",
  "carat/use_cases/plugins/plugin_registry.rb",
  "carat/use_cases/plugins/ui_requests.rb",
  "carat/use_cases/plugins/window_requests.rb",
  "carat/use_cases/windows/open_tab.rb",
  "carat/use_cases/windows/split_window.rb"
]

# Why a constructor's parameters are not required keywords, or "".
def constructor_problem(stripped)
  return "" unless stripped.start_with?("def initialize(")
  inner = stripped[15, stripped.length - 15].split(")")[0].to_s
  inner.split(",").each do |param|
    return "a constructor takes keyword arguments" unless param.strip.match?(/\A[a-z_][a-z0-9_]*:/)
  end
  ""
end

violations = []

# The plugin link overrides every request of the plugin API's host.
host_methods = defs_of(File.read("carat/plugin_api.rb"), "class Host")
link_methods = defs_of(File.read("carat/use_cases/plugins/plugin_link.rb"), "class PluginLink")
host_methods.each do |name|
  violations << "carat/use_cases/plugins/plugin_link.rb: PluginLink does not override Host##{name}" unless link_methods.include?(name)
end

source_files.each do |path|
  text = File.read(path)
  next if path == "carat/domain/default_config.rb" # generated, data only
  from_layer = layer_of(path)

  concern = path.include?("/concerns/")
  if concern && !text.include?("Readers the including class provides:")
    violations << "#{path}: a concern lists the readers it depends on"
  end
  text.each_line.with_index(1) do |line, number|
    stripped = line.strip
    if concern && stripped.start_with?("#:")
      violations << "#{path}:#{number}: a concern's methods carry # @rbs skip, since a signature on a mixed-in method is not applied"
    end
    next if stripped.start_with?("#")
    if from_layer == "plugins" && plugin_reference?(stripped)
      violations << "#{path}:#{number}: a plugin names only the plugin API, never the editor's layers"
    end
    if from_layer
      problem = reference_problem(from_layer, code_of(stripped))
      violations << "#{path}:#{number}: #{problem}" unless problem.empty?
    end
    if concern
      problem = concern_problem(stripped)
      violations << "#{path}:#{number}: #{problem}" unless problem.empty?
    end
    FORBIDDEN.each do |pattern, reason|
      violations << "#{path}:#{number}: #{reason}" if stripped.include?(pattern)
    end
    if stripped.include?(".send(") && !stripped.include?(".send(:")
      violations << "#{path}:#{number}: send with a computed name is not compiled by Spinel"
    end
    if stripped.start_with?("require_relative ") && from_layer
      target = stripped.sub("require_relative ", "").delete("\"'")
      full = File.expand_path(target, File.dirname(path)).sub(Dir.pwd + "/", "") + ".rb"
      to_layer = layer_of(full)
      if from_layer == "plugins"
        own_dir = path == "carat/plugins/registry.rb" ? "carat/plugins/" : File.dirname(path) + "/"
        unless full == "carat/plugin_api.rb" || full.start_with?(own_dir)
          violations << "#{path}:#{number}: a plugin may require only carat/plugin_api.rb and files in its own directory"
        end
      elsif to_layer && LAYER_RANK.key?(to_layer) && LAYER_RANK.key?(from_layer)
        if from_layer == "plugin_api"
          violations << "#{path}:#{number}: the plugin API requires nothing"
        elsif LAYER_RANK[to_layer] > LAYER_RANK[from_layer]
          violations << "#{path}:#{number}: #{from_layer} may not require #{to_layer} (outer layer)"
        elsif to_layer != from_layer && LAYER_RANK[to_layer] == 4 && LAYER_RANK[from_layer] == 4
          violations << "#{path}:#{number}: #{from_layer} may not require #{to_layer} (the doubles and the drivers stay apart)"
        end
      end
    end
  end
end

# Naming and constructors, over every file of the library.
Dir.glob("carat/**/*.rb").sort.each do |path|
  next if path == "carat/domain/default_config.rb"
  text = File.read(path)
  lines = text.lines
  expected = expected_declaration(path)
  unless expected.empty?
    declaration_problems(lines, expected[0], expected[1]).each { |problem| violations << "#{path}: #{problem}" }
  end
  record = text.include?("< Struct.new(") || text.include?("< Data.define(")
  keywords = layer_of(path) && layer_of(path) != "plugins" && layer_of(path) != "plugin_api" && !record && !PENDING_CONSTRUCTORS.include?(path)
  lines.each_with_index do |line, i|
    stripped = line.strip
    next if stripped.start_with?("#")
    problem = class_problem(path, stripped)
    problem = constant_problem(stripped) if problem.empty?
    if problem.empty? && stripped.start_with?("def ")
      returns = ""
      above = i > 0 ? lines[i - 1].strip : ""
      returns = above.split("->").last.to_s.strip if above.start_with?("#:") && above.include?("->")
      problem = method_problem(path, stripped, returns, text)
      problem = constructor_problem(stripped) if problem.empty? && keywords
    end
    violations << "#{path}:#{i + 1}: #{problem}" unless problem.empty?
  end
end

edited = []
edited.concat(source_files)
edited.concat(Dir.glob("test/*.rb"))
edited.sort.each do |path|
  next if path == "carat/domain/buffer.rb"
  File.read(path).each_line.with_index(1) do |line, number|
    stripped = line.strip
    next if stripped.start_with?("#")
    violations << "#{path}:#{number}: only Buffer changes its lines; use the buffer primitives" if lines_mutation?(stripped)
  end
end

# Inline RBS: every method and attribute under carat/ carries a signature.
# A def is covered when the comment block directly above it (same indent,
# no blank line) contains a line starting with "#:" or "# @rbs".
# An attr_reader, attr_writer or attr_accessor needs a trailing "#:" type.
missing = []
Dir.glob("carat/**/*.rb").sort.each do |path|
  next if path == "carat/domain/default_config.rb"
  lines = File.read(path).lines
  lines.each_with_index do |line, i|
    stripped = line.strip
    if stripped.start_with?("def ") || stripped.start_with?("private def ") || stripped.start_with?("protected def ")
      indent = line[/\A */].length
      covered = false
      j = i - 1
      while j >= 0
        above = lines[j]
        break unless above[/\A */].length == indent && above.strip.start_with?("#")
        text = above.strip
        covered = true if text.start_with?("#:") || text.start_with?("# @rbs")
        j -= 1
      end
      missing << "#{path}:#{i + 1}: #{stripped[0, 40]} has no inline RBS signature" unless covered
    elsif stripped.start_with?("attr_reader ") || stripped.start_with?("attr_writer ") || stripped.start_with?("attr_accessor ")
      missing << "#{path}:#{i + 1}: #{stripped[0, 40]} has no trailing #: type" unless stripped.include?("#:")
    end
  end
end
missing.each { |m| STDOUT.puts m }

# The rules themselves, against a line each must refuse and one each must
# let through, so a broken rule fails here instead of passing silently.
t.assert_equal([true, true, false, false], [plugin_reference?("x = Carat::Domain::Buffer.new"), plugin_reference?("UseCases::PluginHost"), plugin_reference?("# Domain:: in a comment"), plugin_reference?("Carat::PluginApi::Paths.join(a, b)")], "the plugin reference rule")
t.assert_equal(["a concern has no instance variables", "a concern has no constructor", "a concern does not extend", "a concern has no included hook", "a concern does not define methods at run time", ""], [concern_problem("@count += 1"), concern_problem("def initialize"), concern_problem("extend Other"), concern_problem("included do"), concern_problem("define_method(:x) { }"), concern_problem("registry.enter(entry.name)")], "the concern rules")
t.assert_equal(true, host_methods.length >= 27 && host_methods.include?("open_in_split") && link_methods.include?("open_in_tab"), "the link coverage rule reads both classes")
t.assert_equal(["a", "b"], defs_of("class X\n  def a\n  end\n  def b(x)\n  end\nend\nclass Y\n  def c\n  end\nend\n", "class X"), "defs_of reads one class body")

t.assert_equal(["", "", "use_cases may not name adapters (outer layer)", "domain may not name use_cases (outer layer)", "doubles may not name drivers (the doubles and the drivers stay apart)", "the plugin API names no layer", "ports may not name use_cases (outer layer)"], [reference_problem("use_cases", code_of("x = Domain::Buffer.new")), reference_problem("domain", code_of("show(\"UseCases::Outcome\") # UseCases::")), reference_problem("use_cases", code_of("Adapters::FramePresenter.new")), reference_problem("domain", code_of("UseCases::Outcome.none")), reference_problem("doubles", code_of("Drivers::DiskFiles.new")), reference_problem("plugin_api", code_of("Domain::Buffer")), reference_problem("ports", code_of("UseCases::Outcome"))], "the constant reference rule")
t.assert_equal([0, 0, 1, 2, 3, 4, 4], ["domain", "plugin_api", "ports", "use_cases", "adapters", "doubles", "drivers"].map { |layer| LAYER_RANK[layer] }, "the layer ranks")
t.assert_equal([[["Carat", "UseCases"], "WindowHandler"], [["Carat", "Plugins", "Explorer"], "FileIcons"], [], [["Carat", "Domain"], "ExName"]], [expected_declaration("carat/use_cases/actions/window_handler.rb"), expected_declaration("carat/plugins/explorer/file_icons.rb"), expected_declaration("carat/domain/json.rb"), expected_declaration("carat/domain/ex_name.rb")], "a file's namespace comes from its layer directory and its name from the file")
t.assert_equal([[], ["declares 2 classes or modules at its namespace level (A, B); one per file"], ["declares B where the file name says A"], ["opens no module Carat::Domain", "declares 0 classes or modules at its namespace level (); one per file"]], [declaration_problems(["module Carat\n", "  module Domain\n", "    class A\n", "      class Inner\n"], ["Carat", "Domain"], "A"), declaration_problems(["module Carat\n", "  module Domain\n", "    class A\n", "    class B\n"], ["Carat", "Domain"], "A"), declaration_problems(["module Carat\n", "  module Domain\n", "    class B < Data.define(:x)\n"], ["Carat", "Domain"], "A"), declaration_problems(["module Carat\n"], ["Carat", "Domain"], "A")], "the one class per file rule")
t.assert_equal(["", "class and module names are CamelCase", "a handler's name ends in Handler", "a port's name ends in Port", "a double's name starts with Fake, Memory, Manual, or Fixed", "", "a concern is named by an adjective or an -ing word", ""], [class_problem("carat/use_cases/x.rb", "class WindowHandler < ActionHandler"), class_problem("carat/domain/x.rb", "class Bad_Name"), class_problem("carat/use_cases/x.rb", "class Windows < ExHandler"), class_problem("carat/ports/x.rb", "class Terminal"), class_problem("carat/doubles/x.rb", "class StubFiles < Ports::FilePort"), class_problem("carat/doubles/x.rb", "class EditorHarness"), class_problem("carat/use_cases/concerns/x.rb", "module Report"), class_problem("carat/use_cases/concerns/x.rb", "module Reporting")], "the class name rules")
t.assert_equal(["", "constants are upper snake case", ""], [constant_problem("MAX_DEPTH = 4"), constant_problem("MaxDepth = 4"), constant_problem("x = MAX_DEPTH")], "the constant rule")
t.assert_equal(["", "cls is an unclear abbreviation", "a predicate ends in ? instead of starting with get_, is_, or has_", "a predicate returns bool", "a method returning bool is a predicate ending in ?, or a command listed in BOOL_COMMANDS", "", "child! has no safe twin child", "", "a setter of one value is name=, not set_name", "", "an alternate constructor is a from_ class method", "", "method names are snake_case"], [method_problem("x.rb", "def char_class(big)", "Integer", ""), method_problem("x.rb", "def cls(big)", "Integer", ""), method_problem("x.rb", "def is_open", "bool", ""), method_problem("x.rb", "def open?", "Integer", ""), method_problem("x.rb", "def open", "bool", ""), method_problem("x.rb", "def pump(state)", "bool", ""), method_problem("x.rb", "def child!(code)", "KeymapNode", "def child!(code)\n"), method_problem("x.rb", "def save!", "void", "def save\ndef save!\n"), method_problem("x.rb", "def set_root(path)", "void", ""), method_problem("x.rb", "def set_lines(from, to, lines)", "void", ""), method_problem("x.rb", "def self.build(keymaps, leader)", "Keymap", ""), method_problem("x.rb", "def self.from_config(keymaps, leader)", "Keymap", ""), method_problem("x.rb", "def readLine", "String", "")], "the method name rules")
t.assert_equal(["", "a constructor takes keyword arguments", "", ""], [constructor_problem("def initialize(actions:, files:)"), constructor_problem("def initialize(actions, files)"), constructor_problem("def initialize(store: Store.new)"), constructor_problem("def call(state, command)")], "the constructor rule")
t.assert_equal("x = \"\" ", code_of("x = \"Domain::Buffer\" # UseCases::"), "code drops strings and comments")
violations.each { |v| STDOUT.puts v }
t.assert_equal(0, violations.length, "no lint violations")
t.assert_equal(0, missing.length, "every method and attribute has an inline RBS signature")
t.finish
