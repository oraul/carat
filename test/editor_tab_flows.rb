require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The tab flows a user types: opening files from the explorer and the
# file window, moving between buffer tabs and tab pages, and closing
# them down to the editor quitting, each started as `carat .` is, with
# the explorer on, under option.gt buffers unless a flow names tab
# pages. Each step is real key notation and, after it, the top row, the
# current buffer, the listed file buffers, the windows and tab pages of
# the current one, whether the explorer is open there, the message, and
# whether the editor quit; each flow ends with no [No Name] beside a
# file and no tab page holding only the explorer.
module EditorTabFlowsTest
  ROOT = "/home/ada/proj"

  # /home/ada/proj with alpha.txt, beta.txt, lib/gamma.rb, and notes.md.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("alpha.txt", "a1\n")
    files.put("beta.txt", "b1\n")
    files.put("lib/gamma.rb", "g1\n")
    files.put("notes.md", "# Notes\n\nn1\n")
    files
  end

  # A 30 by 110 editor with the registry's plugins, started on no file
  # as `carat .` is, the ascii icons, and the further lines.
  def self.editor(more)
    config = Carat::Doubles::FixedConfig.with("option.icons ascii\n#{more}")
    Carat::Doubles::EditorHarness.new(files: disk, config: config, rows: 30, cols: 110, plugins: Carat::Plugins::Registry.all)
  end

  # A table value as strings.
  def self.strings(values)
    out = []
    values.each { |v| out << v.to_s }
    out
  end

  # The name a buffer shows: the explorer's title, the path, or [No Name].
  def self.name_of(buffer)
    return buffer.display_name.to_s if buffer.scratch?
    path = buffer.path
    path.nil? ? "[No Name]" : path
  end

  # The listed file buffers, scratch and unlisted ones left out.
  def self.files(h)
    list = h.assembly.buffers
    out = []
    i = 0
    while i < list.count
      b = list.buffer_at(i)
      out << name_of(b) unless b.scratch? || b.tabless?
      i += 1
    end
    out
  end

  # Whether the explorer shows in a window of the tab page.
  def self.explorer_in?(page)
    layout = page.layout
    ids = layout.leaves
    i = 0
    while i < ids.length
      b = layout.window_at(ids[i]).buffer
      return true if b.scratch? && b.display_name.to_s == "explorer"
      i += 1
    end
    false
  end

  # No [No Name] is listed beside a file, and every tab page has a file
  # window.
  def self.clean?(h)
    names = files(h)
    return false if names.include?("[No Name]") && names.length > 1
    tabs = h.assembly.tabs
    i = 0
    while i < tabs.tab_count
      return false if tabs.tab_at(i).file_window_count == 0
      i += 1
    end
    true
  end

  # Row 0 squeezed: the head over a sidebar, the tab names, icons, marks,
  # and counters, with no separator between them.
  def self.top_row(h)
    h.row(0).strip.squeeze(" ")
  end

  # What a step checks, as strings.
  def self.observe(h)
    [top_row(h), name_of(h.buffer), files(h).join(","), h.window_count.to_s, h.tab_count.to_s, explorer_in?(h.state.tab).to_s, h.message, h.quit?.to_s]
  end

  # Types each step and checks what it leaves, then that the flow ends
  # clean. A step is [keys, row, current, files, windows, tab pages,
  # explorer, message, quit].
  def self.flow(t, label, more, steps)
    h = editor(more)
    i = 0
    while i < steps.length
      step = strings(steps[i])
      h.type(step[0]) unless h.quit?
      t.assert_equal(step[1, 8], observe(h), "#{label}, step #{i + 1}: #{step[0]}")
      i += 1
    end
    t.assert_equal(true, clean?(h), "#{label}: ends with no [No Name] beside a file and no tab page of only the explorer")
  end

  def self.main
    t = Carat::Testing.new("editor_tab_flows")
    tabpages = "option.gt tabpages\n"

    # Opening.
    flow(t, "l from the explorer onto the startup buffer, then a new and a listed file", "", [
      ["<Space>e", "proj 1", "explorer", "[No Name]", "2", "1", "true", "", "false"],
      ["3Gl", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gl", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<Space>e3Gl", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"]
    ])
    flow(t, "Enter from the explorer onto the startup buffer and a listed file", "", [
      ["<Space>e3G<CR>", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4G<CR>", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<Space>e3G<CR>", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"]
    ])
    flow(t, "s and v from the explorer, each split closed with Ctrl-W q", "", [
      ["<Space>e3Gl", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gs", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "3", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<C-w>q", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e4Gv", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "3", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<C-w>q", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"]
    ])
    flow(t, "t from the explorer onto the startup buffer, a new file, and a listed file", "", [
      ["<Space>e3Gt", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gt", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<Space>e3Gt", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["gT", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"]
    ])
    flow(t, "t from the explorer into a directory's file", "", [
      ["<Space>e2Gl3Gt", "proj 1 g1", "lib/gamma.rb", "lib/gamma.rb", "2", "1", "true", "\"lib/gamma.rb\" 1L, 3B", "false"],
      ["<Space>e5Gt", "proj gamma.rb beta.txt", "beta.txt", "lib/gamma.rb,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"]
    ])
    flow(t, ":e, :sp, and :vs from the file window", "", [
      [":e alpha.txt<CR>", "1 a1", "alpha.txt", "alpha.txt", "1", "1", "false", "\"alpha.txt\" 1L, 3B", "false"],
      [":e beta.txt<CR>", "alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "1", "1", "false", "\"beta.txt\" 1L, 3B", "false"],
      [":sp lib/gamma.rb<CR>", "alpha.txt beta.txt gamma.rb", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "2", "1", "false", "\"lib/gamma.rb\" 1L, 3B", "false"],
      ["<C-w>q", "alpha.txt beta.txt gamma.rb", "beta.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      [":vs alpha.txt<CR>", "alpha.txt beta.txt gamma.rb", "alpha.txt", "alpha.txt,beta.txt,lib/gamma.rb", "2", "1", "false", "\"alpha.txt\" 1L, 3B", "false"],
      ["<C-w>q", "alpha.txt beta.txt gamma.rb", "beta.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"]
    ])
    flow(t, ":tabe of a new file, a listed file, and no name", "", [
      [":e alpha.txt<CR>", "1 a1", "alpha.txt", "alpha.txt", "1", "1", "false", "\"alpha.txt\" 1L, 3B", "false"],
      [":tabe beta.txt<CR>", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "\"beta.txt\" 1L, 3B", "false"],
      [":tabe alpha.txt<CR>", "alpha.txt beta.txt 1 2 3", "alpha.txt", "alpha.txt,beta.txt", "1", "3", "false", "\"alpha.txt\" 1L, 3B", "false"],
      [":tabc<CR>", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      [":tabc<CR>", "alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"],
      [":tabe<CR>", "alpha.txt beta.txt [No Name] 1 2", "[No Name]", "alpha.txt,beta.txt,[No Name]", "1", "2", "false", "", "false"],
      [":tabc<CR>", "alpha.txt beta.txt [No Name]", "alpha.txt", "alpha.txt,beta.txt,[No Name]", "1", "1", "false", "", "false"],
      [":bd 3<CR>", "alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"]
    ])

    # Moving.
    flow(t, "gt, gT, :bn, :bp, :b N, and the tab-page keys from a file window", "", [
      [":e alpha.txt<CR>:e beta.txt<CR>:e lib/gamma.rb<CR>", "alpha.txt beta.txt gamma.rb", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "\"lib/gamma.rb\" 1L, 3B", "false"],
      ["gt", "alpha.txt beta.txt gamma.rb", "alpha.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      ["gT", "alpha.txt beta.txt gamma.rb", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      [":bn<CR>", "alpha.txt beta.txt gamma.rb", "alpha.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      [":bp<CR>", "alpha.txt beta.txt gamma.rb", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      [":b 2<CR>", "alpha.txt beta.txt gamma.rb", "beta.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      ["<C-PageDown>", "alpha.txt beta.txt gamma.rb", "beta.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "", "false"],
      [":tabe alpha.txt<CR>", "alpha.txt beta.txt gamma.rb 1 2", "alpha.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "2", "false", "\"alpha.txt\" 1L, 3B", "false"],
      ["<C-PageUp>", "alpha.txt beta.txt gamma.rb 1 2", "beta.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "2", "false", "", "false"],
      ["g<Tab>", "alpha.txt beta.txt gamma.rb 1 2", "alpha.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "2", "false", "", "false"],
      ["<C-PageDown>", "alpha.txt beta.txt gamma.rb 1 2", "beta.txt", "alpha.txt,beta.txt,lib/gamma.rb", "1", "2", "false", "", "false"]
    ])
    flow(t, "gt, gT, :bn, :bp, :b N, and the tab-page keys from the explorer", "", [
      [":e alpha.txt<CR>:e beta.txt<CR><Space>e", "proj alpha.txt beta.txt", "explorer", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["gt", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>egT", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e:bn<CR>", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e:bp<CR>", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e:b 1<CR>", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e<Space>bn", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e<C-PageDown>", "proj alpha.txt beta.txt", "explorer", "alpha.txt,beta.txt", "2", "1", "true", "", "false"]
    ])

    # Moving from a reading view, a window that is not a side window
    # though its buffer is a scratch buffer.
    # Scenario: Buffer switches from a lone reading view act on its window.
    flow(t, "Buffer switches from a lone reading view act on its window: :bn, :bp, :b N, Ctrl-^, and gt", "", [
      [":e alpha.txt<CR>:e beta.txt<CR>:e notes.md<CR><Space>dr", "alpha.txt beta.txt notes.md", "[reading] notes.md", "alpha.txt,beta.txt,notes.md", "1", "1", "false", "", "false"],
      [":bn<CR>", "alpha.txt beta.txt notes.md", "alpha.txt", "alpha.txt,beta.txt,notes.md", "1", "1", "false", "", "false"],
      [":e notes.md<CR><Space>dr:bp<CR>", "alpha.txt beta.txt notes.md", "notes.md", "alpha.txt,beta.txt,notes.md", "1", "1", "false", "", "false"],
      [":e notes.md<CR><Space>dr:b 2<CR>", "alpha.txt beta.txt notes.md", "beta.txt", "alpha.txt,beta.txt,notes.md", "1", "1", "false", "", "false"],
      [":e notes.md<CR><Space>dr<C-^>", "alpha.txt beta.txt notes.md", "notes.md", "alpha.txt,beta.txt,notes.md", "1", "1", "false", "", "false"],
      ["<Space>drgt", "alpha.txt beta.txt notes.md", "alpha.txt", "alpha.txt,beta.txt,notes.md", "1", "1", "false", "", "false"]
    ])
    # Scenario: Buffer switches from a reading view in a split act on the focused window.
    # Each <C-w>w step shows the other window kept beta.txt.
    flow(t, "Buffer switches from a reading view in a split act on the focused window: :bn, :bp, :b N, Ctrl-^, and gt", "", [
      [":e alpha.txt<CR>:e beta.txt<CR>:sp notes.md<CR><Space>dr", "alpha.txt beta.txt notes.md", "[reading] notes.md", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      [":bn<CR>", "alpha.txt beta.txt notes.md", "alpha.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w", "alpha.txt beta.txt notes.md", "beta.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w:e notes.md<CR><Space>dr:bp<CR>", "alpha.txt beta.txt notes.md", "notes.md", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w", "alpha.txt beta.txt notes.md", "beta.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w:e notes.md<CR><Space>dr:b 1<CR>", "alpha.txt beta.txt notes.md", "alpha.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w", "alpha.txt beta.txt notes.md", "beta.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w:e notes.md<CR><Space>dr<C-^>", "alpha.txt beta.txt notes.md", "notes.md", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w", "alpha.txt beta.txt notes.md", "beta.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w<Space>drgt", "alpha.txt beta.txt notes.md", "alpha.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"],
      ["<C-w>w", "alpha.txt beta.txt notes.md", "beta.txt", "alpha.txt,beta.txt,notes.md", "2", "1", "false", "", "false"]
    ])
    # Scenario: A refused switch from a side window keeps the previous window.
    flow(t, "A refused switch from a side window keeps the previous window: :b 99 from the explorer, then Ctrl-W p", "", [
      [":e alpha.txt<CR>:sp notes.md<CR><Space>dr", "alpha.txt notes.md", "[reading] notes.md", "alpha.txt,notes.md", "2", "1", "false", "", "false"],
      ["<Space>e", "proj alpha.txt notes.md", "explorer", "alpha.txt,notes.md", "3", "1", "true", "", "false"],
      [":b 99<CR>", "proj alpha.txt notes.md", "explorer", "alpha.txt,notes.md", "3", "1", "true", "E86: Buffer 99 does not exist", "false"],
      ["<C-w>p", "proj alpha.txt notes.md", "[reading] notes.md", "alpha.txt,notes.md", "3", "1", "true", "", "false"],
      ["<Space>e:bn<CR>", "proj alpha.txt notes.md", "notes.md", "alpha.txt,notes.md", "3", "1", "true", "", "false"]
    ])

    # Closing.
    flow(t, ":q, :q! on a modified buffer, and :wq down to the editor quitting", "", [
      [":e alpha.txt<CR>:e beta.txt<CR>:e lib/gamma.rb<CR>", "alpha.txt beta.txt gamma.rb", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "\"lib/gamma.rb\" 1L, 3B", "false"],
      ["x:q<CR>", "alpha.txt beta.txt gamma.rb *", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "E37: No write since last change (add ! to override)", "false"],
      [":q!<CR>", "alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"],
      ["x:wq<CR>", "1 a1", "alpha.txt", "alpha.txt", "1", "1", "false", "", "false"],
      [":q<CR>", "1 a1", "alpha.txt", "alpha.txt", "1", "1", "false", "", "true"]
    ])
    flow(t, ":bd, :bd N, and the leader delete down to the editor quitting", "", [
      [":e alpha.txt<CR>:e beta.txt<CR>:e lib/gamma.rb<CR>", "alpha.txt beta.txt gamma.rb", "lib/gamma.rb", "alpha.txt,beta.txt,lib/gamma.rb", "1", "1", "false", "\"lib/gamma.rb\" 1L, 3B", "false"],
      [":bd<CR>", "alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"],
      [":bd 1<CR>", "1 b1", "beta.txt", "beta.txt", "1", "1", "false", "", "false"],
      ["<Space>bd", "1", "[No Name]", "[No Name]", "1", "1", "false", "", "false"],
      [":q<CR>", "1", "[No Name]", "[No Name]", "1", "1", "false", "", "true"]
    ])
    flow(t, ":tabc and Ctrl-W q in a split down to the editor quitting", "", [
      [":e alpha.txt<CR>:tabe beta.txt<CR>", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "\"beta.txt\" 1L, 3B", "false"],
      [":tabc<CR>", "alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"],
      [":sp beta.txt<CR>", "alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "false", "\"beta.txt\" 1L, 3B", "false"],
      ["<C-w>q", "alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"],
      [":q<CR>", "1 b1", "beta.txt", "beta.txt", "1", "1", "false", "", "false"],
      [":q<CR>", "1 b1", "beta.txt", "beta.txt", "1", "1", "false", "", "true"]
    ])
    flow(t, "closing beside the explorer and toggling it down to the editor quitting", "", [
      ["<Space>e3Gt", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gt", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      [":q<CR>", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "", "false"],
      ["<Space>e4Gt", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      [":bd<CR>", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "", "false"],
      ["<Space>e", "proj 1 a1", "explorer", "alpha.txt", "2", "1", "true", "", "false"],
      ["<Space>e", "1 a1", "alpha.txt", "alpha.txt", "1", "1", "false", "", "false"],
      [":q<CR>", "1 a1", "alpha.txt", "alpha.txt", "1", "1", "false", "", "true"]
    ])

    # The user's reported sequences.
    flow(t, "the user's case D: gT from the explorer after :bd keeps the explorer", "", [
      ["<Space>e", "proj 1", "explorer", "[No Name]", "2", "1", "true", "", "false"],
      ["jj", "proj 1", "explorer", "[No Name]", "2", "1", "true", "", "false"],
      ["t", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["gT", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "", "false"],
      [":bd<CR>", "proj 1", "[No Name]", "[No Name]", "2", "1", "true", "", "false"],
      ["<Space>e", "proj 1", "explorer", "[No Name]", "2", "1", "true", "", "false"],
      ["gT", "proj 1", "[No Name]", "[No Name]", "2", "1", "true", "", "false"]
    ])
    flow(t, "the user's case A: t opens buffer tabs that gt and gT move between", "", [
      ["<Space>e", "proj 1", "explorer", "[No Name]", "2", "1", "true", "", "false"],
      ["jjt", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>ejt", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["gt", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["gT", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>egt", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"]
    ])

    # A lone tree: the file window closed with Ctrl-W c leaves only the
    # tree, and t or the finder's Ctrl-T opens a file window beside it
    # or in it, never a tab page beside a tab page of only the tree.
    # Under tab pages the startup buffer stays listed once hidden, so
    # those flows leave the tree after opening a file.
    flow(t, "t from a lone tree opens a file window", "", [
      ["<Space>e<C-w>l<C-w>c", "proj", "explorer", "[No Name]", "1", "1", "true", "", "false"],
      ["3Gt", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gt", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"]
    ])
    flow(t, "t from a lone tree under tab pages opens a file window", tabpages, [
      ["<Space>e3Gl<C-w>c", "proj", "explorer", "alpha.txt", "1", "1", "true", "", "false"],
      ["4Gt", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<Space>e3Gt", "alpha.txt beta.txt 1 2", "alpha.txt", "alpha.txt,beta.txt", "1", "2", "false", "\"alpha.txt\" 1L, 3B", "false"]
    ])
    flow(t, "Ctrl-T from a lone tree", "", [
      ["<Space>e<C-w>l<C-w>c", "proj", "explorer", "[No Name]", "1", "1", "true", "", "false"],
      ["<C-p>beta<C-t>", "1 b1", "beta.txt", "beta.txt", "1", "1", "false", "", "false"]
    ])
    flow(t, "Ctrl-T from a lone tree under tab pages", tabpages, [
      ["<Space>e3Gl<C-w>c", "proj", "explorer", "alpha.txt", "1", "1", "true", "", "false"],
      ["<C-p>beta<C-t>", "alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "1", "1", "false", "", "false"]
    ])
    flow(t, "Ctrl-T opens a buffer tab beside the explorer", "", [
      ["<Space>e3Gl", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<C-p>beta<C-t>", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"]
    ])
    flow(t, "Ctrl-T opens it in a tab page beside the explorer", tabpages, [
      ["<Space>e3Gl", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<C-p>beta<C-t>", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"]
    ])

    # The same flows under option.gt tabpages.
    flow(t, "tab pages: opening with l, s, v, and t", tabpages, [
      ["<Space>e3Gl", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gs", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "3", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<C-w>q", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e4Gv", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "3", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      ["<C-w>q", "proj alpha.txt beta.txt", "alpha.txt", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<Space>e4Gt", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "\"beta.txt\" 1L, 3B", "false"],
      [":tabe alpha.txt<CR>", "alpha.txt beta.txt 1 2 3", "alpha.txt", "alpha.txt,beta.txt", "1", "3", "false", "\"alpha.txt\" 1L, 3B", "false"],
      [":tabe<CR>", "alpha.txt beta.txt [No Name] 1 2 3 4", "[No Name]", "alpha.txt,beta.txt,[No Name]", "1", "4", "false", "", "false"],
      [":tabc<CR>", "alpha.txt beta.txt [No Name] 1 2 3", "alpha.txt", "alpha.txt,beta.txt,[No Name]", "1", "3", "false", "", "false"],
      [":bd 4<CR>", "alpha.txt beta.txt 1 2 3", "alpha.txt", "alpha.txt,beta.txt", "1", "3", "false", "", "false"]
    ])
    flow(t, "tab pages: moving from a file window and from the explorer", tabpages, [
      [":e alpha.txt<CR>:tabe beta.txt<CR>", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "\"beta.txt\" 1L, 3B", "false"],
      ["gt", "alpha.txt beta.txt 1 2", "alpha.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      ["gT", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      ["<C-PageDown>", "alpha.txt beta.txt 1 2", "alpha.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      ["<C-PageUp>", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      ["g<Tab>", "alpha.txt beta.txt 1 2", "alpha.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      ["1gt<Space>e", "proj alpha.txt beta.txt 1 2", "explorer", "alpha.txt,beta.txt", "2", "2", "true", "", "false"],
      ["gt", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "", "false"],
      ["1gt", "proj alpha.txt beta.txt 1 2", "explorer", "alpha.txt,beta.txt", "2", "2", "true", "", "false"],
      [":bn<CR>", "proj alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "2", "2", "true", "", "false"],
      ["<Space>e:bp<CR>", "proj alpha.txt beta.txt 1 2", "alpha.txt", "alpha.txt,beta.txt", "2", "2", "true", "", "false"]
    ])
    flow(t, "tab pages: closing down to the editor quitting", tabpages, [
      ["<Space>e3Gl", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "\"alpha.txt\" 1L, 3B", "false"],
      ["<Space>e4Gt", "alpha.txt beta.txt 1 2", "beta.txt", "alpha.txt,beta.txt", "1", "2", "false", "\"beta.txt\" 1L, 3B", "false"],
      [":tabc<CR>", "proj alpha.txt beta.txt", "explorer", "alpha.txt,beta.txt", "2", "1", "true", "", "false"],
      ["<C-w>l:e beta.txt<CR>", "proj alpha.txt beta.txt", "beta.txt", "alpha.txt,beta.txt", "2", "1", "true", "\"beta.txt\" 1L, 3B", "false"],
      [":bd<CR>", "proj 1 a1", "alpha.txt", "alpha.txt", "2", "1", "true", "", "false"],
      ["x:q<CR>", "proj 1 1", "alpha.txt", "alpha.txt", "2", "1", "true", "E37: No write since last change (add ! to override)", "false"],
      [":q!<CR>", "proj 1 1", "alpha.txt", "alpha.txt", "2", "1", "true", "", "true"]
    ])

    t.finish
  end
end

EditorTabFlowsTest.main if __FILE__ == $0
