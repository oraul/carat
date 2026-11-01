require_relative "command_grammar"

module Carat
  module Domain
    # The keys of the command being typed: the keys the keymap is still
    # waiting on to resolve a binding, and the command grammar with what
    # it has taken. HandleKey owns it; the presenter reads it for the
    # pending-keys display, and a plugin's prompt drops the waiting keys.
    # A Struct record: mutable, with a reader and a writer per member.
    class InputState < Struct.new(:pending_keys, :grammar)
      # @rbs @pending_keys: Array[Integer]
      # @rbs @grammar: CommandGrammar

      #: () -> void
      def initialize
        super()
        self.pending_keys = []
        self.grammar = CommandGrammar.new
      end

      # Whether the keymap is waiting for more keys.
      #: () -> bool
      def pending?
        !pending_keys.empty?
      end

      # The waiting keys, which are dropped from the state.
      #: () -> Array[Integer]
      def take_keys
        keys = pending_keys
        self.pending_keys = []
        keys
      end
    end
  end
end
