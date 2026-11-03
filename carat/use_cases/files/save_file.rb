require_relative "../../domain/buffer"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "../plugins/plugin_host"

module Carat
  module UseCases
    # Writes a buffer, which need not be the current one, to its path, or
    # to the given path, with Vim's messages: the written message, E32,
    # E212, and E382 for a scratch buffer, which is never written. An
    # unnamed buffer takes the path it is written to, and the buffer is
    # unmodified after a write to its own path. A write is reported to the
    # plugins as a buffer_save event. :w writes the current buffer; SaveAll
    # writes every modified one this way.
    class SaveFile
      E382 = "E382: Cannot write, 'buftype' option is set"
      private_constant :E382

      attr_reader :files #: Ports::FilePort
      attr_reader :plugins #: PluginHost

      #: (files: Ports::FilePort, plugins: PluginHost) -> void
      def initialize(files:, plugins:)
        @files = files
        @plugins = plugins
      end

      # path_arg is the command argument; empty means the buffer's own
      # path.
      #: (Domain::Buffer, String) -> Outcome
      def call(buffer, path_arg)
        return Outcome.failure(E382) if buffer.scratch?
        own = buffer.path
        path = path_arg.empty? ? own : path_arg
        return Outcome.failure("E32: No file name") if path.nil?
        text = buffer.to_text
        begin
          @files.write(path, text)
        rescue StandardError => e
          return Outcome.failure("E212: Can't open file for writing: #{e.message}")
        end
        if own.nil?
          buffer.rename(path)
          own = path
        end
        buffer.mark_saved if path == own
        @plugins.saved(buffer)
        Outcome.success("\"#{path}\" #{buffer.line_count}L, #{text.bytesize}B written")
      end
    end
  end
end
