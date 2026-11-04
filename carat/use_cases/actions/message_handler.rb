require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # An action that only answers a message: the quit hint on <C-c> and
    # the register prefix (which the grammar consumes, so it is never
    # run).
    class MessageHandler < ActionHandler
      QUIT_HINT = "Type  :q!  and press <Enter> to abandon all changes and exit Carat"
      private_constant :QUIT_HINT

      # @rbs @text: String

      #: (text: String, kind: Symbol) -> void
      def initialize(text:, kind:)
        super(kind: kind, repeat: false)
        @text = text
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return Outcome.none if @text.empty?
        Outcome.success(@text)
      end

      #: (ActionTable) -> void
      def self.register(table)
        table.register("message.quit_hint", MessageHandler.new(text: QUIT_HINT, kind: :action))
        table.register("register.select", MessageHandler.new(text: "", kind: :register))
      end
    end
  end
end
