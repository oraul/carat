module Carat
  module Ports
    # Loads the configuration as the plain value Carat::Json produces.
    class ConfigPort
      # Returns the parsed configuration value.
      # @rbs skip
      def load
        raise NotImplementedError, "ConfigPort#load"
      end
    end
  end
end
