require_relative "key"
require_relative "key_notation"
require_relative "command"
require_relative "registers"

module Carat
  module Domain
    # The state machine over normal-mode keys that implements
    #
    #   [register] [count] operator [count] (motion | text-object)
    #   [register] [count] action
    #
    # It never sees a buffer and never looks keys up: HandleKey hands it
    # count digits and character arguments as keys, and every other key as
    # the action name the keymap resolved with the kind of the handler the
    # action table registered for it: :register (the register prefix,
    # which reads a register name), :operator (waits for a motion, a text
    # object, or itself), :find and :char (read one more key), :motion,
    # :text_object (only under an operator or in a visual mode), and
    # :action (completes at once). It knows no action name of its own.
    # A Struct record whose fields persist between keys.
    class CommandGrammar < Struct.new(:register, :count, :operator, :operator_count, :want, :action, :argument, :linewise, :keys, :typed)
      # @rbs @register: String
      # @rbs @count: Integer
      # @rbs @operator: String
      # @rbs @operator_count: Integer
      # @rbs @want: Symbol
      # @rbs @action: String
      # @rbs @argument: String
      # @rbs @linewise: bool
      # @rbs @keys: Array[Integer]
      # @rbs @typed: String

      #: () -> void
      def initialize
        super("", 0, "", 0, :none, "", "", false, [], "")
      end

      #: () -> void
      def reset
        self.register = ""
        self.count = 0
        self.operator = ""
        self.operator_count = 0
        self.want = :none
        self.action = ""
        self.argument = ""
        self.linewise = false
        self.keys = []
        self.typed = ""
      end

      # How a key reads in the pending-keys display.
      #: (Integer) -> String
      def self.display(code)
        Key.printable?(code) ? Key.char(code) : KeyNotation.format(code)
      end

      # Whether the next key is a register name or a character argument
      # rather than a key to look up.
      #: () -> bool
      def wants_char?
        want != :none
      end

      #: () -> bool
      def operator_pending?
        !operator.empty?
      end

      # Whether anything of a command has been typed.
      #: () -> bool
      def pending?
        !typed.empty?
      end

      # Whether code continues or starts a count: 1 to 9 always, 0 only
      # inside a count so that "0" alone stays a motion.
      #: (Integer) -> bool
      def digit?(code)
        (code >= 49 && code <= 57) || (code == 48 && count > 0)
      end

      #: (Integer) -> void
      def digit(code)
        self.count = count * 10 + (code - 48)
        remember([code])
      end

      # Takes the key a register prefix or a find motion was waiting for.
      # Returns :pending (a register was chosen), :complete (the motion has
      # its character), or :cancel (not a usable key).
      #: (Integer) -> Symbol
      def char(code)
        unless Key.printable?(code)
          reset
          return :cancel
        end
        text = Key.char(code)
        remember([code])
        if want == :register
          unless Registers.valid_name?(text)
            reset
            return :cancel
          end
          self.register = text
          self.want = :none
          :pending
        else
          self.argument = text
          self.want = :none
          :complete
        end
      end

      # Takes the action the keymap resolved for codes, with its kind.
      # Returns :pending (more keys wanted), :operator (an operator is now
      # pending), :complete (take the command), or :cancel (reset, nothing
      # to do).
      #: (String, Symbol, Array[Integer]) -> Symbol
      def accept(action, kind, codes)
        if wants_char?
          reset
          return :cancel
        end
        remember(codes)
        if operator.empty?
          accept_in_normal(action, kind)
        else
          accept_in_pending(action, kind)
        end
      end

      # Takes the action the keymap resolved in a visual mode, where an
      # operator acts on the selection at once instead of waiting for a
      # motion: a register prefix and the actions that want a character
      # (the find motions and "r") return :pending, every other action
      # :complete, and a key arriving while a character was wanted :cancel.
      #: (String, Symbol, Array[Integer]) -> Symbol
      def accept_visual(action, kind, codes)
        if wants_char?
          reset
          return :cancel
        end
        remember(codes)
        if kind == :register
          self.want = :register
          return :pending
        end
        self.action = action
        if kind == :find || kind == :char
          self.want = :char
          return :pending
        end
        :complete
      end

      # The finished command; the grammar is reset for the next one.
      #: () -> Command
      def take
        total = count
        if operator_count > 0
          total = count > 0 ? operator_count * count : operator_count
        end
        command = Command.new(register, total, operator, action, argument, linewise, keys)
        reset
        command
      end

      private

      #: (Array[Integer]) -> void
      def remember(codes)
        text = typed
        i = 0
        while i < codes.length
          keys << codes[i]
          text = text + CommandGrammar.display(codes[i])
          i += 1
        end
        self.typed = text
      end

      #: (String, Symbol) -> Symbol
      def accept_in_normal(action, kind)
        if kind == :register
          self.want = :register
          :pending
        elsif kind == :operator
          self.operator = action
          self.operator_count = count
          self.count = 0
          :operator
        elsif kind == :find || kind == :char
          self.action = action
          self.want = :char
          :pending
        elsif kind == :text_object
          reset
          :cancel
        else
          self.action = action
          :complete
        end
      end

      #: (String, Symbol) -> Symbol
      def accept_in_pending(action, kind)
        if action == operator
          self.linewise = true
          :complete
        elsif kind == :find
          self.action = action
          self.want = :char
          :pending
        elsif kind == :motion || kind == :text_object
          self.action = action
          :complete
        else
          reset
          :cancel
        end
      end
    end
  end
end
