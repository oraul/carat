require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # The :q rule: closes the current window when another exists in any tab
    # page, and ends the editor otherwise unless a listed buffer has unsaved
    # changes. A file window whose only companions in its tab page are
    # plugin side windows counts as the last window there, as Neovim's
    # tree plugins arrange: its tab page closes with them when other tab
    # pages exist, and the last-window rule applies otherwise. The way is
    # :quit for :q, :force for :q!, where a modified hidden buffer is shown
    # in the window instead of ending the editor, as Neovim does, so :qa!
    # is the only way to lose it, and :written after the write of :wq and
    # :x, which ends the editor unless another buffer is modified: the
    # buffer just written is not checked, since a write to another path
    # leaves it modified on purpose.
    class Quit
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, way)
        if @tabs.total_windows > 1
          return close_current(state) unless beside_side_windows?(state)
          return close_page(state) if @tabs.tab_count > 1
        end
        if way == :force
          hidden = @buffers.hidden_modified
          if hidden.nil?
            state.quit = true
          else
            @buffers.load(hidden)
          end
          return Outcome.success("")
        end
        if way == :written
          return Outcome.failure(Domain::Messages::E37) unless @buffers.hidden_modified.nil?
        elsif @buffers.any_modified?
          return Outcome.failure(Domain::Messages::E37)
        end
        state.quit = true
        Outcome.success("")
      end

      private

      #: (Domain::EditorState) -> Outcome
      def close_current(state)
        @buffers.close_window(@tabs.tab_index, state.tab.current)
        Outcome.success("")
      end

      # Whether the current window shows a file and every other window of
      # its tab page shows a plugin's scratch buffer, at least one.
      #: (Domain::EditorState) -> bool
      def beside_side_windows?(state)
        tab = state.tab
        layout = tab.layout
        return false if layout.leaf_count <= 1 || state.buffer.scratch?
        ids = layout.leaves
        i = 0
        while i < ids.length
          return false if ids[i] != tab.current && !layout.window_at(ids[i]).buffer.scratch?
          i += 1
        end
        true
      end

      # Closes the side windows of the current tab page, then the current
      # window, which closes the tab page.
      #: (Domain::EditorState) -> Outcome
      def close_page(state)
        tab = state.tab
        ids = tab.layout.leaves
        current = tab.current
        i = 0
        while i < ids.length
          @buffers.close_window(@tabs.tab_index, ids[i]) unless ids[i] == current
          i += 1
        end
        @buffers.close_window(@tabs.tab_index, current)
        Outcome.success("")
      end
    end
  end
end
