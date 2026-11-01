require_relative "ex_handler"

module Carat
  module UseCases
    # The registered ex command handlers in registration order, which is
    # the order of precedence when two accept a typed name, as in Vim's
    # command table, with an index from each full name and abbreviation
    # to its position. A handler whose full name or abbreviation is
    # already registered is refused. A handler with an empty name, the
    # plugin commands, is matched by asking it, after the named ones.
    class ExTable
      # @rbs @handlers: Array[untyped]
      # @rbs @index: Hash[String, Integer]
      # @rbs @names: Array[String]

      #: () -> void
      def initialize
        @handlers = []
        @index = {}
        @names = []
      end

      # Registers the handler under the name it carries; false, and
      # nothing added, when its full name or abbreviation is taken.
      #: (ExHandler) -> bool
      def register(handler)
        name = handler.name
        return false if !name.full.empty? && (@index.key?(name.full) || @index.key?(name.short))
        unless name.full.empty?
          @index[name.full] = @handlers.length
          @index[name.short] = @handlers.length
          @names << name.to_s
        end
        @handlers << handler
        true
      end

      # The first handler, in registration order, that the typed name
      # names, or nil.
      #: (String) -> ExHandler?
      def find(typed)
        return nil if typed.empty?
        i = 0
        while i < @handlers.length
          handler = handler_at(i)
          return handler if handler.matches?(typed)
          i += 1
        end
        nil
      end

      # The registered names in Vim's notation, in registration order.
      #: () -> Array[String]
      def names
        @names
      end

      #: () -> Integer
      def count
        @handlers.length
      end

      #: (Integer) -> ExHandler
      def handler_at(i)
        @handlers[i]
      end
    end
  end
end
