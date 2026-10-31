require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_transactions")
A = Carat::PluginApi

# A test plugin that applies two replacements to the current buffer in one
# edit request, from a key binding.
class Edits < Carat::PluginApi::Plugin
  # @rbs @host: Carat::PluginApi::Host?

  #: () -> void
  def initialize
    @host = nil
  end

  # Returns the manifest.
  # @rbs skip
  def manifest
    Carat::PluginApi::Manifest.new(
      "edits", "1.0.0", "1.0",
      { "plugin.edits.two" => "Replace two ranges" },
      {},
      { "normal" => { "<leader>te" => "plugin.edits.two" } },
      [], {}, {}
    )
  end

  #: (Carat::PluginApi::Host) -> void
  def activate(host)
    @host = host
  end

  # The host as never nil, for a request made outside a command.
  #: () -> Carat::PluginApi::Host
  def link
    h = @host
    h.nil? ? Carat::PluginApi::Host.new : h
  end

  #: (String, Carat::PluginApi::Context) -> void
  def on_action(name, context)
    host = @host
    return if host.nil?
    host.edit_buffer(0, [A::Edit.new(0, 0, 0, 1, "X"), A::Edit.new(1, 0, 1, 1, "Y")]) if name == "plugin.edits.two"
  end
end

def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  files.put("b.txt", "bee\n")
  h = Carat::Doubles::EditorHarness.with_plugins(files, 10, 80, [Edits.new])
  h.open("a.txt")
  h
end

# What a key sequence closed: the number of transactions, and for the last
# one its records as [row, removed, inserted] and the cursor rows before
# and after.
def closed(h, keys)
  buffer = h.buffer
  start = buffer.closed_count
  h.type(keys)
  tx = buffer.last_transaction
  count = buffer.closed_count - start
  return [count] if tx.nil? || count == 0
  records = []
  i = 0
  while i < tx.size
    r = tx.record_at(i)
    records << [r.row, r.removed, r.inserted]
    i += 1
  end
  [count, records, tx.before.row, tx.after.row]
end

t.table([
  ["dd is one transaction with one record", ["a\nb\nc\n", "jdd"], [1, [[1, ["b"], []]], 1, 1]],
  ["3dd is one transaction", ["a\nb\nc\nd\n", "3dd"], [1, [[0, ["a", "b", "c"], []]], 0, 0]],
  ["o, typing, and Escape are one insert session", ["a\n", "oxy<Esc>"], [1, [[1, [], [""]], [1, [""], ["x"]], [1, ["x"], ["xy"]]], 0, 1]],
  ["an insert session from i to Escape", ["ab\n", "ixy<Esc>"], [1, [[0, ["ab"], ["xab"]], [0, ["xab"], ["xyab"]]], 0, 0]],
  ["typing a character records the line before and after", ["ab\n", "lix<Esc>"], [1, [[0, ["ab"], ["axb"]]], 0, 0]],
  ["a newline in insert mode joins the session", ["ab\n", "a<CR><Esc>"], [1, [[0, ["ab"], ["a", "b"]]], 0, 1]],
  ["visual d is one transaction", ["abc\n", "vld"], [1, [[0, ["abc"], ["c"]]], 0, 0]],
  ["visual block c is one session with its repeat", ["ab\ncd\n", "<C-v>jcX<Esc>"], [1, [[0, ["ab", "cd"], ["b", "d"]], [0, ["b"], ["Xb"]], [1, ["d"], ["Xd"]]], 1, 0]],
  ["a put of three lines is one transaction", ["a\nb\n", "yy3p"], [1, [[1, [], ["a", "a", "a"]]], 0, 1]],
  ["a motion closes nothing", ["a\nb\n", "j"], [0]],
  ["a yank closes nothing", ["a\nb\n", "yy"], [0]],
  ["a plugin edit from a key is the key's transaction", ["ab\ncd\n", " te"], [1, [[1, ["cd"], ["Yd"]], [0, ["ab"], ["Xb"]]], 0, 0]]
]) do |input|
  closed(editor(input[0]), input[1])
end

# A forced reload after an edit is one transaction with one record.
h = editor("a\nb\n")
h.type("x")
t.assert_equal([1, [[0, ["", "b"], ["a", "b"]]], 0, 0], closed(h, ":e!<CR>"), "a forced reload is one transaction with one record")

# A plugin edit request outside a command is a transaction of its own.
edits = Edits.new
files = Carat::Doubles::MemoryFiles.new
files.put("a.txt", "ab\ncd\n")
h = Carat::Doubles::EditorHarness.with_plugins(files, 10, 80, [edits])
h.open("a.txt")
start = h.buffer.closed_count
r = edits.link.edit_buffer(0, [A::Edit.new(0, 0, 0, 1, "X"), A::Edit.new(1, 0, 1, 1, "Y")])
t.assert_equal([true, 1, 2, ["Xb", "Yd"]], [r.ok, h.buffer.closed_count - start, h.buffer.last_transaction.size, h.lines], "a plugin edit request outside a command closes one transaction with both records")

# A session left open outside insert mode is closed by the next command.
h = editor("a\nb\n")
h.buffer.begin_transaction(Carat::Domain::Position.new(0, 0))
h.buffer.set_lines(0, 1, ["z"])
start = h.buffer.closed_count
h.type("j")
t.assert_equal([1, false, 1], [h.buffer.closed_count - start, h.buffer.transaction_open?, h.buffer.last_transaction.size], "the dispatcher closes a transaction left open outside insert mode before the next command")

# The modified flag follows writes and edits, through the keys.
h = editor("ab\n")
h.type("x")
modified_after_edit = h.buffer.modified
h.type(":w<CR>")
modified_after_write = h.buffer.modified
h.type("x")
t.assert_equal([true, false, true], [modified_after_edit, modified_after_write, h.buffer.modified], "an edit modifies, a write clears, the next edit modifies again")
h = editor("ab\n")
h.type("x")
h.type("ia<Esc>")
t.assert_equal([["ab"], true], [h.lines, h.buffer.modified], "typing the deleted character back leaves the buffer modified")
h.type(":e!<CR>")
t.assert_equal([["ab"], false], [h.lines, h.buffer.modified], "a forced reload clears the flag")

# Buffer ids are stable.
h = editor("a\n")
a_buffer = h.buffer
a_id = a_buffer.id
h.type(":e b.txt<CR>")
t.assert_equal([true, true, true], [a_id > 0, h.buffer.id != a_id, a_buffer.id == a_id], "two files have different ids and a.txt keeps its own")

t.finish
