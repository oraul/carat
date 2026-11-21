require_relative "../ports/config_port"
require_relative "../domain/config"
require_relative "../domain/default_config"

module Carat
  module Doubles
    # A config port that returns a configuration given to it. defaults
    # reads the shipped defaults as the editor does; with reads lines a
    # test gives after them, as the project file .caratrc, and with_user as
    # the user file, so a test sets options and bindings with the lines a
    # user would write. The test configuration keeps option.showtabline 1,
    # the tab row's rule before the option, so a test with one file in one
    # tab page sees no tab row; shipped is the defaults alone.
    class FixedConfig < Ports::ConfigPort
      # @rbs @value: Domain::Config

      #: (value: Domain::Config) -> void
      def initialize(value:)
        @value = value
      end

      # The shipped defaults alone, a new configuration on every call.
      #: () -> Domain::Config
      def self.shipped
        config = Domain::Config.new
        config.read_defaults("config/default.caratrc", Domain::DEFAULT_CARATRC)
        config
      end

      # The shipped defaults with option.showtabline 1, the test
      # configuration, a new configuration on every call.
      #: () -> Domain::Config
      def self.defaults
        config = shipped
        config.read_defaults("test showtabline", "option.showtabline 1\n")
        config
      end

      # The shipped defaults, then text as the project file .caratrc.
      #: (String) -> Domain::Config
      def self.with(text)
        config = defaults
        config.read(".caratrc", text, false)
        config
      end

      # The shipped defaults, then text as the user file
      # ~/.config/carat/caratrc, which is trusted with key sequences.
      #: (String) -> Domain::Config
      def self.with_user(text)
        config = defaults
        config.read("~/.config/carat/caratrc", text, true)
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
