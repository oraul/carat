require_relative "../ports/file_port"

module Carat
  module Drivers
    # The file system through File and Dir.
    class DiskFiles < Ports::FilePort
      # Returns the file's text.
      # @rbs path: String
      def read(path)
        File.read(path)
      end

      #: (String, String) -> void
      def write(path, text)
        File.write(path, text)
      end

      # Returns whether path exists.
      # @rbs path: String
      def exist?(path)
        File.exist?(path)
      end

      # Returns the sorted entry names of a directory.
      # @rbs dir: String
      def list(dir)
        Dir.children(dir).sort
      end

      # Returns size, mtime, and directory flag as a hash of integers.
      # @rbs path: String
      def stat(path)
        {
          "size" => File.size(path),
          "mtime" => File.mtime(path).to_i,
          "directory" => File.directory?(path) ? 1 : 0
        }
      end
    end
  end
end
