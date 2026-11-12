module Carat
  module UseCases
    # Which buffer SwitchBuffer shows: target :next or :previous goes count
    # listed file buffers forward or back, wrapping; :first and :last show
    # the first and the last listed file buffer; :number shows buffer
    # number count; :alternate shows the window's alternate buffer;
    # :current stays. bang lets a modified current buffer go hidden. A
    # Data value.
    class BufferRequest < Data.define(:target, :count, :bang)
      # @rbs @target: Symbol
      # @rbs @count: Integer
      # @rbs @bang: bool

      # The steps through the list: count forward for :next, back for
      # :previous.
      #: () -> Integer
      def steps
        target == :previous ? -count : count
      end
    end
  end
end
