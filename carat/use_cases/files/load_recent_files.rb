require_relative "../../domain/buffer_list"
require_relative "../../domain/recent_files_text"
require_relative "../../ports/file_port"

module Carat
  module UseCases
    # Adds the files an earlier run kept to the recent files when the editor
    # starts: it reads the state file under the home directory
    # (RecentFilesText), at most RecentFilesText::LIMIT bytes, and gives
    # the paths it holds to BufferList#restore_recent, after the files this
    # run already opened. It never fails: no home directory, a missing
    # file, one that is a directory or a FIFO or cannot be read, and a line
    # that is not a usable path all read as no paths.
    class LoadRecentFiles
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList

      #: (files: Ports::FilePort, buffers: Domain::BufferList) -> void
      def initialize(files:, buffers:)
        @files = files
        @buffers = buffers
      end

      #: () -> void
      def call
        path = Domain::RecentFilesText.location(@files.home)
        return if path.empty?
        text = +""
        begin
          text = @files.read(path, Domain::RecentFilesText::LIMIT)
        rescue StandardError
          return
        end
        @buffers.restore_recent(Domain::RecentFilesText.parse(text, Domain::BufferList::RECENT_LIMIT))
      end
    end
  end
end
