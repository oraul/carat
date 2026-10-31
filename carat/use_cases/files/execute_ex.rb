require_relative "../../domain/editor_state"
require_relative "../../domain/ex_grammar"
require_relative "../outcome"
require_relative "open_file"
require_relative "save_file"
require_relative "quit"
require_relative "../windows/split_window"
require_relative "../windows/close_window"
require_relative "../windows/open_tab"
require_relative "../windows/close_tab"
require_relative "../windows/switch_tab"
require_relative "../plugins/plugin_host"

module Carat
  module UseCases
    # Parses a command line and runs the matching ex command. The registry is
    # the case below; later changes add their commands as arms, and a name
    # no arm takes is offered to the plugins before it is unknown. The
    # "all" commands act on every buffer in the list, across every tab
    # page.
    class ExecuteEx
      # @rbs @open_file: OpenFile
      # @rbs @save_file: SaveFile
      # @rbs @quit: Quit
      # @rbs @split_window: SplitWindow
      # @rbs @close_window: CloseWindow
      # @rbs @open_tab: OpenTab
      # @rbs @close_tab: CloseTab
      # @rbs @switch_tab: SwitchTab
      # @rbs @plugins: PluginHost

      #: (OpenFile, SaveFile, Quit, SplitWindow, CloseWindow, OpenTab, CloseTab, SwitchTab, PluginHost) -> void
      def initialize(open_file, save_file, quit, split_window, close_window, open_tab, close_tab, switch_tab, plugins)
        @open_file = open_file
        @save_file = save_file
        @quit = quit
        @split_window = split_window
        @close_window = close_window
        @open_tab = open_tab
        @close_tab = close_tab
        @switch_tab = switch_tab
        @plugins = plugins
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        command = Domain::ExGrammar.parse(text)
        case command.name
        when ""
          command.args.empty? ? Outcome.success("") : unknown(text)
        when "w", "write"
          @save_file.call(state, command.args)
        when "q", "quit"
          @quit.call(state, command.bang)
        when "wq"
          written = @save_file.call(state, command.args)
          return written unless written.ok
          @quit.leave(state)
        when "x", "xit", "exi", "exit"
          exit_editor(state, command)
        when "wa", "wall"
          write_all(state)
        when "qa", "qall", "quita", "quitall"
          @quit.all(state, command.bang)
        when "wqa", "wqall", "xa", "xall"
          written = write_all(state)
          return written unless written.ok
          @quit.all(state, true)
        when "e", "edit"
          edit(state, command)
        when "sp", "split"
          @split_window.call(state, false, 0, command.args, false)
        when "vs", "vsplit"
          @split_window.call(state, true, 0, command.args, false)
        when "new"
          @split_window.call(state, false, 0, "", true)
        when "vne", "vnew"
          @split_window.call(state, true, 0, "", true)
        when "clo", "close"
          @close_window.close(state, 0)
        when "on", "only"
          @close_window.only(state)
        when "tabnew", "tabe", "tabedit"
          @open_tab.call(state, command.args)
        when "tabc", "tabclose"
          @close_tab.close(state)
        when "tabo", "tabonly"
          @close_tab.only(state)
        when "tabn", "tabnext"
          @switch_tab.next(state, 0)
        when "tabp", "tabprevious", "tabN", "tabNext"
          @switch_tab.previous(state, 0)
        when "tabfir", "tabfirst"
          @switch_tab.first(state)
        when "tabl", "tablast"
          @switch_tab.last(state)
        else
          @plugins.command?(command.name) ? @plugins.command(command) : unknown(text)
        end
      end

      private

      #: (String) -> Outcome
      def unknown(text)
        shown = text.strip
        shown = shown[1, shown.length - 1] while shown.start_with?(":")
        Outcome.failure("E492: Not an editor command: #{shown}")
      end

      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def edit(state, command)
        path = command.args.empty? ? state.buffer.path : command.args
        return Outcome.failure("E32: No file name") if path.nil?
        return Outcome.failure(Quit::E37) if state.buffer.modified && !command.bang
        @open_file.call(state, path)
      end

      # :x writes only when there is something to write: a modified buffer or
      # a file argument. After a successful write it leaves as :wq does.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def exit_editor(state, command)
        if state.buffer.modified || !command.args.empty?
          written = @save_file.call(state, command.args)
          return written unless written.ok
        end
        @quit.leave(state)
      end

      # Writes every modified buffer to its own path, in list order, and
      # reports the last write, or the first failure: a modified buffer with
      # no name reports E141 with its list position, and the other buffers
      # are still written, as Neovim's do_wqall goes on after an error. A
      # scratch buffer is skipped. A hidden buffer that is clean after its
      # write leaves the list.
      #: (Domain::EditorState) -> Outcome
      def write_all(state)
        result = Outcome.success("")
        failed = false
        i = 0
        while i < state.buffer_count
          buffer = state.buffer_at(i)
          if buffer.modified && !buffer.scratch?
            written = buffer.path.nil? ? Outcome.failure("E141: No file name for buffer #{i + 1}") : @save_file.write(buffer, "")
            if !written.ok && !failed
              result = written
              failed = true
            elsif !failed
              result = written
            end
          end
          i += 1
        end
        i = state.buffer_count - 1
        while i >= 0
          state.release(state.buffer_at(i))
          i -= 1
        end
        result
      end
    end
  end
end
