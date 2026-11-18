require_relative "../../domain/editor_state"
require_relative "../../domain/key"
require_relative "../../domain/mode"
require_relative "../outcome"
require_relative "../handle_key"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]norm[al][!] {commands}: runs the characters of the argument,
    # read literally, as keys typed in normal mode through HandleKey, as
    # Neovim's ex_normal does: once at the cursor without a range, once on
    # each line of a range with the cursor on column 0 of the line, until
    # the buffer's last line. A command the keys leave unfinished ends as
    # if the typeahead ran out: a pending keymap prefix times out, then Esc
    # is fed while the mode is not normal or the grammar holds part of a
    # command, so an insert is left and a command line is not run. The
    # keys are one undo step with the command: they run with the state's
    # normal_depth raised, so the dispatcher and LeaveInsert join the
    # transaction open here (or the caller's) instead of closing it. A
    # bang runs the same keys, every Carat key being a keymap binding.
    # E471 without an argument, E192 past MAX_DEPTH nested commands.
    class NormalCommandHandler < LineCommandHandler
      MAX_DEPTH = 100
      ARGUMENT_REQUIRED = "E471: Argument required"
      TOO_DEEP = "E192: Recursive use of :normal too deep"
      # Escapes fed at most to end an unfinished command: an operator
      # pending in visual mode needs two.
      MAX_ESCAPES = 3
      private_constant :MAX_DEPTH, :ARGUMENT_REQUIRED, :TOO_DEEP, :MAX_ESCAPES

      attr_reader :handle_key #: HandleKey

      #: (spec: String, handle_key: HandleKey) -> void
      def initialize(spec:, handle_key:)
        super(spec: spec)
        @handle_key = handle_key
      end

      # True: the bang is accepted and changes nothing.
      # @rbs skip
      def bang?
        true
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        return Outcome.failure(ARGUMENT_REQUIRED) if command.args.empty?
        return Outcome.failure(TOO_DEEP) if state.normal_depth >= MAX_DEPTH
        codes = codes_of(command.args)
        buffer = state.buffer
        opened = buffer.begin_transaction(state.cursor.position)
        # No begin and ensure: Spinel's exception frames are 64 in all, and
        # each nested :normal would hold one.
        state.normal_depth += 1
        if lines.given
          row = lines.first
          while row <= lines.last && row < buffer.line_count && state.buffer.equal?(buffer)
            state.cursor.move_to(row, 0)
            run(state, codes)
            row += 1
          end
        else
          run(state, codes)
        end
        state.normal_depth -= 1
        buffer.commit_transaction(state.cursor.position) if opened
        Outcome.none
      end

      # Registers :normal after :> and :<, in the order of
      # docs/compatibility.md, which is its precedence; no core command
      # shares its abbreviation.
      #: (ExTable, handle_key: HandleKey) -> void
      def self.register(table, handle_key:)
        table.register(NormalCommandHandler.new(spec: "norm[al]", handle_key: handle_key), "Run normal mode keys")
      end

      private

      # The key code of each character of text, read literally.
      #: (String) -> Array[Integer]
      def codes_of(text)
        codes = Array.new(0, 0)
        text.each_char { |ch| codes << ch.ord }
        codes
      end

      # Feeds the keys, then ends what they left unfinished.
      #: (Domain::EditorState, Array[Integer]) -> void
      def run(state, codes)
        keys = @handle_key
        i = 0
        while i < codes.length
          keys.call(state, codes[i].to_i)
          i += 1
        end
        input = keys.input
        keys.call(state, Domain::Key::TIMEOUT) if input.pending?
        escapes = 0
        while escapes < MAX_ESCAPES && (state.mode != Domain::Mode::NORMAL || input.pending? || input.grammar.pending?)
          keys.call(state, Domain::Key::ESC)
          escapes += 1
        end
      end
    end
  end
end
