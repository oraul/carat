require_relative "../domain/config"

module Carat
  module Ports
    # Loads the configuration: the setting lines of every configuration
    # file in load order, as a Domain::Config whose lines carry the file
    # and line number their problems are reported with. A setting the
    # files leave out falls back to Vim's default in the domain; the
    # shipped config/default.caratrc gives Carat's.
    class ConfigPort
      # Returns the Domain::Config.
      # @rbs skip
      def load
        raise NotImplementedError, "ConfigPort#load"
      end
    end
  end
end
