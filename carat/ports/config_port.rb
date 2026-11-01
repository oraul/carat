module Carat
  module Ports
    # Loads the configuration as the plain value Carat::Json produces,
    # with the name of the file it comes from for configuration problems.
    # A value the loaded files leave out falls back to Vim's default in the
    # domain; the shipped config/default.json gives Carat's.
    class ConfigPort
      # Returns the parsed configuration value.
      # @rbs skip
      def load
        raise NotImplementedError, "ConfigPort#load"
      end

      # Returns the file name configuration problems are reported with.
      # @rbs skip
      def source
        raise NotImplementedError, "ConfigPort#source"
      end
    end
  end
end
