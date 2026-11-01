require_relative "../enter_insert"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # i a I A o O: enter insert mode at the place EnterInsert names.
    class InsertModeHandler < ActionHandler
      # @rbs @enter_insert: EnterInsert
      # @rbs @where: Symbol

      #: (enter_insert: EnterInsert, where: Symbol) -> void
      def initialize(enter_insert:, where:)
        super(kind: :action)
        @enter_insert = enter_insert
        @where = where
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @enter_insert.call(state, @where)
      end

      #: (ActionTable, enter_insert: EnterInsert) -> void
      def self.register(table, enter_insert:)
        table.register("mode.insert", InsertModeHandler.new(enter_insert: enter_insert, where: :before))
        table.register("mode.insert_after", InsertModeHandler.new(enter_insert: enter_insert, where: :after))
        table.register("mode.insert_line_start", InsertModeHandler.new(enter_insert: enter_insert, where: :line_start))
        table.register("mode.insert_line_end", InsertModeHandler.new(enter_insert: enter_insert, where: :line_end))
        table.register("mode.insert_open_below", InsertModeHandler.new(enter_insert: enter_insert, where: :open_below))
        table.register("mode.insert_open_above", InsertModeHandler.new(enter_insert: enter_insert, where: :open_above))
      end
    end
  end
end
