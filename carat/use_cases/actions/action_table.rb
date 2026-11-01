require_relative "action_handler"

module Carat
  module UseCases
    # The registered action handlers, in registration order, with an index
    # from action name to position. A name is registered once; a second
    # registration is refused. One namespace handler may stand for every
    # name under a prefix that no exact entry takes, which is how the
    # plugin.<name>.<action> actions reach the plugin host.
    class ActionTable
      # @rbs @handlers: Array[untyped]
      # @rbs @index: Hash[String, Integer]
      # @rbs @names: Array[String]
      # @rbs @prefix: String
      # @rbs @namespace: ActionHandler?

      #: () -> void
      def initialize
        @handlers = []
        @index = {}
        @names = []
        @prefix = ""
        @namespace = nil
      end

      # Registers the handler under the name; false, and nothing added,
      # when the name is already registered.
      #: (String, ActionHandler) -> bool
      def register(name, handler)
        return false if @index.key?(name)
        @index[name] = @handlers.length
        @handlers << handler
        @names << name
        true
      end

      # Registers the handler for every name that starts with prefix and
      # has no entry of its own; false when a namespace is registered.
      #: (String, ActionHandler) -> bool
      def register_namespace(prefix, handler)
        return false unless @namespace.nil?
        @prefix = prefix
        @namespace = handler
        true
      end

      # The handler for the name, or nil when none is registered.
      #: (String) -> ActionHandler?
      def find(name)
        at = @index[name]
        return handler_at(at) unless at.nil?
        return @namespace if !@prefix.empty? && name.start_with?(@prefix)
        nil
      end

      # How the grammar reads the action: its handler's kind, or :action
      # for a name with no handler.
      #: (String) -> Symbol
      def kind_of(name)
        handler = find(name)
        handler.nil? ? :action : handler.kind
      end

      #: (String) -> bool
      def include?(name)
        @index.key?(name)
      end

      # The registered names, in registration order.
      #: () -> Array[String]
      def names
        @names
      end

      #: () -> Integer
      def count
        @handlers.length
      end

      #: (Integer) -> ActionHandler
      def handler_at(i)
        @handlers[i]
      end
    end
  end
end
