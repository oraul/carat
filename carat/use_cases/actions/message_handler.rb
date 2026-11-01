require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # An action that only answers a message: the quit hint on <C-c>, the
    # register prefix (which the grammar consumes, so it is never run),
    # and the actions config/default.json binds but a later roadmap item
    # implements, which answer "Not implemented: name".
    class MessageHandler < ActionHandler
      QUIT_HINT = "Type  :q!  and press <Enter> to abandon all changes and exit Carat"

      # The reserved actions, listed under Reserved in docs/actions.md.
      RESERVED = ["history.undo", "history.redo", "history.repeat", "search.forward", "search.backward", "search.next", "search.previous"]

      # @rbs @text: String

      #: (text: String, kind: Symbol) -> void
      def initialize(text:, kind:)
        super(kind: kind)
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
        i = 0
        while i < RESERVED.length
          name = RESERVED[i]
          table.register(name, MessageHandler.new(text: "Not implemented: #{name}", kind: :action))
          i += 1
        end
      end
    end
  end
end
