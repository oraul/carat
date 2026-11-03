require_relative "../ports/config_port"
require_relative "../domain/config"
require_relative "../domain/default_config"

module Carat
  module Doubles
    # A config port that returns a configuration given to it. defaults
    # reads the shipped defaults as the editor does; with reads lines a
    # test gives after them, as the project file .caratrc, so a test sets
    # options and bindings with the lines a user would write.
    class FixedConfig < Ports::ConfigPort
      # @rbs @value: Domain::Config

      #: (value: Domain::Config) -> void
      def initialize(value:)
        @value = value
      end

      # The shipped defaults, a new configuration on every call.
      #: () -> Domain::Config
      def self.defaults
        config = Domain::Config.new
        config.read_defaults("config/default.caratrc", Domain::DEFAULT_CARATRC)
        config
      end

      # The shipped defaults, then text as the project file .caratrc.
      #: (String) -> Domain::Config
      def self.with(text)
        config = defaults
        config.read(".caratrc", text, false)
        config
      end

      # Returns the configuration it was given.
      # @rbs skip
      def load
        @value
      end
    end
  end
end
