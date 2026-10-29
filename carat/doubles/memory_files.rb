require_relative "../ports/file_port"

module Carat
  module Doubles
    # An in-memory file system: a hash from path to text. Paths listed in
    # unwritable raise on write, so tests can exercise E212.
    class MemoryFiles < Ports::FilePort
      attr_reader :unwritable #: Array[String]

      # @rbs @files: Hash[String, String]

      #: () -> void
      def initialize
        @files = {}
        @unwritable = []
      end

      #: (String, String) -> void
      def put(path, text)
        @files[path] = text
      end

      #: (String) -> String?
      def get(path)
        @files[path]
      end

      # Returns the file's text, raising when it is absent.
      # @rbs path: String
      def read(path)
        text = @files[path]
        raise ArgumentError, "no such file: #{path}" if text.nil?
        text
      end

      #: (String, String) -> void
      def write(path, text)
        raise ArgumentError, "Permission denied" if @unwritable.include?(path)
        @files[path] = text
      end

      # Returns whether the path was put or written.
      # @rbs path: String
      def exist?(path)
        @files.key?(path)
      end

      # Returns the sorted paths that start with dir.
      # @rbs dir: String
      def list(dir)
        out = []
        @files.each_key { |path| out << path if path.start_with?(dir) }
        out.sort
      end

      # Returns the size of the text and zero for mtime and directory,
      # raising for a path that was never put, as the disk does.
      # @rbs path: String
      def stat(path)
        text = @files[path]
        raise ArgumentError, "no such file: #{path}" if text.nil?
        { "size" => text.bytesize, "mtime" => 0, "directory" => 0 }
      end
    end
  end
end
