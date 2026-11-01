require_relative "../files/quit"
require_relative "../windows/split_window"
require_relative "../windows/close_window"
require_relative "../windows/focus_window"
require_relative "../windows/resize_layout"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The <C-w> commands: split, focus, close, only, equalize, and quit,
    # through the window use cases, with the count where Neovim takes one.
    class WindowHandler < ActionHandler
      # @rbs @split_window: SplitWindow
      # @rbs @close_window: CloseWindow
      # @rbs @focus_window: FocusWindow
      # @rbs @resize_layout: ResizeLayout
      # @rbs @quit: Quit
      # @rbs @variant: Symbol

      #: (split_window: SplitWindow, close_window: CloseWindow, focus_window: FocusWindow, resize_layout: ResizeLayout, quit: Quit, variant: Symbol) -> void
      def initialize(split_window:, close_window:, focus_window:, resize_layout:, quit:, variant:)
        super(kind: :action)
        @split_window = split_window
        @close_window = close_window
        @focus_window = focus_window
        @resize_layout = resize_layout
        @quit = quit
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        count = command.count
        focus = @focus_window
        case @variant
        when :split then @split_window.call(state, false, count, "", false)
        when :vsplit then @split_window.call(state, true, count, "", false)
        when :left then focus.direction(state, :left, count)
        when :down then focus.direction(state, :down, count)
        when :up then focus.direction(state, :up, count)
        when :right then focus.direction(state, :right, count)
        when :next then focus.cycle(state, true, count)
        when :previous then focus.cycle(state, false, count)
        when :last_accessed then focus.previous(state)
        when :close then @close_window.close(state, count)
        when :only then @close_window.only(state)
        when :equalize then @resize_layout.equalize(state)
        else quit_window(state, count)
        end
      end

      #: (ActionTable, split_window: SplitWindow, close_window: CloseWindow, focus_window: FocusWindow, resize_layout: ResizeLayout, quit: Quit) -> void
      def self.register(table, split_window:, close_window:, focus_window:, resize_layout:, quit:)
        names = ["window.split", "window.vsplit", "window.left", "window.down", "window.up", "window.right", "window.next", "window.previous", "window.last_accessed", "window.close", "window.only", "window.equalize", "window.quit"]
        variants = [:split, :vsplit, :left, :down, :up, :right, :next, :previous, :last_accessed, :close, :only, :equalize, :quit]
        i = 0
        while i < names.length
          table.register(names[i], WindowHandler.new(split_window: split_window, close_window: close_window, focus_window: focus_window, resize_layout: resize_layout, quit: quit, variant: variants[i]))
          i += 1
        end
      end

      private

      # Ctrl-W q: :q on the current window, or with a count on window n,
      # which closes it without moving the cursor as :{n}quit does.
      #: (Domain::EditorState, Integer) -> Outcome
      def quit_window(state, n)
        return @close_window.close(state, n) if n > 0 && state.total_windows > 1
        @quit.call(state, false)
      end
    end
  end
end
