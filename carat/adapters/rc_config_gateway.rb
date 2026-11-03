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
    # there but is not a regular file of at most LIMIT bytes, a project
    # file that is a symbolic link, or one whose read fails is noted and
    # skipped; a directory is skipped silently.
    class RcConfigGateway < Ports::ConfigPort
      # How the defaults are named in problems.
      DEFAULTS = "config/default.caratrc"

      # The user file under the home directory, and how it is named.
      USER_PATH = "/.config/carat/caratrc"
      USER = "~/.config/carat/caratrc"

      # The project file in the working directory, and how it is named.
      PROJECT = ".caratrc"

      # The most bytes a configuration file may hold; a longer one is not
      # read, so a hostile file cannot exhaust memory at startup.
      LIMIT = 1_048_576

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
      # a file, not a directory, is there, or notes why it was refused. An
      # untrusted file may not be a link, which could lead anywhere; the
      # user file may, as dotfile managers link it.
      #: (Domain::Config, String, String, bool) -> void
      def read_file(config, path, source, trusted)
        info = @files.stat(path)
        return unless info.exists && !info.directory
        problem = refusal(info, trusted)
        unless problem.empty?
          config.refuse(source, problem)
          return
        end
        text = ""
        begin
          text = @files.read(path, LIMIT)
        rescue StandardError
          config.refuse(source, "cannot be read")
          return
        end
        config.read(source, text, trusted)
      end

      # Why a file that is there is not read, "" when it may be.
      #: (Domain::PathInfo, bool) -> String
      def refusal(info, trusted)
        return "is a symbolic link, not read" if info.symlink && !trusted
        return "is not a regular file, not read" unless info.regular
        return "is larger than #{LIMIT} bytes, not read" if info.size > LIMIT
        ""
      end
    end
  end
end
