require_relative "config"

module Carat
  module Domain
    # Renders carat/plugins/registry.rb from the lines of
    # config/plugins.caratrc, "plugin.<name> <path> <class>", one per
    # plugin in order: one explicit require and one constructor call per
    # plugin, so the compiler sees a fixed list with no reflection. The
    # generator writes the text and the config_sync test renders it again
    # to compare, which is why it lives here rather than in the generator,
    # a compile root a test cannot require.
    module RegistrySource
      # The keyword is assembled from two pieces so the compiler's require
      # scanner, which reads the text of every file for it, does not take
      # the rendered line for a require of this file.
      KEYWORD = "require_" + "relative"

      # Whether a line of the list names a plugin: key plugin.<name> with
      # a single name segment, and exactly a path and a class.
      #: (RcLine) -> bool
      def self.entry?(line)
        line.scope == "plugin" && !line.name.include?(".") && line.words.length == 2
      end

      # The word at index of every plugin line: 0 the path, 1 the class.
      #: (Config, Integer) -> Array[String]
      def self.column(config, index)
        out = []
        i = 0
        while i < config.count
          line = config.line_at(i)
          out << line.words[index].to_s if entry?(line)
          i += 1
        end
        out
      end

      # The plugin names in order.
      #: (Config) -> Array[String]
      def self.names(config)
        out = []
        i = 0
        while i < config.count
          line = config.line_at(i)
          out << line.name if entry?(line)
          i += 1
        end
        out
      end

      #: (Config) -> String
      def self.render(config)
        paths = column(config, 0)
        classes = column(config, 1)
        out = +""
        out << "# Generated from config/plugins.caratrc by bin/carat-gen-config.rb.\n"
        out << "# Do not edit. Change config/plugins.caratrc and run: spin run carat-gen-config\n"
        out << KEYWORD << " \"../plugin_api\"\n"
        paths.each { |path| out << KEYWORD << " \"#{path}\"\n" }
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
        classes.each { |name| out << "        list << #{name}.new\n" }
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
