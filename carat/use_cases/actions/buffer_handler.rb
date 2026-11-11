require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../buffers/list_buffers"
require_relative "../buffers/switch_buffer"
require_relative "../buffers/buffer_request"
require_relative "../buffers/delete_buffer"
require_relative "../outcome"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The buffer actions the leader's buffer group binds: list the buffers
    # as :ls does, go to the next or previous listed buffer as :bn and :bp
    # do, a count stepping that many, and delete the current buffer as :bd
    # does, or with a count the buffer of that number as :bd N does, and
    # show the window's alternate buffer as Ctrl-^ does, or with a count
    # the buffer of that number,
    # through the use cases the ex commands run, so the messages and
    # refusals are theirs.
    class BufferHandler < ActionHandler
      # @rbs @list_buffers: ListBuffers
      # @rbs @switch_buffer: SwitchBuffer
      # @rbs @delete_buffer: DeleteBuffer
      # @rbs @variant: Symbol

      #: (list_buffers: ListBuffers, switch_buffer: SwitchBuffer, delete_buffer: DeleteBuffer, variant: Symbol) -> void
      def initialize(list_buffers:, switch_buffer:, delete_buffer:, variant:)
        super(kind: :action, repeat: false)
        @list_buffers = list_buffers
        @switch_buffer = switch_buffer
        @delete_buffer = delete_buffer
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        count = command.count
        case @variant
        when :list then @list_buffers.call(state, "", false)
        when :delete then @delete_buffer.call(state, count, false, count == 0 ? "bdelete" : "bdelete #{count}")
        when :alternate then @switch_buffer.call(state, BufferRequest.new(target: count == 0 ? :alternate : :number, count: count, bang: false))
        else @switch_buffer.call(state, BufferRequest.new(target: @variant, count: count == 0 ? 1 : count, bang: false))
        end
      end

      #: (ActionTable, list_buffers: ListBuffers, switch_buffer: SwitchBuffer, delete_buffer: DeleteBuffer) -> void
      def self.register(table, list_buffers:, switch_buffer:, delete_buffer:)
        names = ["buffer.list", "buffer.next", "buffer.previous", "buffer.delete", "buffer.alternate"]
        variants = [:list, :next, :previous, :delete, :alternate]
        descriptions = ["List buffers", "Next buffer", "Previous buffer", "Delete buffer", "Alternate buffer"]
        i = 0
        while i < names.length
          table.register(names[i], BufferHandler.new(list_buffers: list_buffers, switch_buffer: switch_buffer, delete_buffer: delete_buffer, variant: variants[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
