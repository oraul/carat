require_relative "../../domain/editor_state"
require_relative "../buffers/list_buffers"
require_relative "../buffers/switch_buffer"
require_relative "../buffers/buffer_request"
require_relative "../buffers/delete_buffer"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The ex commands of the buffer list: :ls, :buffers, and :files with
    # their flag argument and bang; :bn, :bp, and :bN with a count
    # argument (E488 for another); :b N and :bd N with a buffer number,
    # the current buffer without one, and "Not implemented" for a name.
    class BufferCommandHandler < ExHandler
      LARGEST = 999_999_999
      private_constant :LARGEST

      # @rbs @list_buffers: ListBuffers
      # @rbs @switch_buffer: SwitchBuffer
      # @rbs @delete_buffer: DeleteBuffer
      # @rbs @variant: Symbol

      #: (spec: String, list_buffers: ListBuffers, switch_buffer: SwitchBuffer, delete_buffer: DeleteBuffer, variant: Symbol) -> void
      def initialize(spec:, list_buffers:, switch_buffer:, delete_buffer:, variant:)
        super(spec: spec)
        @list_buffers = list_buffers
        @switch_buffer = switch_buffer
        @delete_buffer = delete_buffer
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        args = command.args
        case @variant
        when :list then @list_buffers.call(state, args, command.bang)
        when :number then number(state, command)
        when :delete then delete(state, command)
        else step(state, command)
        end
      end

      # Registers the buffer list commands in the order of
      # docs/compatibility.md; none shares an abbreviation with another
      # command.
      #: (ExTable, list_buffers: ListBuffers, switch_buffer: SwitchBuffer, delete_buffer: DeleteBuffer) -> void
      def self.register(table, list_buffers:, switch_buffer:, delete_buffer:)
        specs = ["ls", "buffers", "files", "b[uffer]", "bn[ext]", "bp[revious]", "bN[ext]", "bd[elete]"]
        variants = [:list, :list, :list, :number, :next, :previous, :previous, :delete]
        i = 0
        while i < specs.length
          table.register(BufferCommandHandler.new(spec: specs[i], list_buffers: list_buffers, switch_buffer: switch_buffer, delete_buffer: delete_buffer, variant: variants[i]))
          i += 1
        end
      end

      private

      # :b N, or :b alone, which stays.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def number(state, command)
        args = command.args
        return @switch_buffer.call(state, BufferRequest.new(target: :current, count: 0, bang: command.bang)) if args.empty?
        return Outcome.failure("Not implemented: :buffer #{args}") unless digits?(args)
        @switch_buffer.call(state, BufferRequest.new(target: :number, count: number_in(args), bang: command.bang))
      end

      # :bn, :bp, and :bN, one buffer without a count.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def step(state, command)
        args = command.args
        return Outcome.failure("E488: Trailing characters: #{args}") unless args.empty? || digits?(args)
        count = args.empty? ? 1 : number_in(args)
        @switch_buffer.call(state, BufferRequest.new(target: @variant, count: count, bang: command.bang))
      end

      # :bd N, or the current buffer without a number.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def delete(state, command)
        args = command.args
        return Outcome.failure("Not implemented: :bdelete #{args}") unless args.empty? || digits?(args)
        typed = command.name + (command.bang ? "!" : "") + (args.empty? ? "" : " " + args)
        @delete_buffer.call(state, args.empty? ? 0 : number_in(args), command.bang, typed)
      end

      # The number the digits spell, held to LARGEST, which no buffer
      # number reaches, so a long run of digits stays an Integer.
      #: (String) -> Integer
      def number_in(text)
        text.bytesize > 9 ? LARGEST : text.to_i
      end

      # Whether the text is a run of ASCII digits.
      #: (String) -> bool
      def digits?(text)
        return false if text.empty?
        i = 0
        while i < text.bytesize
          code = text.getbyte(i).to_i
          return false if code < 48 || code > 57
          i += 1
        end
        true
      end
    end
  end
end
