require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"
require_relative "buffer_request"

module Carat
  module UseCases
    # :bn, :bp, :bN, :bfirst, :blast, :b N, Ctrl-^, the window's
    # alternate buffer (E23 without one), and {count}gt, the count-th
    # buffer tab (nothing when the row has fewer): shows another listed file
    # buffer in the current window, as the request says, with the cursor
    # where a window last left it, the position left joining the window's
    # jump list. The buffer the window showed stays listed, hidden. With
    # option.hidden off a modified current file buffer refuses the switch
    # with E37 unless the request carries the bang, as :e does; with it on,
    # the default, the buffer is left hidden with its changes. A number
    # of no listed file buffer is E86 and a list without file buffers E85, as Neovim's
    # do_buffer answers. Run with the focus in a side window, a slot's
    # window such as the explorer (TabPage#side_window?), the switch acts
    # on the tab page's editing window (TabPage#editing_leaf), focused
    # first and left focused unless the switch fails, which puts the tab
    # page's current and previous windows back as they were; with no file
    # window it fails. Any other window, a reading view included, is
    # switched itself.
    class SwitchBuffer
      E85 = "E85: There is no listed buffer"
      E23 = "E23: No alternate file"
      NO_FILE_WINDOW = "No file window to show the buffer in"
      private_constant :E85, :E23, :NO_FILE_WINDOW

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, BufferRequest) -> Outcome
      def call(state, request)
        return Outcome.none if request.target == :current
        tab = state.tab
        return switch(state, request) if tab.floats.focused? || !tab.side_window?(tab.current)
        leaf = tab.editing_leaf
        return Outcome.failure(NO_FILE_WINDOW) if leaf < 0
        side = tab.current
        before = tab.previous
        tab.focus(leaf)
        outcome = switch(state, request)
        unless outcome.ok
          tab.current = side
          tab.previous = before
        end
        outcome
      end

      private

      # Shows the buffer the request names in the current window.
      #: (Domain::EditorState, BufferRequest) -> Outcome
      def switch(state, request)
        current = state.buffer
        if request.target == :number
          found = @buffers.with_id(request.count)
          return Outcome.failure("E86: Buffer #{request.count} does not exist") if found.nil? || found.scratch?
        elsif request.target == :alternate
          found = @buffers.alternate_of(state.window)
          return Outcome.failure(E23) if found.nil?
        elsif request.target == :tab
          found = @buffers.file_at(request.count)
          return Outcome.none if found.nil?
        elsif request.target == :first || request.target == :last
          found = request.target == :first ? @buffers.first_file : @buffers.last_file
          return Outcome.failure(E85) if found.nil?
        else
          found = @buffers.step_from(current, request.steps)
          return Outcome.failure(E85) if found.nil?
        end
        return Outcome.none if found.equal?(current)
        return Outcome.failure(Domain::Messages::E37) if current.modified? && !current.scratch? && !request.bang && !state.options.hidden
        @buffers.enter(found)
        Outcome.none
      end
    end
  end
end
