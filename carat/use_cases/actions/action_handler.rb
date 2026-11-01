require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"

module Carat
  module UseCases
    # The input port of an action: what a key binding's action name runs.
    # A handler is registered in the ActionTable under one or more names;
    # the dispatcher finds it there and calls it with the state and the
    # command the grammar produced, and shows the Outcome it returns. kind
    # tells the command grammar how the action reads keys: :motion,
    # :find (a motion that reads a character), :operator (waits for a
    # motion), :text_object, :register (the register prefix), :char (an
    # action that reads a character), or :action (completes at once).
    # repeat says whether the action is a change the dot command repeats
    # when it changes the text or enters insert mode: operators, the
    # standalone edits, the insert commands, and the visual operators.
    class ActionHandler
      attr_reader :kind #: Symbol
      attr_reader :repeat #: bool

      #: (kind: Symbol, repeat: bool) -> void
      def initialize(kind:, repeat:)
        @kind = kind
        @repeat = repeat
      end

      # Runs the action and returns the Outcome to report.
      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        raise NotImplementedError, "ActionHandler#call"
      end
    end
  end
end
