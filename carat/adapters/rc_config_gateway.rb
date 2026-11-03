require_relative "../ports/config_port"
require_relative "../ports/file_port"
require_relative "../domain/config"
require_relative "../domain/default_config"

module Carat
  module Adapters
    # Loads the configuration files in order through the file port: the
    # shipped defaults the binary embeds, the user's
    # ~/.config/carat/caratrc, and the project's .caratrc in the working
    # directory, each of the last two only when a file is there. The
    # project file is not trusted to set language commands. A file that is
    # there but cannot be read is noted and skipped.
    class RcConfigGateway < Ports::ConfigPort
      # How the defaults are named in problems.
      DEFAULTS = "config/default.caratrc"

      # The user file under the home directory, and how it is named.
      USER_PATH = "/.config/carat/caratrc"
      USER = "~/.config/carat/caratrc"

      # The project file in the working directory, and how it is named.
      PROJECT = ".caratrc"

      attr_reader :files #: Ports::FilePort

      # @rbs @files: Ports::FilePort

      #: (files: Ports::FilePort) -> void
      def initialize(files:)
        @files = files
      end

      # Returns the Domain::Config of the three files.
      # @rbs skip
      def load
        config = Domain::Config.new
        config.read_defaults(DEFAULTS, Domain::DEFAULT_CARATRC)
        home = @files.home
        read_file(config, "#{home}#{USER_PATH}", USER, true) unless home.empty?
        read_file(config, "#{@files.cwd}/#{PROJECT}", PROJECT, false)
        config
      end

      private

      # Reads the file at path into the configuration under its label when
      # a file, not a directory, is there.
      #: (Domain::Config, String, String, bool) -> void
      def read_file(config, path, source, trusted)
        info = @files.stat(path)
        return unless info.exists && !info.directory
        text = ""
        begin
          text = @files.read(path)
        rescue StandardError
          config.unreadable(source)
          return
        end
        config.read(source, text, trusted)
      end
    end
  end
end
