require_relative "key"
require_relative "key_notation"
require_relative "command"
require_relative "registers"
require_relative "operator_kind"

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
    # :text_object (only under an operator or in a visual mode), :search
    # (reads a pattern on the command line: the grammar answers :prompt,
    # keeps what it has, and takes the pattern through pattern), and
    # :action (completes at once). It knows no action name of its own but
    # LAST_KEY_DOUBLED: the operators whose last key typed again is their
    # doubled form (gcc), since their whole keys typed again in
    # operator_pending name a text object (gc).
    # operator_key is the last key of a pending operator of more than one
    # key, 0 for none.
    # A Struct record whose fields persist between keys.
    class CommandGrammar < Struct.new(:register, :count, :operator, :operator_count, :want, :action, :argument, :linewise, :keys, :typed, :operator_key, keyword_init: true)
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
      # @rbs @operator_key: Integer

      # The operators whose doubled form is their last key typed again.
      LAST_KEY_DOUBLED = [OperatorKind::COMMENT]

      #: () -> void
      def initialize
        super(register: "", count: 0, operator: "", operator_count: 0, want: :none, action: "", argument: "", linewise: false, keys: [], typed: "", operator_key: 0)
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
        self.operator_key = 0
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
        want == :register || want == :char
      end

      # Whether the command waits for a pattern typed on the command line.
      #: () -> bool
      def wants_pattern?
        want == :pattern
      end

      # Takes the pattern a search action was waiting for and finishes
      # the command with it as the argument.
      #: (String) -> Command
      def pattern(text)
        self.argument = text
        self.want = :none
        take
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
      # pending), :prompt (a pattern is wanted on the command line),
      # :complete (take the command), or :cancel (reset, nothing to do).
      #: (String, Symbol, Array[Integer]) -> Symbol
      def accept(action, kind, codes)
        if want != :none
          reset
          return :cancel
        end
        remember(codes)
        if kind == :search
          self.action = action
          self.want = :pattern
          return :prompt
        end
        if operator.empty?
          result = accept_in_normal(action, kind)
          self.operator_key = codes.length > 1 ? codes[codes.length - 1] : 0 if result == :operator
          result
        else
          accept_in_pending(action, kind, codes)
        end
      end

      # Takes the action the keymap resolved in a visual mode, where an
      # operator acts on the selection at once instead of waiting for a
      # motion: a register prefix and the actions that want a character
      # (the find motions and "r") return :pending, a search :prompt,
      # every other action :complete, and a key arriving while a
      # character was wanted :cancel.
      #: (String, Symbol, Array[Integer]) -> Symbol
      def accept_visual(action, kind, codes)
        if want != :none
          reset
          return :cancel
        end
        remember(codes)
        if kind == :search
          self.action = action
          self.want = :pattern
          return :prompt
        end
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
        command = Command.new(register: register, count: total, operator: operator, action: action, char: argument, linewise: linewise, keys: keys)
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

      #: (String, Symbol, Array[Integer]) -> Symbol
      def accept_in_pending(action, kind, codes)
        if action == operator || last_key_doubled?(codes)
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

      # Whether codes are the one last key of a pending operator of
      # LAST_KEY_DOUBLED, as the second c of gcc.
      #: (Array[Integer]) -> bool
      def last_key_doubled?(codes)
        operator_key != 0 && codes.length == 1 && codes[0] == operator_key && LAST_KEY_DOUBLED.include?(operator)
      end
    end
  end
end
