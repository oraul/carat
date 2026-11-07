require_relative "../windows/close_float"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Esc in normal mode: closes the topmost floating window through
    # CloseFloat, doing nothing when none is open.
    class FloatHandler < ActionHandler
      # @rbs @close_float: CloseFloat

      #: (close_float: CloseFloat) -> void
      def initialize(close_float:)
        super(kind: :action, repeat: false)
        @close_float = close_float
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @close_float.call(state, 0)
      end

      #: (ActionTable, close_float: CloseFloat) -> void
      def self.register(table, close_float:)
        table.register("float.close", FloatHandler.new(close_float: close_float), "Close the topmost floating window")
      end
    end
  end
end
