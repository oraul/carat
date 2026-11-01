require_relative "../ports/config_port"
require_relative "../domain/json"
require_relative "../domain/default_config"

module Carat
  module Doubles
    # A config port that returns a value given to it. The default value is
    # a fresh parse of the shipped defaults, which a test may modify before
    # building the editor.
    class FixedConfig < Ports::ConfigPort
      # The file the value stands for, in configuration problems.
      SOURCE = "config/default.json"

      # @rbs @value: untyped

      #: (value: untyped) -> void
      def initialize(value:)
        @value = value
      end

      # Returns the parsed defaults, a new value on every call.
      # @rbs skip
      def self.defaults
        Carat::Json.parse(Domain::DEFAULT_CONFIG_JSON)
      end

      # Returns the value it was given.
      # @rbs skip
      def load
        @value
      end
    end
  end
end
