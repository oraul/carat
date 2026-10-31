require_relative "../../plugin_api"
require_relative "tree"

module Carat
  module Plugins
    module Explorer
      # The file tree: a scratch buffer in a fixed-width side window rooted
      # at the working directory, with icons from the host's table, the
      # current file marked and revealed, and the keys of common Neovim
      # tree plugins in the window's own keymap. Every change to the file
      # system goes through the host's validated requests, and names and
      # confirmations are asked for with the host's prompt.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "explorer"
        TITLE = "explorer"
        HELP = "<CR>/l open  h close  o toggle  s/v/t split/vsplit/tab  a add  r rename  d delete  R refresh  H hidden  - up  C root  q quit"

        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @tree: Tree?
        # @rbs @cwd: String
        # @rbs @followed: String
        # @rbs @pending: String

        #: () -> void
        def initialize
          @host = nil
          @tree = nil
          @cwd = ""
          @followed = ""
          @pending = ""
        end

        # Returns the manifest.
        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(
            NAME,
            "0.1.0",
            Carat::PluginApi::VERSION,
            {
              "plugin.explorer.toggle" => "Open the file tree, focus it, or close it when it is focused",
              "plugin.explorer.focus" => "Open the file tree or focus it",
              "plugin.explorer.open" => "Open the file under the cursor in the editing window, or expand the directory",
              "plugin.explorer.collapse" => "Collapse the directory under the cursor, or go to its parent",
              "plugin.explorer.toggle_dir" => "Expand or collapse the directory under the cursor, or open the file",
              "plugin.explorer.open_split" => "Open the file under the cursor in a horizontal split",
              "plugin.explorer.open_vsplit" => "Open the file under the cursor in a vertical split",
              "plugin.explorer.open_tab" => "Open the file under the cursor in a new tab page",
              "plugin.explorer.create" => "Create a file, or a directory with a trailing /, next to the entry",
              "plugin.explorer.rename" => "Rename the entry under the cursor",
              "plugin.explorer.delete" => "Delete the file or empty directory under the cursor after confirmation",
              "plugin.explorer.refresh" => "List the tree again from disk",
              "plugin.explorer.toggle_hidden" => "Show or hide entries whose name starts with a dot",
              "plugin.explorer.root_up" => "Make the parent of the root the root",
              "plugin.explorer.set_root" => "Make the directory under the cursor the root",
              "plugin.explorer.close" => "Close the file tree",
              "plugin.explorer.help" => "Show the tree's keys in the message row"
            },
            { "Explorer" => "", "ExplorerFind" => "" },
            { "normal" => { "<leader>e" => "plugin.explorer.toggle" } },
            ["buffer_open", "window_focus", "cursor_move"],
            { "width" => "30", "side" => "left", "show_hidden" => "false", "ignore" => ".git\nbuild\ntmp" },
            { "width" => "integer", "side" => "string", "show_hidden" => "bool", "ignore" => "list" }
          )
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        # Follows the file of the current window: buffer_open, window_focus,
        # and cursor_move all carry its path, "" for a plugin window or an
        # unnamed buffer, which change nothing.
        #: (Carat::PluginApi::Event) -> void
        def on_event(event)
          host = @host
          return if host.nil?
          follow(host, event.path)
        end

        #: (String, Carat::PluginApi::Context) -> void
        def on_action(name, context)
          host = @host
          return if host.nil?
          case name
          when "plugin.explorer.toggle" then toggle(host, context.window)
          when "plugin.explorer.focus" then focus(host)
          else
            return unless in_tree?(host, context.window)
            tree_action(host, name, context.row)
          end
        end

        #: (Carat::PluginApi::Command) -> void
        def on_command(command)
          host = @host
          return if host.nil?
          if command.name == "ExplorerFind"
            show_tree(host)
          else
            toggle(host, current_window(host))
          end
        end

        #: (Carat::PluginApi::Input) -> void
        def on_input(input)
          host = @host
          return if host.nil?
          target = @pending
          @pending = ""
          return if target.empty?
          case input.id
          when "create" then finish_create(host, target, input)
          when "rename" then finish_rename(host, target, input)
          when "delete" then finish_delete(host, target, input)
          end
        end

        private

        # ---------------------------------------------------------- opening

        #: (Carat::PluginApi::Host, Integer) -> void
        def toggle(host, window)
          shown = host.scratch_window(TITLE).window
          if shown == 0
            show_tree(host)
          elsif shown == window
            report(host, host.close_scratch(TITLE))
          else
            host.focus_window(shown)
          end
        end

        #: (Carat::PluginApi::Host) -> void
        def focus(host)
          shown = host.scratch_window(TITLE).window
          if shown == 0
            show_tree(host)
          else
            host.focus_window(shown)
          end
        end

        # Opens the tree, or refreshes and focuses it, with the current file
        # revealed and the cursor on it.
        #: (Carat::PluginApi::Host) -> void
        def show_tree(host)
          tree = tree_of(host)
          tree.mark(@followed)
          tree.reveal(@followed) unless @followed.empty?
          tree.build(host)
          opened = host.open_scratch(TITLE, side(host), width(host), tree.lines(host), keymap)
          unless opened.ok
            report_window(host, opened)
            return
          end
          row = tree.row_of(@followed)
          host.move_cursor(row, 0) if row >= 0
        end

        # The id of the current window, for an ex command, which carries no
        # context: focusing window 0 answers it and changes nothing.
        #: (Carat::PluginApi::Host) -> Integer
        def current_window(host)
          host.focus_window(0).window
        end

        #: (Carat::PluginApi::Host, Integer) -> bool
        def in_tree?(host, window)
          shown = host.scratch_window(TITLE).window
          shown > 0 && shown == window
        end

        # ---------------------------------------------------------- follow

        #: (Carat::PluginApi::Host, String) -> void
        def follow(host, path)
          return if path.empty?
          absolute = PluginApi::Paths.absolute(cwd(host), path)
          return if absolute == @followed
          @followed = absolute
          tree = @tree
          return if tree.nil?
          tree.mark(absolute)
          return if host.scratch_window(TITLE).window == 0
          tree.reveal(absolute)
          refresh(host, tree)
        end

        # ------------------------------------------------------ tree keys

        #: (Carat::PluginApi::Host, String, Integer) -> void
        def tree_action(host, name, row)
          tree = tree_of(host)
          case name
          when "plugin.explorer.open" then open_entry(host, tree, row, :edit)
          when "plugin.explorer.toggle_dir" then open_entry(host, tree, row, :toggle)
          when "plugin.explorer.open_split" then open_entry(host, tree, row, :split)
          when "plugin.explorer.open_vsplit" then open_entry(host, tree, row, :vsplit)
          when "plugin.explorer.open_tab" then open_entry(host, tree, row, :tab)
          when "plugin.explorer.collapse" then collapse(host, tree, row)
          when "plugin.explorer.create" then ask_create(host, tree, row)
          when "plugin.explorer.rename" then ask_rename(host, tree, row)
          when "plugin.explorer.delete" then ask_delete(host, tree, row)
          when "plugin.explorer.refresh" then refresh(host, tree)
          when "plugin.explorer.toggle_hidden"
            tree.toggle_hidden
            refresh(host, tree)
          when "plugin.explorer.root_up" then root_up(host, tree)
          when "plugin.explorer.set_root" then set_root(host, tree, row)
          when "plugin.explorer.close" then report(host, host.close_scratch(TITLE))
          when "plugin.explorer.help" then host.message(HELP, false)
          end
        end

        # A directory expands (or toggles with o); a file opens in the
        # editing window, a split, or a tab page.
        #: (Carat::PluginApi::Host, Tree, Integer, Symbol) -> void
        def open_entry(host, tree, row, how)
          n = tree.at(row)
          return if n.nil?
          if n.directory
            return if n.root?
            if how == :toggle
              tree.toggle(n.path)
            elsif how == :edit
              tree.expand(n.path)
            else
              return
            end
            refresh(host, tree)
            return
          end
          open_path(host, n.path, how)
        end

        # The path goes to the host as it is, never inside an ex command
        # line, so a name with a space or a bar opens as named.
        #: (Carat::PluginApi::Host, String, Symbol) -> void
        def open_path(host, path, how)
          relative = PluginApi::Paths.relative(cwd(host), path)
          if how == :tab
            report_window(host, host.open_in_tab(relative))
            return
          end
          target = host.editing_window.window
          if target == 0
            open_in_tree_window(host, relative)
            return
          end
          case how
          when :split, :vsplit
            report_window(host, host.open_in_split(target, relative, how == :vsplit))
          else
            report_window(host, host.open_file(target, relative))
          end
        end

        # No window shows a file: the tree's window takes the file, and the
        # tree opens again at the edge, so the file gets the rest of the
        # width; the file window stays current.
        #: (Carat::PluginApi::Host, String) -> void
        def open_in_tree_window(host, relative)
          opened = host.open_file(host.scratch_window(TITLE).window, relative)
          report_window(host, opened)
          return unless opened.ok
          tree = tree_of(host)
          tree.build(host)
          again = host.open_scratch(TITLE, side(host), width(host), tree.lines(host), keymap)
          return unless again.ok
          host.focus_window(host.editing_window.window)
        end

        #: (Carat::PluginApi::Host, Tree, Integer) -> void
        def collapse(host, tree, row)
          n = tree.at(row)
          return if n.nil? || n.root?
          if n.directory && tree.expanded?(n.path)
            tree.collapse(n.path)
            refresh(host, tree)
            return
          end
          parent = tree.parent_row(row)
          host.move_cursor(parent, 0) if parent >= 0
        end

        #: (Carat::PluginApi::Host, Tree) -> void
        def root_up(host, tree)
          old = tree.root
          return if old == "/"
          tree.set_root(PluginApi::Paths.dirname(old))
          tree.expand(old)
          refresh(host, tree)
          row = tree.row_of(old)
          host.move_cursor(row, 0) if row >= 0
        end

        #: (Carat::PluginApi::Host, Tree, Integer) -> void
        def set_root(host, tree, row)
          n = tree.at(row)
          return if n.nil? || n.root?
          tree.set_root(n.directory ? n.path : PluginApi::Paths.dirname(n.path))
          refresh(host, tree)
          host.move_cursor(0, 0)
        end

        # ------------------------------------------------ file operations

        #: (Carat::PluginApi::Host, Tree, Integer) -> void
        def ask_create(host, tree, row)
          n = tree.at(row)
          return if n.nil?
          dir = n.directory ? n.path : PluginApi::Paths.dirname(n.path)
          ask(host, "create", dir, "Create in #{label(tree, dir)}/: ", "")
        end

        #: (Carat::PluginApi::Host, Tree, Integer) -> void
        def ask_rename(host, tree, row)
          n = tree.at(row)
          return if n.nil?
          if n.root?
            host.message("Cannot rename the root", true)
            return
          end
          ask(host, "rename", n.path, "Rename to: ", n.name)
        end

        #: (Carat::PluginApi::Host, Tree, Integer) -> void
        def ask_delete(host, tree, row)
          n = tree.at(row)
          return if n.nil?
          if n.root?
            host.message("Cannot delete the root", true)
            return
          end
          ask(host, "delete", n.path, "Delete #{n.name}? (y/n): ", "")
        end

        #: (Carat::PluginApi::Host, String, String, String, String) -> void
        def ask(host, id, target, text, initial)
          asked = host.prompt(id, text, initial)
          if asked.ok
            @pending = target
          else
            report(host, asked)
          end
        end

        #: (Carat::PluginApi::Host, String, Carat::PluginApi::Input) -> void
        def finish_create(host, dir, input)
          return unless input.answered?
          tree = tree_of(host)
          text = input.text
          directory = text.end_with?("/")
          name = text
          name = name[0, name.length - 1] while name.end_with?("/") && name.length > 1
          path = PluginApi::Paths.join(dir, name)
          made = directory ? host.make_dir(tree.root, path) : host.make_file(tree.root, path)
          unless made.ok
            report(host, made)
            return
          end
          created = PluginApi::Paths.absolute(cwd(host), path)
          tree.expand(dir) unless dir == tree.root
          tree.reveal(created)
          refresh(host, tree)
          row = tree.row_of(created)
          host.move_cursor(row, 0) if row >= 0
          host.message("Created #{PluginApi::Paths.relative(cwd(host), created)}", false)
        end

        #: (Carat::PluginApi::Host, String, Carat::PluginApi::Input) -> void
        def finish_rename(host, path, input)
          return unless input.answered?
          tree = tree_of(host)
          renamed = host.rename_path(tree.root, path, input.text)
          unless renamed.ok
            report(host, renamed)
            return
          end
          target = PluginApi::Paths.join(PluginApi::Paths.dirname(path), input.text)
          tree.moved(path, target)
          @followed = target if @followed == path
          refresh(host, tree)
          row = tree.row_of(target)
          host.move_cursor(row, 0) if row >= 0
          host.message("Renamed #{PluginApi::Paths.basename(path)} to #{input.text}", false)
        end

        #: (Carat::PluginApi::Host, String, Carat::PluginApi::Input) -> void
        def finish_delete(host, path, input)
          answer = input.cancelled ? "" : input.text.strip.downcase
          unless answer == "y" || answer == "yes"
            host.message("Delete cancelled", false)
            return
          end
          tree = tree_of(host)
          deleted = host.delete_path(tree.root, path)
          unless deleted.ok
            report(host, deleted)
            return
          end
          tree.collapse(path)
          refresh(host, tree)
          host.message("Deleted #{PluginApi::Paths.relative(cwd(host), path)}", false)
        end

        # ------------------------------------------------------- helpers

        #: (Carat::PluginApi::Host) -> Tree
        def tree_of(host)
          tree = @tree
          return tree unless tree.nil?
          made = Tree.new(cwd(host), host.option("show_hidden").text == "true", ignored(host))
          made.mark(@followed)
          @tree = made
          made
        end

        #: (Carat::PluginApi::Host, Tree) -> void
        def refresh(host, tree)
          tree.build(host)
          host.set_scratch_lines(TITLE, tree.lines(host))
        end

        #: (Carat::PluginApi::Host) -> String
        def cwd(host)
          @cwd = host.working_directory.text if @cwd.empty?
          @cwd
        end

        #: (Carat::PluginApi::Host) -> Array[String]
        def ignored(host)
          text = host.option("ignore").text
          text.empty? ? [] : text.split("\n")
        end

        #: (Carat::PluginApi::Host) -> Integer
        def width(host)
          value = host.option("width").text.to_i
          value > 0 ? value : 30
        end

        #: (Carat::PluginApi::Host) -> String
        def side(host)
          host.option("side").text == "right" ? "right" : "left"
        end

        # A directory as the prompt names it: the root by its name, the
        # rest relative to the root's parent.
        #: (Tree, String) -> String
        def label(tree, dir)
          PluginApi::Paths.relative(PluginApi::Paths.dirname(tree.root), dir)
        end

        # Shows a response's message, as an error when it failed.
        #: (Carat::PluginApi::Host, Carat::PluginApi::Response) -> void
        def report(host, response)
          host.message(response.message, !response.ok) unless response.message.empty?
        end

        # Shows a window response's message, as an error when it failed.
        #: (Carat::PluginApi::Host, Carat::PluginApi::WindowResponse) -> void
        def report_window(host, response)
          host.message(response.message, !response.ok) unless response.message.empty?
        end

        # The tree window's own keys; the rest fall through to the normal
        # keymap.
        #: () -> untyped
        def keymap
          {
            "normal" => {
              "<CR>" => "plugin.explorer.open",
              "l" => "plugin.explorer.open",
              "h" => "plugin.explorer.collapse",
              "o" => "plugin.explorer.toggle_dir",
              "s" => "plugin.explorer.open_split",
              "v" => "plugin.explorer.open_vsplit",
              "t" => "plugin.explorer.open_tab",
              "a" => "plugin.explorer.create",
              "r" => "plugin.explorer.rename",
              "d" => "plugin.explorer.delete",
              "R" => "plugin.explorer.refresh",
              "H" => "plugin.explorer.toggle_hidden",
              "-" => "plugin.explorer.root_up",
              "C" => "plugin.explorer.set_root",
              "q" => "plugin.explorer.close",
              "?" => "plugin.explorer.help"
            }
          }
        end
      end
    end
  end
end
