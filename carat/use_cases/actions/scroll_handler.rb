require_relative "../windows/scroll_window"
require_relative "../windows/scroll_request"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # <C-f> <C-b> <C-d> <C-u> <C-e> <C-y> zt zz zb and <PageDown> <PageUp>
    # with their counts, through ScrollWindow. An action that completes at
    # once, in normal, visual, and insert mode alike. In insert mode it
    # breaks the insert session as a motion does, as a page key does in
    # Neovim.
    class ScrollHandler < ActionHandler
      # @rbs @scroll_window: ScrollWindow
      # @rbs @target: Symbol

      #: (scroll_window: ScrollWindow, target: Symbol) -> void
      def initialize(scroll_window:, target:)
        super(kind: :action, repeat: false)
        @breaks_insert = true
        @scroll_window = scroll_window
        @target = target
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @scroll_window.call(state, ScrollRequest.new(target: @target, count: command.count))
      end

      #: (ActionTable, scroll_window: ScrollWindow) -> void
      def self.register(table, scroll_window:)
        names = ["scroll.page_down", "scroll.page_up", "scroll.half_page_down", "scroll.half_page_up", "scroll.line_down", "scroll.line_up", "scroll.cursor_top", "scroll.cursor_middle", "scroll.cursor_bottom"]
        targets = [:page_down, :page_up, :half_down, :half_up, :line_down, :line_up, :cursor_top, :cursor_middle, :cursor_bottom]
        descriptions = ["Page down", "Page up", "Half page down", "Half page up", "Scroll line down", "Scroll line up", "Cursor line to top", "Cursor line to middle", "Cursor line to bottom"]
        i = 0
        while i < names.length
          table.register(names[i], ScrollHandler.new(scroll_window: scroll_window, target: targets[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
