require_relative "../carat"
require_relative "../carat/testing"

# The plugin host's hardening: every call into a plugin is guarded, events
# are queued and bounded, buffers and windows are addressed by id, edits
# are validated item by item, events come from the edit path with ranges,
# strings are copied at the boundary, a disabled plugin leaves nothing
# behind, and the manifest rules cover versions, names, commands, and
# bindings. Each test runs the whole editor over the doubles.
t = Carat::Testing.new("use_cases_plugin_hardening")
A = Carat::PluginApi

# A test plugin whose behavior is chosen by its mode: what its action does,
# what it does on events and on its ex command, and what it does when it
# activates. It logs what it receives.
class Rig < Carat::PluginApi::Plugin
  attr_reader :log #: Array[String]
  attr_accessor :mode #: String
  attr_accessor :target #: Integer
  attr_accessor :arg #: String

  # @rbs @name: String
  # @rbs @events: Array[String]
  # @rbs @commands: Hash[String, String]
  # @rbs @keys: String
  # @rbs @link: Carat::PluginApi::Host?
  # @rbs @runs: Integer

  #: (String, String, Array[String], Hash[String, String], String) -> void
  def initialize(name, mode, events, commands, keys)
    @name = name
    @mode = mode
    @events = events
    @commands = commands
    @keys = keys
    @log = []
    @link = nil
    @target = 0
    @arg = ""
    @runs = 0
  end

  # Returns the manifest.
  # @rbs skip
  def manifest
    action = "plugin.#{@name}.go"
    Carat::PluginApi::Manifest.new(@name, "1.0.0", "1.2", { action => "Go" }, @commands, { "normal" => { @keys => action } }, @events, {}, {})
  end

  #: (Carat::PluginApi::Host) -> void
  def activate(host)
    @link = host
    if @mode == "activate_tab"
      r = host.run_ex("tabnew")
      @log << "activate #{r.ok} #{r.message}".rstrip
    end
  end

  #: () -> Integer
  def runs
    @runs
  end

  # The host as never nil.
  #: () -> Carat::PluginApi::Host
  def host
    h = @link
    h.nil? ? Carat::PluginApi::Host.new : h
  end

  #: (Carat::PluginApi::Event) -> void
  def on_event(event)
    @log << event.to_line
    host.run_ex("w") if @mode == "save_writes" && event.name == "buffer_save"
  end

  #: (Carat::PluginApi::Command) -> void
  def on_command(command)
    return unless @mode == "nest"
    @runs += 1
    r = host.run_ex(command.name)
    @log << r.message unless r.ok
  end

  #: (String, Carat::PluginApi::Context) -> void
  def on_action(name, context)
    h = host
    case @mode
    when "unimplemented"
      Carat::PluginApi::Host.new.message("never", false)
    when "recurse"
      @log << deep(0).to_s
    when "edit_other"
      r = h.edit_buffer(@target, [Carat::PluginApi::Edit.new(0, 0, 0, 0, "new\n")])
      @log << "edit #{r.ok}"
    when "edit_bad_last"
      r = h.edit_buffer(0, [Carat::PluginApi::Edit.new(0, 0, 0, 1, "X"), Carat::PluginApi::Edit.new(1, 0, 1, 0, "Y"), "nope"])
      @log << "edit #{r.ok} #{r.message}"
    when "litter"
      h.open_scratch("list", "left", 20, ["x"], nil)
      h.place_sign(@target, 0, "error")
      h.set_status("busy")
      h.prompt("ask", "Name: ", "")
      raise ArgumentError, "after littering"
    when "split"
      r = h.open_in_split(0, @arg, false)
      @log << "split #{r.ok} #{r.window} #{r.message}"
    when "vsplit"
      r = h.open_in_split(@target, @arg, true)
      @log << "vsplit #{r.ok} #{r.window} #{r.message}"
    when "tab"
      r = h.open_in_tab(@arg)
      @log << "tab #{r.ok} #{r.window} #{r.message}"
    when "focus"
      r = h.focus_window(@target)
      @log << "focus #{r.ok} #{r.window} #{r.message}".rstrip
    when "open"
      r = h.open_file(@target, @arg)
      @log << "open #{r.ok} #{r.window} #{r.message}"
    when "read_mutate"
      view = h.read_buffer(0)
      first = view.lines[0]
      first << "!"
      path = view.path
      path << "?"
      @log << first
    when "scratch_mutate"
      line = +"x"
      h.open_scratch("list", "left", 20, [line], nil)
      line << "!"
    when "rename"
      r = h.rename_path(h.working_directory.text, @arg, "c.txt")
      @log << "rename #{r.ok}"
    end
  end

  private

  #: (Integer) -> Integer
  def deep(n)
    deep(n + 1) + 1
  end
end

# A plugin that never implements its manifest.
class Bare < Carat::PluginApi::Plugin
end

# A plugin whose manifest gives a string for its actions.
class Crooked < Carat::PluginApi::Plugin
  # Returns the manifest.
  # @rbs skip
  def manifest
    Carat::PluginApi::Manifest.new("crooked", "1.0.0", "1.2", "nope", {}, nil, [], {}, {})
  end
end

def rig(name, mode, events)
  Rig.new(name, mode, events, {}, "<leader>r" + name[0, 1])
end

# An editor over a.txt and b.txt with the plugins, on a.txt.
def editor(plugins)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", "one\ntwo\nthree\n")
  files.put("b.txt", "bee\n")
  files.put("my notes.txt", "spaced\n")
  files.put("a|b.txt", "barred\n")
  files.put("dir/x.txt", "x\n")
  h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, plugins)
  h.open("a.txt")
  h
end

# Guarded calls: NotImplementedError, a stack overflow, and broken
# manifests disable the plugin and the editor goes on.
p = rig("probe", "unimplemented", [])
h = editor([p])
h.type(" rp")
t.assert_equal([false, "Plugin probe disabled: Host#message", true], [h.plugins.enabled?("probe"), h.message, h.state.message_error], "a host method the plugin's host does not implement disables the plugin")
h.type("x")
t.assert_equal(["ne", "two", "three"], h.lines, "and the editor goes on editing")
p = rig("probe", "recurse", [])
h = editor([p])
h.type(" rp")
t.assert_equal([false, "Plugin probe disabled: stack level too deep"], [h.plugins.enabled?("probe"), h.message], "a stack overflow disables the plugin")
h.type("x")
t.assert_equal(["ne", "two", "three"], h.lines, "and the editor goes on editing")
good = rig("good", "", [])
h = editor([good, Bare.new, Crooked.new])
t.assert_equal(["Plugin#manifest", "actions is not an object of action names", true], [h.plugins.reason("plugin2"), h.plugins.reason("crooked"), h.plugins.enabled?("good")], "a manifest that raises and one of the wrong shape register disabled, the others enabled")
t.assert_equal(["plugin plugin2: Plugin#manifest", "plugin crooked: actions is not an object of action names"], h.plugins.errors, "both are recorded")
h.type("x")
t.assert_equal(["ne", "two", "three"], h.lines, "the editor started and edits")

# Re-entry: a plugin writing on every save hears one save; two of them
# stop after the rounds limit.
w = rig("writer", "save_writes", ["buffer_save"])
h = editor([w])
h.type("x:w<CR>")
t.assert_equal([["buffer_save b2 w1 a.txt 0,0"], "ne\ntwo\nthree\n", true], [w.log, h.files.get("a.txt"), h.plugins.enabled?("writer")], "a plugin writing on a save hears only the user's save, not its own")
w1 = rig("one", "save_writes", ["buffer_save"])
w2 = rig("two", "save_writes", ["buffer_save"])
h = editor([w1, w2])
h.type(":w<CR>")
t.assert_equal(["Plugin events dropped after 8 rounds", true, true], [h.message, h.plugins.enabled?("one"), h.plugins.enabled?("two")], "two plugins writing on each other's saves stop after 8 rounds")
t.assert_equal([8, 8], [w1.log.length, w2.log.length], "each heard one save per round")
nest = Rig.new("nest", "nest", [], { "Nest" => "" }, "<leader>rn")
h = editor([nest])
h.type(":Nest<CR>")
t.assert_equal([4, ["E169: Command too recursive"], true], [nest.runs, nest.log, h.plugins.enabled?("nest")], "a command that runs itself runs 4 deep, then is refused")

# Edits: a bad last item changes nothing and causes no event.
e = rig("edit", "edit_bad_last", [])
seen = rig("seen", "", ["buffer_change"])
h = editor([e, seen])
h.type(" re")
t.assert_equal([["edit false edit 3: not an edit"], ["one", "two", "three"], false, []], [e.log, h.lines, h.buffer.modified?, seen.log], "a bad last item refuses the request before any edit lands")

# Ids: a buffer id survives a list change and a window id a window close.
p = rig("probe", "focus", [])
h = editor([p])
h.type(":vs<CR>:vs<CR>")
third = h.state.tab.layout.window_at(h.state.tab.layout.leaves[2]).id
h.type("1<C-w>w<C-w>c")
p.target = third
h.type(" rp")
t.assert_equal([["focus true #{third}"], third, 2], [p.log, h.state.window_id, h.window_count], "a window id still names the same window after another closed")
h.type(":new<CR>")
t.assert_equal(true, h.state.window_id > third, "a new window gets an id never given before")
p.target = 99
h.type(" rp")
t.assert_equal("focus false 0 No window 99", p.log[1], "an unknown window id fails")
r = rig("reader", "", [])
h = editor([r])
a_id = h.buffer.id
h.type(":e b.txt<CR>:e a.txt<CR>")
t.assert_equal([false, true, ["one", "two", "three"]], [r.host.read_buffer(a_id).ok, h.buffer.id > a_id, r.host.read_buffer(h.buffer.id).lines], "a buffer that left the list loses its id for good and the reopened file gets a new one")
h.type(":sp b.txt<CR>")
b_id = h.buffer.id
h.type("<C-w>j")
t.assert_equal("bee", r.host.read_buffer(b_id).lines[0], "a buffer that is not current is read by its id")

# Windows across tab pages, and a failed open keeps the focus.
p = rig("probe", "focus", [])
h = editor([p])
first = h.state.window_id
h.type(":tabnew<CR>")
p.target = first
h.type(" rp")
t.assert_equal([1, first], [h.tab_index, h.state.window_id], "focusing a window of another tab page goes to that tab page")
p = rig("probe", "open", [])
h = editor([p])
h.type(":vs<CR>")
left = h.state.window_id
p.target = h.state.tab.layout.window_at(h.state.tab.layout.leaves[1]).id
p.arg = "dir"
h.type(" rp")
t.assert_equal([true, left], [p.log[0].start_with?("open false 0 E484"), h.state.window_id], "a failed open fails and leaves the focus where it was")

# Splits and tab pages take the path as it is.
p = rig("probe", "split", [])
p.arg = "my notes.txt"
h = editor([p])
h.type(" rp")
t.assert_equal([2, "my notes.txt", ["spaced"]], [h.window_count, h.buffer.path, h.lines], "a split opens a name with a space")
t.assert_equal(true, p.log[0].start_with?("split true #{h.state.window_id} "), "and answers the new window's id")
p.mode = "tab"
p.arg = "a|b.txt"
h.type(" rp")
t.assert_equal([2, "a|b.txt", ["barred"]], [h.tab_count, h.buffer.path, h.lines], "a tab page opens a name with a bar")
p = rig("probe", "vsplit", [])
p.arg = "b.txt"
h = editor([p])
p.target = h.state.window_id
h.type(" rp")
t.assert_equal([2, "b.txt", 0], [h.window_count, h.buffer.path, h.state.window.col], "a vertical split puts the new window at the left")

# Events from the edit path: ranges, other buffers, other plugins.
listener = rig("listener", "", ["buffer_change"])
h = editor([listener])
h.type("jdd")
t.assert_equal(["buffer_change b2 w1 a.txt 1,0 -1 +0"], listener.log, "dd on row 1 reports row 1, one row removed")
listener.log.clear
h.type("ix<Esc>")
t.assert_equal(["buffer_change b2 w1 a.txt 1,0 -1 +1"], listener.log, "an insert session reports once, when it ends")
editor_rig = rig("editor", "edit_other", [])
other = rig("other", "", ["buffer_change"])
h = editor([editor_rig, other])
b_id = 0
h.type(":sp b.txt<CR>")
b_id = h.buffer.id
h.type("<C-w>j")
editor_rig.target = b_id
other.log.clear
editor_rig.log.clear
h.type(" re")
t.assert_equal([["buffer_change b#{b_id} w1 b.txt 0,0 -1 +2"], ["new", "bee"]], [other.log, h.state.buffer_with_id(b_id).lines], "another plugin hears the change of a buffer that is not current, with its rows")
t.assert_equal(["edit true"], editor_rig.log, "the plugin that edited does not")

# Close and rename events.
watcher = rig("watcher", "", ["buffer_close", "buffer_rename"])
renamer = rig("renamer", "rename", [])
renamer.arg = "a.txt"
h = editor([watcher, renamer])
h.type(":sp b.txt<CR>")
b_id = h.buffer.id
h.type(":q<CR>")
t.assert_equal(["buffer_close b#{b_id} w1 b.txt 0,0"], watcher.log, "closing the window of a clean buffer closes the buffer")
watcher.log.clear
h.type(" rr")
t.assert_equal([["rename true"], "c.txt", ["buffer_rename b2 w1 c.txt 0,0 a.txt"]], [renamer.log, h.buffer.path, watcher.log], "a renamed file's buffer follows it and the rename is an event with the old path")

# Strings at the boundary are copies.
m = rig("mutator", "read_mutate", [])
h = editor([m])
h.type(" rm")
t.assert_equal([["one!"], ["one", "two", "three"], "a.txt"], [m.log, h.lines, h.buffer.path], "changing a read line or path changes nothing in the buffer")
m.mode = "scratch_mutate"
h.type(" rm")
t.assert_equal(["x"], h.lines, "changing a given scratch line changes nothing in the buffer")

# Disabling cleans up the windows, signs, status, prompt, and bindings.
l = rig("litter", "litter", [])
h = editor([l])
l.target = h.buffer.id
h.type(" rl")
t.assert_equal([1, false, {}, :normal, "", "a.txt"], [h.window_count, h.buffer.signs?, h.state.segments, h.mode, h.state.prompt, h.buffer.path], "a plugin disabled after opening a side window, a sign, a status, and a prompt leaves none of them")
t.assert_equal(["a.txt"], h.buffer_paths, "its scratch buffer left the list")
t.assert_equal("Plugin litter disabled: after littering", h.message, "it says why it was disabled")
t.assert_equal(:none, h.assembly.keymap.lookup(:normal, Carat::Domain::KeyNotation.parse("<leader>rl", " ").codes).kind, "its binding went with it")

# Version, name, command, and binding rules.
dup1 = rig("probe", "", [])
dup2 = rig("probe", "", [])
h = editor([dup1, dup2])
t.assert_equal(["plugin probe: a plugin named probe is already registered"], h.plugins.errors, "a second plugin with a registered name is refused")
t.assert_equal(true, h.plugins.enabled?("probe"), "and the first keeps its name")
c1 = Rig.new("first", "", [], { "Probe" => "Pr" }, "<leader>xa")
c2 = Rig.new("second", "", [], { "Pro" => "Pr" }, "<leader>xb")
h = editor([c1, c2])
t.assert_equal([true, false, "command Pro is already declared by plugin first"], [h.plugins.enabled?("first"), h.plugins.enabled?("second"), h.plugins.reason("second")], "a plugin repeating another's ex command or abbreviation is refused")
c3 = Rig.new("third", "", [], { "Probe" => "" }, "<leader>xc")
h = editor([c1, c3])
h.type(":Probe<CR>")
t.assert_equal(["command Probe is already declared by plugin first", ""], [h.plugins.reason("third"), h.message], "two plugins declaring one ex command: the second is refused and the command reaches the first")
k1 = Rig.new("kone", "", [], {}, "<leader>pp")
k2 = Rig.new("ktwo", "", [], {}, "<leader>pp")
h = editor([k1, k2])
t.assert_equal(["plugin ktwo: binding normal.<leader>pp is already bound by plugin kone"], h.plugins.errors, "a binding conflict between plugins is reported")
t.assert_equal("plugin.kone.go", h.assembly.keymap.lookup(:normal, Carat::Domain::KeyNotation.parse("<leader>pp", " ").codes).value, "and the first plugin keeps the keys")

# Signs move with their lines.
s = rig("signer", "", [])
h = editor([s])
s.host.place_sign(0, 2, "error")
h.type("ggO<Esc>")
t.assert_equal(["", "\u{F057}"], [h.buffer.sign_at(2), h.buffer.sign_at(3)], "a line opened above moves the sign down")
h.type("4Gdd")
t.assert_equal([["", "one", "two"], "", ""], [h.lines, h.buffer.sign_at(2), h.buffer.sign_at(3)], "deleting its line removes it")

# run_ex works while activating.
act = rig("starter", "activate_tab", [])
h = editor([act])
t.assert_equal([["activate true"], 2], [act.log, h.tab_count], "a plugin runs an ex command in activate")

t.finish
