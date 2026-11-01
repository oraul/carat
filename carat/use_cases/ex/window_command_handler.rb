require_relative "../../domain/editor_state"
require_relative "../windows/split_window"
require_relative "../windows/close_window"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The ex commands of windows: :sp, :vs, :new, :vne, :clo, and :on.
    class WindowCommandHandler < ExHandler
      # @rbs @split_window: SplitWindow
      # @rbs @close_window: CloseWindow
      # @rbs @variant: Symbol

      #: (spec: String, split_window: SplitWindow, close_window: CloseWindow, variant: Symbol) -> void
      def initialize(spec:, split_window:, close_window:, variant:)
        super(spec: spec)
        @split_window = split_window
        @close_window = close_window
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        split = @split_window
        case @variant
        when :split then split.call(state, false, 0, command.args, false)
        when :vsplit then split.call(state, true, 0, command.args, false)
        when :new then split.call(state, false, 0, "", true)
        when :vnew then split.call(state, true, 0, "", true)
        when :close then @close_window.close(state, 0)
        else @close_window.only(state)
        end
      end

      # Registers the window commands in the order of docs/compatibility.md.
      #: (ExTable, split_window: SplitWindow, close_window: CloseWindow) -> void
      def self.register(table, split_window:, close_window:)
        specs = ["sp[lit]", "vs[plit]", "new", "vne[w]", "clo[se]", "on[ly]"]
        variants = [:split, :vsplit, :new, :vnew, :close, :only]
        i = 0
        while i < specs.length
          table.register(WindowCommandHandler.new(spec: specs[i], split_window: split_window, close_window: close_window, variant: variants[i]))
          i += 1
        end
      end
    end
  end
end
