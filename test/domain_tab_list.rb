require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_tab_list")
D = Carat::Domain

def pos(row, col)
  Carat::Domain::Position.new(row, col)
end

def buffer_named(name)
  Carat::Domain::Buffer.new(["a", "b", "c"], name, "\n")
end

def tabs_over(buffer)
  Carat::Domain::TabList.new(Carat::Domain::Window.new(buffer))
end

# Tab pages and the alternate tab rule.
s = tabs_over(buffer_named("a.txt"))
first = s.tab
s.add_tab(D::TabPage.new(D::Window.new(buffer_named("b.txt"))))
t.assert_equal([2, 1], [s.tab_count, s.tab_index], "a new tab page goes after the current one and is current")
s.tab_index = 0
s.add_tab(D::TabPage.new(D::Window.new(buffer_named("c.txt"))))
t.assert_equal(["a.txt", "c.txt", "b.txt"], [s.tab_at(0).window.buffer.path, s.tab_at(1).window.buffer.path, s.tab_at(2).window.buffer.path], "inserted after the first tab page")
t.assert_equal(3, s.total_windows, "one window per tab page")
t.assert_equal([true, 2], [s.next_tab(0), s.tab_index], "next from the second goes to the third")
t.assert_equal([true, 0], [s.next_tab(0), s.tab_index], "next from the last wraps")
t.assert_equal([true, 2], [s.next_tab(3), s.tab_index], "a count goes to that tab page")
t.assert_equal([false, 2], [s.next_tab(5), s.tab_index], "a count past the last does nothing")
s.previous_tab(0)
t.assert_equal(1, s.tab_index, "previous goes back one")
s.previous_tab(2)
t.assert_equal(2, s.tab_index, "previous with a count wraps")
s.tab_index = 0
s.previous_tab(2)
t.assert_equal(1, s.tab_index, "two back from the first lands on the second of three")
s.tab_index = 1
s.remove_tab(1)
t.assert_equal([2, 1, "b.txt"], [s.tab_count, s.tab_index, s.tab.window.buffer.path], "closing the current tab page makes the next one current")
s.remove_tab(1)
t.assert_equal([1, 0], [s.tab_count, s.tab_index], "closing the last tab page makes the one before it current")
s.add_tab(D::TabPage.new(D::Window.new(buffer_named("d.txt"))))
s.remove_tab(0)
t.assert_equal([1, 0, "d.txt"], [s.tab_count, s.tab_index, s.tab.window.buffer.path], "closing a tab page before the current one keeps it current")
t.assert_true(!s.tab_at(0).equal?(first), "the first tab page is gone")

# Window ids come from the tab list and are never reused.
s = tabs_over(D::Buffer.new(["a"], "a.txt", "\n"))
t.assert_equal(1, s.window.id, "the first window has id 1")
page = D::TabPage.new(D::Window.new(s.window.buffer))
s.add_tab(page)
t.assert_equal([2, 1, 0, -1], [page.window.id, s.window_tab(2), s.window_tab(1), s.window_tab(9)], "a new tab page's window gets the next id and is found by it")
s.remove_tab(1)
lone = D::Window.new(s.window.buffer)
s.adopt(lone)
s.adopt(lone)
t.assert_equal(3, lone.id, "an id is given once and never again")

# Cursor clamping, driven by the change records: every closed transaction
# on a listed buffer clamps the cursors of the windows showing it, from
# its first changed row on, in every tab page.
text = D::Buffer.new(["zero", "one", "two", "three", "four"], "a.txt", "\n")
tabs = tabs_over(text)
list = D::BufferList.new(tabs)
list.add(text)
here = tabs.window
here.cursor.move_to(1, 2)
low = D::Window.new(text)
low.cursor.move_to(4, 3)
low.top = 4
tabs.tab.layout.arrange(0, 0, 23, 80)
tabs.tab.focus(tabs.tab.layout.split(tabs.tab.current, false, 0, 1))
tabs.adopt(tabs.window)
tabs.add_tab(D::TabPage.new(low))
tabs.tab_index = 0
t.assert_equal([2, 2], [tabs.tab.window_count, tabs.total_windows - 1], "two windows on the buffer in the first tab page and one in the second")
text.set_lines(3, 5, [])
t.assert_equal([[2, 2], 0, [1, 2]], [low.cursor.to_a, low.top, here.cursor.to_a], "a cursor past the end moves onto the last line and its last character, a scroll position past the end returns to the top, and a cursor above the change stays")
low.cursor.move_to(2, 3)
low.top = 2
text.set_lines(1, 3, ["x"])
t.assert_equal([[1, 0], 0, [1, 0]], [low.cursor.to_a, low.top, here.cursor.to_a], "every window on the buffer from the changed row on is clamped")
here.cursor.move_to(0, 3)
text.set_lines(1, 2, [])
t.assert_equal([0, 3], here.cursor.to_a, "a cursor above the change stays")
other = D::Buffer.new(["only"], "b.txt", "\n")
list.add(other)
low.cursor.move_to(0, 3)
other.set_lines(0, 1, ["x"])
t.assert_equal([0, 3], low.cursor.to_a, "a change to another buffer clamps nothing here")
open = D::Buffer.new(["one", "two"], "c.txt", "\n")
list.add(open)
w = D::Window.new(open)
tabs.add_tab(D::TabPage.new(w))
w.cursor.move_to(1, 2)
open.begin_transaction(pos(1, 2))
open.set_lines(1, 2, [])
t.assert_equal([1, 2], w.cursor.to_a, "nothing is clamped while the transaction is open")
open.commit_transaction(pos(0, 0))
t.assert_equal([0, 2], w.cursor.to_a, "it is clamped when the transaction closes")

# The records beside the lists: the input state, the last find, and the
# plugins' segments and prompt.
input = D::InputState.new
t.assert_equal([false, "", []], [input.pending?, input.grammar.typed, input.pending_keys], "no keys pending at first")
input.pending_keys << 103
t.assert_equal([true, [103], false], [input.pending?, input.take_keys, input.pending?], "take_keys hands over the waiting keys and drops them")
found = D::LastFind.new
t.assert_equal(true, found.entry.nil?, "no find at first")
found.remember(D::Find.new("x", true, false))
t.assert_equal(["x", true], [found.entry.char, found.entry.forward], "remember keeps the find")
ui = D::PluginUi.new
t.assert_equal([{}, false], [ui.segments, ui.prompting?], "no status segments and no prompt at first")
ui.segment("hello", "hi")
ui.segment("other", "x")
ui.segment("other", "")
ui.open_prompt("hello", "rename", "Name: ")
t.assert_equal([{ "hello" => "hi" }, true, "Name: ", "rename"], [ui.segments, ui.prompting?, ui.prompt, ui.prompt_id], "segments by plugin, empty text removes one, and an open prompt")
ui.drop("other")
t.assert_equal(true, ui.prompting?, "dropping another plugin keeps the prompt")
ui.drop("hello")
t.assert_equal([{}, false, ""], [ui.segments, ui.prompting?, ui.prompt], "dropping the plugin removes its segment and its prompt")

t.finish
