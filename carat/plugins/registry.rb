# Generated from config/plugins.caratrc by bin/carat-gen-config.rb.
# Do not edit. Change config/plugins.caratrc and run: spin run carat-gen-config
require_relative "../plugin_api"
require_relative "explorer/plugin"
require_relative "ruby/plugin"
require_relative "finder/plugin"

module Carat
  module Plugins
    # The built-in compiled plugins in registry order, one constructor
    # call each, so the compiler sees a fixed list.
    module Registry
      NAMES = ["explorer", "ruby", "finder"]

      #: () -> Array[untyped]
      def self.all
        list = []
        list << Carat::Plugins::Explorer::Plugin.new
        list << Carat::Plugins::Ruby::Plugin.new
        list << Carat::Plugins::Finder::Plugin.new
        list
      end
    end
  end
end
