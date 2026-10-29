# Generated from config/plugins.json by bin/carat-gen-config.rb.
# Do not edit. Change config/plugins.json and run: spin run carat-gen-config
require_relative "../plugin_api"
require_relative "explorer/plugin"

module Carat
  module Plugins
    # The built-in compiled plugins in registry order, one constructor
    # call each, so the compiler sees a fixed list.
    module Registry
      NAMES = ["explorer"]

      #: () -> Array[untyped]
      def self.all
        list = []
        list << Carat::Plugins::Explorer::Plugin.new
        list
      end
    end
  end
end
