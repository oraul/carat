require_relative "../insert_text"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The insert-mode keys bound to actions: Enter, Backspace, Delete, and
    # Tab, through InsertText. Typed text does not come here: HandleKey
    # inserts an unbound printable key directly.
    class InsertTextHandler < ActionHandler
      # @rbs @insert_text: InsertText
      # @rbs @variant: Symbol

      #: (insert_text: InsertText, variant: Symbol) -> void
      def initialize(insert_text:, variant:)
        super(kind: :action, repeat: false)
        @insert_text = insert_text
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :newline then @insert_text.newline(state)
        when :backspace then @insert_text.backspace(state)
        when :delete then @insert_text.delete(state)
        else @insert_text.tab(state)
        end
      end

      #: (ActionTable, insert_text: InsertText) -> void
      def self.register(table, insert_text:)
        table.register("insert.newline", InsertTextHandler.new(insert_text: insert_text, variant: :newline))
        table.register("insert.backspace", InsertTextHandler.new(insert_text: insert_text, variant: :backspace))
        table.register("insert.delete", InsertTextHandler.new(insert_text: insert_text, variant: :delete))
        table.register("insert.tab", InsertTextHandler.new(insert_text: insert_text, variant: :tab))
      end
    end
  end
end
