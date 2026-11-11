require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"
require_relative "buffer_request"

module Carat
  module UseCases
    # :bn, :bp, :bN, :bfirst, :blast, :b N, and Ctrl-^, the window's
    # alternate buffer (E23 without one): shows another listed file
    # buffer in the current window, as the request says, with the cursor
    # where a window last left it, the position left joining the window's
    # jump list. The buffer the window showed stays listed, hidden. A
    # modified current file buffer refuses the switch with E37 unless the
    # request carries the bang, as :e does; a number of no listed file
    # buffer is E86 and a list without file buffers E85, as Neovim's
    # do_buffer answers.
    class SwitchBuffer
      E85 = "E85: There is no listed buffer"
      E23 = "E23: No alternate file"
      private_constant :E85, :E23

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, BufferRequest) -> Outcome
      def call(state, request)
        return Outcome.none if request.target == :current
        current = state.buffer
        if request.target == :number
          found = @buffers.with_id(request.count)
          return Outcome.failure("E86: Buffer #{request.count} does not exist") if found.nil? || found.scratch?
        elsif request.target == :alternate
          found = @buffers.alternate_of(state.window)
          return Outcome.failure(E23) if found.nil?
        elsif request.target == :first || request.target == :last
          found = request.target == :first ? @buffers.first_file : @buffers.last_file
          return Outcome.failure(E85) if found.nil?
        else
          found = @buffers.step_from(current, request.steps)
          return Outcome.failure(E85) if found.nil?
        end
        return Outcome.none if found.equal?(current)
        return Outcome.failure(Domain::Messages::E37) if current.modified? && !current.scratch? && !request.bang
        @buffers.enter(found)
        Outcome.none
      end
    end
  end
end
