require_relative "ex_handler"

module Carat
  module UseCases
    # The registered ex command handlers in registration order, which is
    # the order of precedence when two accept a typed name, as in Vim's
    # command table, with an index from each full name and abbreviation
    # to its position. A handler whose full name or abbreviation is
    # already registered is refused. A handler with an empty name, the
    # plugin commands, is matched by asking it, after the named ones.
    # Each named command is registered with a short description, which
    # the command palette shows beside it, as an action is.
    class ExTable
      # @rbs @handlers: Array[untyped]
      # @rbs @index: Hash[String, Integer]
      # @rbs @names: Array[String]
      # @rbs @full_names: Array[String]
      # @rbs @descriptions: Hash[String, String]

      #: () -> void
      def initialize
        @handlers = []
        @index = {}
        @names = []
        @full_names = []
        @descriptions = {}
      end

      # Registers the handler under the name it carries, with the
      # description the palette shows for a named one; false, and nothing
      # added, when its full name or abbreviation is taken.
      #: (ExHandler, String) -> bool
      def register(handler, description)
        name = handler.name
        return false if !name.full.empty? && (@index.key?(name.full) || @index.key?(name.short))
        unless name.full.empty?
          @index[name.full] = @handlers.length
          @index[name.short] = @handlers.length
          @names << name.to_s
          @full_names << name.full
          @descriptions[name.full] = description
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

      # The full names of the named commands, in registration order.
      #: () -> Array[String]
      def full_names
        @full_names
      end

      # The description of a command by its full name, "" for none.
      #: (String) -> String
      def describe(full)
        text = @descriptions[full]
        text.nil? ? "" : text
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
