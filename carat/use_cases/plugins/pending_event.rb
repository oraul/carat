require_relative "../../plugin_api"

module Carat
  module UseCases
    # An event waiting in the plugin host's queue, with its cause: the
    # plugin whose request made it, which does not receive it, or "" for
    # the editor and the user. A Struct record.
    class PendingEvent < Struct.new(:event, :cause)
      # @rbs @event: PluginApi::Event
      # @rbs @cause: String

      #: (PluginApi::Event, String) -> void
      def initialize(event, cause)
        super(event, cause)
      end

      # Whether the plugin named should receive the event.
      #: (String) -> bool
      def for?(name)
        name != cause
      end
    end
  end
end
