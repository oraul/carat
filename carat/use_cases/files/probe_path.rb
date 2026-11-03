require_relative "../../domain/path_info"
require_relative "../../ports/file_port"

module Carat
  module UseCases
    # What the file port says about a path; a path the port cannot stat,
    # as one it may not read, is missing. It is the one place the use
    # cases ask the port about a path, for the file operations and the
    # plugins' stat request.
    class ProbePath
      attr_reader :files #: Ports::FilePort

      #: (files: Ports::FilePort) -> void
      def initialize(files:)
        @files = files
      end

      #: (String) -> Domain::PathInfo
      def call(path)
        begin
          return @files.stat(path)
        rescue StandardError
          return Domain::PathInfo.missing
        end
      end
    end
  end
end
