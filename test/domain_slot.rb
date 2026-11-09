require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainSlotTest
  D = Carat::Domain

  def self.scratch(title)
    buffer = D::Buffer.new(lines: ["x"], path: nil, line_ending: "\n")
    buffer.owner = "test"
    buffer.title = title
    buffer
  end

  # A tab page of "a.txt" arranged at 23 by 80 with a 20-column left
  # sidebar showing the scratch buffer "list".
  def self.page_with_sidebar
    page = D::TabPage.new(window: D::Window.new(buffer: D::Buffer.new(lines: ["a"], path: "a.txt", line_ending: "\n")))
    page.layout.arrange(0, 0, 23, 80)
    window = D::Window.new(buffer: scratch("list"))
    window.fixed_width = true
    page.layout.place_slot(window, 20, :left)
    page.layout.arrange(0, 0, 23, 80)
    page.left_slot.attach(window, "list", 20)
    page
  end

  # Steps over a page with a left sidebar: H hides it (its leaf closed),
  # C closes its window, F shows a file in it, V adds the view "other".
  # Answers [shown, kept, views].
  def self.after(steps)
    page = page_with_sidebar
    slot = page.left_slot
    layout = page.layout
    steps.to_s.each_char do |step|
      window = slot.view_window
      if step == "H"
        layout.close(layout.leaf_holding(window))
        slot.hide(20)
      elsif step == "C"
        layout.close(layout.leaf_holding(window))
      elsif step == "F"
        window.show(D::Buffer.new(lines: ["f"], path: "f.txt", line_ending: "\n"))
      else
        slot.add_view("other")
      end
    end
    [slot.shown?(layout), slot.kept?, slot.views]
  end

  def self.main
    t = Carat::Testing.new("domain_slot")

    page = D::TabPage.new(window: D::Window.new(buffer: D::Buffer.new(lines: ["a"], path: "a.txt", line_ending: "\n")))
    sides = []
    i = 0
    while i < D::TabPage::SLOT_COUNT
      slot = page.slot_at(i)
      sides << [slot.side, slot.occupied?, slot.sidebar?]
      i += 1
    end
    t.assert_equal([[:left, false, true], [:right, false, true], [:bottom, false, false]], sides, "a tab page starts with three empty slots")
    t.assert_equal([:left, :right, :bottom], [page.slot(:left).side, page.slot(:right).side, page.slot(:bottom).side], "a slot is found by its side")

    t.table([
      ["a placed view is shown", "", [true, false, ["list"]]],
      ["a second view is listed after the first, once", "VV", [true, false, ["list", "other"]]],
      ["a hidden slot keeps its window", "H", [false, true, ["list"]]],
      ["a closed window ends the slot", "C", [false, false, ["list"]]],
      ["a window that took a file ends the slot", "F", [false, false, ["list"]]]
    ]) do |steps|
      after(steps.to_s)
    end

    page = page_with_sidebar
    list = page.left_slot.view_window.buffer
    page.layout.close(page.layout.leaf_holding(page.left_slot.view_window))
    page.left_slot.hide(20)
    tabs = D::TabList.new(window: D::Window.new(buffer: D::Buffer.new(lines: ["b"], path: "b.txt", line_ending: "\n")))
    tabs.add_tab(page)
    t.assert_equal([true, true, false], [page.keeps?(list), tabs.shown?(list), tabs.shown?(scratch("list"))], "a hidden slot's buffer counts as shown, by identity")
    page.left_slot.clear
    t.assert_equal([false, false, []], [page.keeps?(list), page.left_slot.occupied?, page.left_slot.views], "a cleared slot forgets its window and views")

    t.finish
  end
end

DomainSlotTest.main if __FILE__ == $0
