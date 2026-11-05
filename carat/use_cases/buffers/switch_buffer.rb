require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"
require_relative "buffer_request"

module Carat
  module UseCases
    # :bn, :bp, :bN, and :b N: shows another listed file buffer in the
    # current window, as the request says, with the cursor where a window
    # last left it. The buffer the window showed stays listed, hidden. A
    # modified current file buffer refuses the switch with E37 unless the
    # request carries the bang, as :e does; a number of no listed file
    # buffer is E86 and a list without file buffers E85, as Neovim's
    # do_buffer answers.
    class SwitchBuffer
      E85 = "E85: There is no listed buffer"
      private_constant :E85

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
        else
          found = @buffers.step_from(current, request.steps)
          return Outcome.failure(E85) if found.nil?
        end
        return Outcome.none if found.equal?(current)
        return Outcome.failure(Domain::Messages::E37) if current.modified? && !current.scratch? && !request.bang
        @buffers.load(found)
        Outcome.none
      end
    end
  end
end
