require_relative "../ports/config_port"
require_relative "../domain/json"
require_relative "../domain/default_config"

module Carat
  module Adapters
    # Loads the configuration. This change loads the embedded defaults; the
    # user and project files are merged in by the options change.
    class JsonConfigGateway < Ports::ConfigPort
      # Returns the parsed default configuration.
      # @rbs skip
      def load
        Carat::Json.parse(Domain::DEFAULT_CONFIG_JSON)
      end
    end
  end
end
