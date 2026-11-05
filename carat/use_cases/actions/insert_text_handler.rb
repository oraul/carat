require_relative "../break_line"
require_relative "../erase_character"
require_relative "../insert_tab"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The insert-mode keys bound to actions: Enter through BreakLine,
    # Backspace and Delete through EraseCharacter, and Tab through
    # InsertTab. Typed text does not come here: HandleKey inserts an
    # unbound printable key through InsertText.
    class InsertTextHandler < ActionHandler
      # @rbs @break_line: BreakLine
      # @rbs @erase_character: EraseCharacter
      # @rbs @insert_tab: InsertTab
      # @rbs @variant: Symbol

      #: (break_line: BreakLine, erase_character: EraseCharacter, insert_tab: InsertTab, variant: Symbol) -> void
      def initialize(break_line:, erase_character:, insert_tab:, variant:)
        super(kind: :action, repeat: false)
        @break_line = break_line
        @erase_character = erase_character
        @insert_tab = insert_tab
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :newline then @break_line.call(state)
        when :backspace then @erase_character.call(state, false)
        when :delete then @erase_character.call(state, true)
        else @insert_tab.call(state)
        end
      end

      #: (ActionTable, break_line: BreakLine, erase_character: EraseCharacter, insert_tab: InsertTab) -> void
      def self.register(table, break_line:, erase_character:, insert_tab:)
        names = ["insert.newline", "insert.backspace", "insert.delete", "insert.tab"]
        variants = [:newline, :backspace, :delete, :tab]
        descriptions = ["Break line", "Erase before cursor", "Erase under cursor", "Insert tab"]
        i = 0
        while i < names.length
          table.register(names[i], InsertTextHandler.new(break_line: break_line, erase_character: erase_character, insert_tab: insert_tab, variant: variants[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
