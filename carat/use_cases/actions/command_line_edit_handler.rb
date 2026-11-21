require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../move_command_line_cursor"
require_relative "../delete_command_line_text"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The keys that edit the command line at its cursor: the cursor moves
    # through MoveCommandLineCursor (cmdline.left, right, home, end,
    # word_left, word_right) and the deletions through
    # DeleteCommandLineText (cmdline.delete, delete_word, delete_line).
    class CommandLineEditHandler < ActionHandler
      # @rbs @move_command_line_cursor: MoveCommandLineCursor
      # @rbs @delete_command_line_text: DeleteCommandLineText
      # @rbs @variant: Symbol

      #: (move_command_line_cursor: MoveCommandLineCursor, delete_command_line_text: DeleteCommandLineText, variant: Symbol) -> void
      def initialize(move_command_line_cursor:, delete_command_line_text:, variant:)
        super(kind: :action, repeat: false)
        @move_command_line_cursor = move_command_line_cursor
        @delete_command_line_text = delete_command_line_text
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :delete then @delete_command_line_text.call(state, :under)
        when :delete_word then @delete_command_line_text.call(state, :word)
        when :delete_line then @delete_command_line_text.call(state, :line)
        else @move_command_line_cursor.call(state, @variant)
        end
      end

      #: (ActionTable, move_command_line_cursor: MoveCommandLineCursor, delete_command_line_text: DeleteCommandLineText) -> void
      def self.register(table, move_command_line_cursor:, delete_command_line_text:)
        names = ["cmdline.left", "cmdline.right", "cmdline.home", "cmdline.end", "cmdline.word_left", "cmdline.word_right", "cmdline.delete", "cmdline.delete_word", "cmdline.delete_line"]
        variants = [:left, :right, :home, :end, :word_left, :word_right, :delete, :delete_word, :delete_line]
        descriptions = ["Command line cursor left", "Command line cursor right", "Command line cursor to start", "Command line cursor to end", "Command line cursor word left", "Command line cursor word right", "Delete under command line cursor", "Delete command line word", "Delete command line to cursor"]
        i = 0
        while i < names.length
          table.register(names[i], CommandLineEditHandler.new(move_command_line_cursor: move_command_line_cursor, delete_command_line_text: delete_command_line_text, variant: variants[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
