module Carat
  module Domain
    # The runs of characters of one class on a line, as parallel arrays of
    # start column (inclusive), end column (exclusive), and class, because
    # Spinel pins Array[Integer] but not an array of program values. A
    # Struct record built by TextObjects.runs.
    class Runs < Struct.new(:froms, :tos, :classes)
      # @rbs @froms: Array[Integer]
      # @rbs @tos: Array[Integer]
      # @rbs @classes: Array[Integer]

      #: () -> void
      def initialize
        super([], [], [])
      end

      #: (Integer, Integer, Integer) -> void
      def add(from, to, cls)
        froms << from
        tos << to
        classes << cls
      end

      #: () -> Integer
      def length
        froms.length
      end

      #: (Integer) -> Integer
      def from(i)
        froms[i]
      end

      #: (Integer) -> Integer
      def to(i)
        tos[i]
      end

      #: (Integer) -> Integer
      def class_at(i)
        classes[i]
      end

      # The index of the run holding col, or the last run.
      #: (Integer) -> Integer
      def index_of(col)
        i = 0
        while i < froms.length
          return i if col >= froms[i] && col < tos[i]
          i += 1
        end
        froms.length - 1
      end
    end
  end
end
