# Generated from config/plugins.json by bin/carat-gen-config.rb.
# Do not edit. Change config/plugins.json and run: spin run carat-gen-config
require_relative "../plugin_api"
require_relative "hello/plugin"

module Carat
  module Plugins
    # The built-in compiled plugins in registry order, one constructor
    # call each, so the compiler sees a fixed list.
    module Registry
      NAMES = ["hello"]

      #: () -> Array[untyped]
      def self.all
        list = []
        list << Carat::Plugins::Hello::Plugin.new
        list
      end
    end
  end
end
