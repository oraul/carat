require_relative "../../domain/buffer_list"
require_relative "../../domain/recent_files_text"
require_relative "../../ports/file_port"

module Carat
  module UseCases
    # Writes the recent files to the state file under the home directory
    # (RecentFilesText) when the editor ends, creating the directories
    # above it, so the next run lists them again. Nothing is written with
    # no home directory or no recent file. It never fails: a directory or
    # file that cannot be made or written, a read-only home included, is
    # skipped, since the editor is ending and the list is a convenience.
    class SaveRecentFiles
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList

      #: (files: Ports::FilePort, buffers: Domain::BufferList) -> void
      def initialize(files:, buffers:)
        @files = files
        @buffers = buffers
      end

      #: () -> void
      def call
        home = @files.home
        path = Domain::RecentFilesText.location(home)
        text = Domain::RecentFilesText.render(@buffers.recent)
        return if path.empty? || text.empty?
        begin
          make_directories(home)
          @files.write(path, text)
        rescue StandardError
          return
        end
      end

      private

      # Makes the directories of the state file below home that are not
      # there yet, one at a time, the port having no recursive make.
      #: (String) -> void
      def make_directories(home)
        names = Domain::RecentFilesText::DIRECTORY.split("/")
        dir = home
        i = 0
        while i < names.length
          dir = "#{dir}/#{names[i]}"
          @files.mkdir(dir) unless @files.exist?(dir)
          i += 1
        end
      end
    end
  end
end
