module Carat
  module Domain
    # Renders carat/plugins/registry.rb from the parsed config/plugins.json:
    # one explicit require and one constructor call per plugin, in order,
    # so the compiler sees a fixed list with no reflection. The generator
    # writes the text and the config_sync test renders it again to compare,
    # which is why it lives here rather than in the generator, a compile
    # root a test cannot require.
    module RegistrySource
      # The keyword is assembled from two pieces so the compiler's require
      # scanner, which reads the text of every file for it, does not take
      # the rendered line for a require of this file.
      KEYWORD = "require_" + "relative"

      # The plugin entries of the config: each a hash with "name",
      # "path" (relative to carat/plugins/), and "class".
      #: (untyped) -> Array[untyped]
      def self.entries(config)
        out = []
        return out unless config.is_a?(Hash)
        list = config["plugins"]
        return out unless list.is_a?(Array)
        list.each do |entry|
          out << entry if entry.is_a?(Hash) && entry["name"].is_a?(String) && entry["path"].is_a?(String) && entry["class"].is_a?(String)
        end
        out
      end

      #: (untyped) -> Array[String]
      def self.names(config)
        out = []
        entries(config).each { |entry| out << entry["name"].to_s }
        out
      end

      #: (untyped) -> String
      def self.render(config)
        list = entries(config)
        out = +""
        out << "# Generated from config/plugins.json by bin/carat-gen-config.rb.\n"
        out << "# Do not edit. Change config/plugins.json and run: spin run carat-gen-config\n"
        out << KEYWORD << " \"../plugin_api\"\n"
        list.each { |entry| out << KEYWORD << " \"#{entry["path"]}\"\n" }
        out << "\n"
        out << "module Carat\n"
        out << "  module Plugins\n"
        out << "    # The built-in compiled plugins in registry order, one constructor\n"
        out << "    # call each, so the compiler sees a fixed list.\n"
        out << "    module Registry\n"
        out << "      NAMES = #{names(config).inspect}\n"
        out << "\n"
        out << "      #: () -> Array[untyped]\n"
        out << "      def self.all\n"
        out << "        list = []\n"
        list.each { |entry| out << "        list << #{entry["class"]}.new\n" }
        out << "        list\n"
        out << "      end\n"
        out << "    end\n"
        out << "  end\n"
        out << "end\n"
        out
      end
    end
  end
end
