require_relative "../../domain/tab_list"
require_relative "../files/quit"
require_relative "../windows/split_window"
require_relative "../windows/close_window"
require_relative "../windows/close_other_windows"
require_relative "../windows/focus_window"
require_relative "../windows/focus_request"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The <C-w> commands: split through SplitWindow, focus through
    # FocusWindow, close through CloseWindow, only through
    # CloseOtherWindows, equalize, and quit through Quit, with the count
    # where Neovim takes one. Equalizing makes the windows of every split
    # the same size, leaving fixed-width windows alone.
    class WindowHandler < ActionHandler
      # @rbs @split_window: SplitWindow
      # @rbs @close_window: CloseWindow
      # @rbs @close_other_windows: CloseOtherWindows
      # @rbs @focus_window: FocusWindow
      # @rbs @quit: Quit
      # @rbs @tabs: Domain::TabList
      # @rbs @variant: Symbol

      #: (split_window: SplitWindow, close_window: CloseWindow, close_other_windows: CloseOtherWindows, focus_window: FocusWindow, quit: Quit, tabs: Domain::TabList, variant: Symbol) -> void
      def initialize(split_window:, close_window:, close_other_windows:, focus_window:, quit:, tabs:, variant:)
        super(kind: :action, repeat: false)
        @split_window = split_window
        @close_window = close_window
        @close_other_windows = close_other_windows
        @focus_window = focus_window
        @quit = quit
        @tabs = tabs
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        count = command.count
        case @variant
        when :split then @split_window.call(state, false, count, "", false)
        when :vsplit then @split_window.call(state, true, count, "", false)
        when :close then @close_window.call(state, count)
        when :only then @close_other_windows.call(state)
        when :equalize then equalize(state)
        when :quit then quit_window(state, count)
        else @focus_window.call(state, FocusRequest.new(target: @variant, count: count))
        end
      end

      #: (ActionTable, split_window: SplitWindow, close_window: CloseWindow, close_other_windows: CloseOtherWindows, focus_window: FocusWindow, quit: Quit, tabs: Domain::TabList) -> void
      def self.register(table, split_window:, close_window:, close_other_windows:, focus_window:, quit:, tabs:)
        names = ["window.split", "window.vsplit", "window.left", "window.down", "window.up", "window.right", "window.next", "window.previous", "window.last_accessed", "window.close", "window.only", "window.equalize", "window.quit"]
        variants = [:split, :vsplit, :left, :down, :up, :right, :next, :previous, :last_accessed, :close, :only, :equalize, :quit]
        i = 0
        while i < names.length
          table.register(names[i], WindowHandler.new(split_window: split_window, close_window: close_window, close_other_windows: close_other_windows, focus_window: focus_window, quit: quit, tabs: tabs, variant: variants[i]))
          i += 1
        end
      end

      private

      # Ctrl-W =.
      #: (Domain::EditorState) -> Outcome
      def equalize(state)
        state.tab.layout.equalize
        Outcome.none
      end

      # Ctrl-W q: :q on the current window, or with a count on window n,
      # which closes it without moving the cursor as :{n}quit does.
      #: (Domain::EditorState, Integer) -> Outcome
      def quit_window(state, n)
        return @close_window.call(state, n) if n > 0 && @tabs.total_windows > 1
        @quit.call(state, :quit)
      end
    end
  end
end
