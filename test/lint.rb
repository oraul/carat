# Checks the rules the Spinel compiler does not enforce by itself:
# the layer dependency rule, the plugin rule (a plugin requires only
# carat/plugin_api.rb and its own directory; the generated registry may
# require any plugin), forbidden constructs, hard-coded bindings, and the
# coverage of docs/codebase-map.md.
# Prints every violation; the snapshot is the empty report.
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module LintTest
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

  def self.assigns?(tail)
    tail.start_with?("=") && !tail.start_with?("==") && !tail.start_with?("=~")
  end

  def self.lines_mutation?(stripped)
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

  def self.plugin_reference?(stripped)
    return false if stripped.start_with?("#")
    PLUGIN_REFERENCES.each { |name| return true if stripped.include?(name) }
    false
  end

  # A concern (a module under carat/<layer>/concerns/) holds behavior only:
  # no instance variables, no constructor, no extend, no included hook, and
  # no define_method; the reason for a refused line, or "".
  def self.concern_problem(stripped)
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
  def self.defs_of(text, opener)
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

  def self.layer_of(path)
    return "plugin_api" if path == "carat/plugin_api.rb"
    parts = path.split("/")
    return nil unless parts[0] == "carat" && parts.length > 2
    parts[1]
  end

  # The code of a line: string literals emptied and a trailing comment
  # dropped, so a namespace inside a string or a comment is not a reference.
  def self.code_of(line)
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
  def self.reference_problem(from_layer, code)
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

  def self.source_files
    files = []
    files.concat(Dir.glob("carat.rb"))
    files.concat(Dir.glob("carat/**/*.rb"))
    files.concat(Dir.glob("bin/*.rb"))
    files.sort
  end

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
    "show" => "shows a language server on the bar, answering whether the slot changed",
    "hold" => "shows a language server waiting for :LspStart on the bar, answering whether the slot changed",
    "drain" => "handles the queued messages of the language servers, answering whether any",
    "set_lsp" => "sets the lsp slot, answering whether it changed",
    "count_diagnostics" => "counts a buffer's diagnostics into the diagnostics slot, answering whether a count changed",
    "read_header" => "reads a frame's headers, answering whether they are complete",
    "refuse" => "refuses a server's stream, answering false for the caller",
    "write_bytes" => "writes to a child's input, answering whether it took them",
    "tick" => "moves the start screen to the frame of the clock",
    "handle" => "handles decoded keys",
    "begin_transaction" => "opens a transaction",
    "decode_escape" => "decodes an escape sequence",
    "decode_csi" => "decodes a CSI sequence",
    "decode_utf8" => "decodes a UTF-8 sequence",
    "reveal" => "expands the tree down to a path",
    "next_tab" => "moves to the next tab page",
    "add" => "adds a floating window to its layer",
    "close" => "closes a floating window",
    "close_top" => "closes the topmost floating window",
    "close_focused" => "closes the focused floating window",
    "enter" => "focuses a floating window",
    "move" => "moves a floating window",
    "focus_buffer" => "focuses the first window showing a buffer",
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

  def self.camel(snake)
    out = +""
    snake.split("_").each { |part| out << part[0, 1].upcase << part[1, part.length - 1] }
    out
  end

  # The namespace modules a file under carat/ opens and the class or module
  # it must declare, or [] when the rule does not apply.
  def self.expected_declaration(path)
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
  def self.declared_name(stripped)
    return "" unless stripped.start_with?("class ") || stripped.start_with?("module ")
    stripped.split(" ")[1].split("(")[0].split("<")[0].strip
  end

  # The problems of a file's declarations: the namespace modules it opens,
  # and exactly one class or module at the namespace level, named after the
  # file.
  def self.declaration_problems(lines, namespaces, expected)
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
  def self.class_problem(path, stripped)
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
  def self.constant_problem(stripped)
    return "" unless stripped.match?(/\A[A-Z][A-Za-z0-9_]* = /)
    name = stripped.split(" ")[0]
    name.match?(/\A[A-Z][A-Z0-9_]*\z/) ? "" : "constants are upper snake case"
  end

  # The method name of a def line, without self., "" for another line.
  def self.method_name(stripped)
    return "" unless stripped.start_with?("def ")
    rest = stripped[4, stripped.length - 4]
    rest = rest[5, rest.length - 5] if rest.start_with?("self.")
    rest.split("(")[0].split(" ")[0]
  end

  # The number of parameters of a def line.
  def self.parameter_count(stripped)
    open = stripped.index("(")
    return 0 if open.nil?
    inner = stripped[open + 1, stripped.length - open - 1].split(")")[0].to_s.strip
    inner.empty? ? 0 : inner.split(",").length
  end

  # Why a method's name breaks a rule, or "", given its def line, the return
  # type its signature names ("" when none), and the text of its file.
  def self.method_problem(path, stripped, returns, text)
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

  # Why a constructor's parameters are not required keywords, or "".
  def self.constructor_problem(stripped)
    return "" unless stripped.start_with?("def initialize(")
    inner = stripped[15, stripped.length - 15].split(")")[0].to_s
    inner.split(",").each do |param|
      return "a constructor takes keyword arguments" unless param.strip.match?(/\A[a-z_][a-z0-9_]*:/)
    end
    ""
  end

  # ------------------------------------------------------------ records
  #
  # Every record is built with keyword arguments. A Struct record is
  # declared with keyword_init: true, so a positional call raises when it
  # runs; Data accepts both forms silently, so every construction of a
  # record, Struct or Data, is read too: its arguments start with a
  # keyword or close empty.

  # Why a line of code declaring a Struct record breaks the rule, or "".
  def self.struct_problem(code)
    return "" unless code.include?("< Struct.new(")
    code.include?(", keyword_init: true)") ? "" : "a Struct record is declared with keyword_init: true"
  end

  # The names of the record classes a text declares, Struct or Data.
  def self.record_names(text)
    names = []
    text.each_line do |line|
      stripped = line.strip
      next unless stripped.start_with?("class ")
      next unless stripped.include?("< Struct.new(") || stripped.include?("< Data.define(")
      names << declared_name(stripped)
    end
    names
  end

  # Whether the arguments of a call, the code after its opening
  # parenthesis, start with a keyword or close empty.
  def self.keyword_arguments?(rest)
    rest.lstrip.match?(/\A(\)|[a-z_][a-z0-9_]*: )/)
  end

  # Why a line of code builds a record with positional arguments, or "",
  # given the record names, whether its file declares a record (where a
  # bare new( builds one), and the next line of code, which is read when
  # the arguments start there. A name that is the tail of a longer one,
  # Node in LayoutNode, is not a call of that record.
  def self.construction_problem(code, names, own, following)
    starts = []
    names.each do |name|
      pattern = name + ".new("
      at = code.index(pattern)
      until at.nil?
        before = at > 0 ? code[at - 1, 1].to_s : ""
        starts << at + pattern.length unless before.match?(/[A-Za-z0-9_]/)
        at = code.index(pattern, at + 1)
      end
    end
    if own
      at = code.index("new(")
      until at.nil?
        before = at > 0 ? code[at - 1, 1].to_s : ""
        starts << at + 4 unless before.match?(/[A-Za-z0-9_.:]/)
        at = code.index("new(", at + 1)
      end
    end
    starts.each do |from|
      rest = code[from, code.length - from].to_s
      rest = following if rest.strip.empty?
      return "a record is built with keyword arguments" unless keyword_arguments?(rest)
    end
    ""
  end

  # ------------------------------------------------------------ doubles
  #
  # The test doubles are not part of the production require graph: only
  # files under carat/doubles/ and carat/test_support.rb, the require graph
  # of test and benchmark programs, may require one.
  TEST_SUPPORT = "carat/test_support.rb"

  # Why a file may not require the target path (both relative to the
  # repository, the target with its .rb), or "".
  def self.double_require_problem(path, target)
    return "" unless target.start_with?("carat/doubles/")
    return "" if path.start_with?("carat/doubles/") || path == TEST_SUPPORT
    return "" unless path.start_with?("bin/") || path.start_with?("carat/") || path == "carat.rb"
    "only carat/doubles/ and #{TEST_SUPPORT} may require a test double"
  end

  # ------------------------------------------------------- use cases
  #
  # A use case exposes one public instance method, call, besides
  # initialize and the readers the shared-instance test needs; every other
  # method is private. The rule leaves out what is not a use case: the
  # handlers and their bases (input ports with call and a register
  # function), the two tables, the CommandRunner interface, Outcome,
  # records, concerns, and the plugin host under use_cases/plugins/, whose
  # request families are the adapter of PluginApi::Host by design and
  # whose registry, entries, and events move out of use_cases with the
  # host (docs/backlog.md). Spinel compiles private_constant without
  # enforcing it, so the lint keeps every constant of a use case file
  # private and no file outside it reading one.
  ONE_CALL_EXEMPT = [
    "carat/use_cases/actions/action_table.rb", "carat/use_cases/actions/action_handler.rb",
    "carat/use_cases/ex/ex_table.rb", "carat/use_cases/ex/ex_handler.rb", "carat/use_cases/ex/command_runner.rb",
    "carat/use_cases/outcome.rb"
  ]

  # Whether the one-call rule leaves the file out.
  def self.one_call_exempt?(path, text)
    return true unless path.start_with?("carat/use_cases/")
    return true if path.include?("/concerns/") || path.start_with?("carat/use_cases/plugins/")
    return true if ONE_CALL_EXEMPT.include?(path)
    return true if text.include?("< Data.define(") || text.include?("< Struct.new(")
    text.include?(" < ActionHandler") || text.include?(" < ExHandler")
  end

  # The public instance methods of a use case other than initialize and
  # call, and its public writers, each as a problem; a class method and
  # an attr_reader are allowed.
  def self.one_call_problems(lines)
    problems = []
    hidden = false
    lines.each do |line|
      stripped = line.to_s.strip
      next if stripped.start_with?("#")
      hidden = true if stripped == "private"
      next if hidden
      if stripped.start_with?("attr_writer ") || stripped.start_with?("attr_accessor ")
        problems << "a use case has no public writer (#{stripped.split(" ")[1]})"
      elsif stripped.start_with?("def ") && !stripped.start_with?("def self.")
        name = method_name(stripped)
        problems << "a use case exposes only call; #{name} is public" unless name == "initialize" || name == "call"
      end
    end
    problems
  end

  # The constants a file assigns at the start of a line.
  def self.constants_of(text)
    names = []
    text.each_line do |line|
      stripped = line.to_s.strip
      names << stripped.split(" ")[0] if stripped.match?(/\A[A-Z][A-Z0-9_]* = /)
    end
    names
  end

  # The constants of a use case file missing from its private_constant
  # lines, each as a problem.
  def self.private_constant_problems(text)
    listed = []
    text.each_line do |line|
      stripped = line.to_s.strip
      next unless stripped.start_with?("private_constant ")
      stripped.sub("private_constant ", "").split(",").each { |name| listed << name.strip.delete_prefix(":") }
    end
    problems = []
    constants_of(text).each { |name| problems << "#{name} is not listed in a private_constant" unless listed.include?(name) }
    problems
  end

  # Whether a line of code names the constant of a class as Class::CONST,
  # with or without a namespace before the class.
  def self.constant_read?(code, klass, constant)
    target = "#{klass}::#{constant}"
    at = code.index(target)
    while at
      before = at > 0 ? code[at - 1, 1] : ""
      after = code[at + target.length, 1].to_s
      return true unless before.match?(/[A-Za-z0-9_]/) || after.match?(/[A-Za-z0-9_]/)
      at = code.index(target, at + 1)
    end
    false
  end

  # The code map, docs/codebase-map.md, names every file under carat/, bin/,
  # test/, bench/, and tools/, and carat.rb, in an area; a test's snapshot
  # is covered by its test. A path the map names under those roots exists.
  MAP = "docs/codebase-map.md"
  MAP_ROOTS = ["carat", "bin", "test", "bench", "tools"]

  # The code spans of a Markdown text: what stands between pairs of
  # backticks.
  def self.map_spans(text)
    spans = []
    parts = text.split("`")
    i = 1
    while i < parts.length
      spans << parts[i].to_s
      i += 2
    end
    spans
  end

  # Whether a code span reads as a file path under the map's roots.
  def self.map_file?(span)
    span == "carat.rb" || span.match?(/\A(carat|bin|test|bench|tools)\/[a-z0-9_.\/-]*[a-z0-9]\z/)
  end

  # The files the map must cover, sorted.
  def self.map_files
    files = ["carat.rb"]
    MAP_ROOTS.each do |root|
      Dir.glob(root + "/**/*").each { |path| files << path.to_s unless File.directory?(path) }
    end
    files.sort
  end

  # One line per file in no area and per named path that does not exist.
  def self.map_problems(files, spans)
    problems = []
    files.each do |path|
      owner = path.end_with?(".rb.expected") ? path[0, path.length - ".expected".length].to_s : path
      problems << "#{path} is in no area of #{MAP}" unless spans.include?(owner)
    end
    spans.each do |span|
      next unless map_file?(span)
      problems << "#{MAP} names #{span}, which does not exist" unless files.include?(span)
    end
    problems
  end

  def self.main
    t = Carat::Testing.new("lint")

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

    # ------------------------------------------------------- constructors
    #
    # A behavior class takes its collaborators as required keyword
    # arguments, built once in the composition root; a default only for a
    # collaborator that takes no arguments, keeps no state, and does no I/O.
    # Every behavior class follows the rule, and so does every record's
    # initialize; the shared-instance test in test/adapters_assembly.rb
    # checks that the composition root hands each shared object to all its
    # holders.

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
        if stripped.start_with?("require_relative ")
          target = stripped.sub("require_relative ", "").delete("\"'")
          full = File.expand_path(target, File.dirname(path)).sub(Dir.pwd + "/", "") + ".rb"
          problem = double_require_problem(path, full)
          violations << "#{path}:#{number}: #{problem}" unless problem.empty?
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
      keywords = (layer_of(path) && layer_of(path) != "plugins" && layer_of(path) != "plugin_api") || record
      one_call_problems(lines).each { |problem| violations << "#{path}: #{problem}" } unless one_call_exempt?(path, text)
      private_constant_problems(text).each { |problem| violations << "#{path}: #{problem}" } if path.start_with?("carat/use_cases/")
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

    # No file reads a use case's constant from outside the use case's
    # file: the constants shared by several use cases live in the domain.
    owned = []
    Dir.glob("carat/use_cases/**/*.rb").sort.each do |path|
      expected = expected_declaration(path)
      next if expected.empty?
      constants_of(File.read(path).to_s).each { |name| owned << [path, expected[1].to_s, name] }
    end
    readers = []
    readers.concat(Dir.glob("carat/**/*.rb"))
    readers.concat(Dir.glob("bin/*.rb"))
    readers.concat(Dir.glob("test/**/*.rb"))
    readers.concat(Dir.glob("bench/*.rb"))
    readers.sort.each do |path|
      next if path == "test/lint.rb"
      File.read(path).to_s.each_line.with_index(1) do |line, number|
        stripped = line.to_s.strip
        next if stripped.start_with?("#")
        code = code_of(stripped)
        next unless code.include?("::")
        owned.each do |home, klass, name|
          next if home == path
          violations << "#{path}:#{number}: #{klass}::#{name} is private to #{home}; a shared constant lives in the domain" if constant_read?(code, klass.to_s, name.to_s)
        end
      end
    end

    edited = []
    edited.concat(source_files)
    edited.concat(Dir.glob("test/*.rb"))
    edited.sort.each do |path|
      next if path == "carat/domain/buffer.rb"
      # In the test runner, with every other test in the program, the line
      # each_line.with_index yields is untyped, so it is converted before
      # the helper, which would widen otherwise.
      File.read(path).each_line.with_index(1) do |line, number|
        stripped = line.strip
        next if stripped.start_with?("#")
        violations << "#{path}:#{number}: only Buffer changes its lines; use the buffer primitives" if lines_mutation?(stripped.to_s)
      end
    end

    # Records: keyword_init on every Struct record, and keyword arguments
    # at every construction of a record, in the library, the executables,
    # the tests, and the benchmark.
    built = []
    built.concat(source_files)
    built.concat(Dir.glob("test/*.rb"))
    built.concat(Dir.glob("bench/*.rb"))
    built.sort!
    names = []
    built.each { |path| names.concat(record_names(File.read(path).to_s)) }
    built.each do |path|
      text = File.read(path).to_s
      own = !record_names(text).empty?
      lines = text.lines
      lines.each_with_index do |line, i|
        stripped = line.to_s.strip
        next if stripped.start_with?("#")
        code = code_of(stripped)
        following = i + 1 < lines.length ? code_of(lines[i + 1].to_s.strip) : ""
        problem = struct_problem(code)
        problem = construction_problem(code, names, own, following) if problem.empty?
        violations << "#{path}:#{i + 1}: #{problem}" unless problem.empty?
      end
    end

    # The code map covers every file of the five roots and names no missing one.
    map_problems(map_files, map_spans(File.read(MAP).to_s)).each { |problem| violations << problem }

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
    t.assert_equal(["", "only carat/doubles/ and carat/test_support.rb may require a test double", "only carat/doubles/ and carat/test_support.rb may require a test double", "", "", ""], [double_require_problem("carat/doubles/editor_harness.rb", "carat/doubles/fake_terminal.rb"), double_require_problem("carat.rb", "carat/doubles/fake_terminal.rb"), double_require_problem("bin/carat.rb", "carat/doubles/memory_files.rb"), double_require_problem("carat/test_support.rb", "carat/doubles/manual_signals.rb"), double_require_problem("carat/adapters/editor_assembly.rb", "carat/use_cases/move.rb"), double_require_problem("test/editor_normal.rb", "carat/doubles/fake_terminal.rb")], "the double require rule")
    t.assert_equal(false, File.read("carat.rb").include?("doubles/"), "the production require graph names no double")
    t.assert_equal(["", "a Struct record is declared with keyword_init: true", ""], [struct_problem("class Cursor < Struct.new(:row, :col, keyword_init: true)"), struct_problem("class Cursor < Struct.new(:row, :col)"), struct_problem("class Position < Data.define(:row, :col)")], "the keyword_init rule")
    t.assert_equal(["Cursor", "Position"], record_names("class Cursor < Struct.new(:row, keyword_init: true)\n  class Position < Data.define(:row)\nclass Other\n"), "record_names reads Struct and Data declarations")
    t.assert_equal(["", "a record is built with keyword arguments", "", "a record is built with keyword arguments", "", "", "a record is built with keyword arguments", "", ""], [construction_problem("c = Cursor.new(row: 0, col: 0)", ["Cursor"], false, ""), construction_problem("c = D::Cursor.new(0, 0)", ["Cursor"], false, ""), construction_problem("n = LayoutNode.new(kind)", ["Node"], false, ""), construction_problem("new(text, codes)", ["DecodedLine"], true, ""), construction_problem("o = Options.new", ["Options"], false, ""), construction_problem("Manifest.new(", ["Manifest"], false, "name: \"\","), construction_problem("Manifest.new(", ["Manifest"], false, "\"\","), construction_problem("x = Array.new(3, 0)", ["Cursor"], true, ""), construction_problem("e = Event.new()", ["Event"], false, "")], "the record construction rule")
    t.assert_equal("x = \"\" ", code_of("x = \"Domain::Buffer\" # UseCases::"), "code drops strings and comments")
    violations.each { |v| STDOUT.puts v }
    t.assert_equal([true, true, true, true, false], [one_call_exempt?("carat/use_cases/actions/window_handler.rb", "    class WindowHandler < ActionHandler\n"), one_call_exempt?("carat/use_cases/windows/focus_request.rb", "    class FocusRequest < Data.define(:target, :count)\n"), one_call_exempt?("carat/use_cases/plugins/plugin_host.rb", "    class PluginHost\n"), one_call_exempt?("carat/use_cases/outcome.rb", "    class Outcome\n"), one_call_exempt?("carat/use_cases/operate.rb", "    class Operate\n")], "the one-call rule leaves out handlers, records, the plugin host, and Outcome")
    t.assert_equal([["a use case exposes only call; other is public", "a use case has no public writer (:mode)"], []], [one_call_problems(["class X\n", "attr_reader :tabs\n", "def initialize(tabs:)\n", "def call(state)\n", "def self.build(x)\n", "def other(state)\n", "attr_writer :mode\n", "private\n", "def helper\n"]), one_call_problems(["class X\n", "def call(state)\n", "private\n", "def helper(state)\n"])], "the one-call rule")
    t.assert_equal([["B is not listed in a private_constant"], []], [private_constant_problems("A = 1\nB = \"b\"\nprivate_constant :A\n"), private_constant_problems("A = 1\nB = 2\nprivate_constant :A, :B\nx = A\n")], "the private constant rule")
    t.assert_equal([true, true, false, false, false], [constant_read?("x = Operate::DELETE", "Operate", "DELETE"), constant_read?("x = UseCases::Operate::DELETE", "Operate", "DELETE"), constant_read?("x = MyOperate::DELETE", "Operate", "DELETE"), constant_read?("x = Operate::DELETED", "Operate", "DELETE"), constant_read?("x = Domain::OperatorKind::DELETE", "Operate", "DELETE")], "the constant read rule")
    t.assert_equal(["test/b.rb is in no area of docs/codebase-map.md", "test/b.rb.expected is in no area of docs/codebase-map.md", "docs/codebase-map.md names carat/gone.rb, which does not exist"], map_problems(["carat.rb", "carat/a.rb", "test/a.rb", "test/a.rb.expected", "test/b.rb", "test/b.rb.expected"], map_spans("- `carat.rb` and `carat/a.rb`: x, `test/a.rb`, `carat/gone.rb`, `carat/use_cases/`, `test/NAME.rb`, `make test`")), "the code map rule")
    t.assert_equal(true, map_files.include?("tools/noruby/ruby") && map_files.include?("test/runner/run_all.rb") && !map_files.include?("tools/noruby"), "the code map rule reads files in subdirectories and no directory")
    t.assert_equal(0, violations.length, "no lint violations")
    t.assert_equal(0, missing.length, "every method and attribute has an inline RBS signature")
    t.finish
  end
end

LintTest.main if __FILE__ == $0
