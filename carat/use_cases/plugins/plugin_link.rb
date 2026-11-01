require_relative "../../plugin_api"
require_relative "plugin_registry"
require_relative "buffer_requests"
require_relative "window_requests"
require_relative "file_requests"
require_relative "ui_requests"

module Carat
  module UseCases
    # The host a plugin receives at activation: one per plugin, carrying
    # the plugin's name. Each request checks once that the plugin is still
    # enabled, refusing it with the reason otherwise, and forwards to the
    # request family that serves it with the plugin's name. It overrides
    # every method of PluginApi::Host; the lint test checks that. The
    # return values are described on PluginApi::Host.
    class PluginLink < PluginApi::Host
      # @rbs @name: String
      # @rbs @registry: PluginRegistry
      # @rbs @buffers: BufferRequests
      # @rbs @windows: WindowRequests
      # @rbs @files: FileRequests
      # @rbs @ui: UiRequests

      #: (name: String, registry: PluginRegistry, buffer_requests: BufferRequests, window_requests: WindowRequests, file_requests: FileRequests, ui_requests: UiRequests) -> void
      def initialize(name:, registry:, buffer_requests:, window_requests:, file_requests:, ui_requests:)
        @name = name
        @registry = registry
        @buffers = buffer_requests
        @windows = window_requests
        @files = file_requests
        @ui = ui_requests
      end

      #: () -> String
      def name
        @name
      end

      # Returns a BufferView.
      # @rbs buffer: Integer
      def read_buffer(buffer)
        why = refusal
        return PluginApi::BufferView.missing(why) unless why.empty?
        @buffers.read_buffer(@name, buffer)
      end

      # Returns a Response.
      # @rbs buffer: Integer
      # @rbs edits: Array[untyped]
      def edit_buffer(buffer, edits)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @buffers.edit_buffer(@name, buffer, edits)
      end

      # Returns a Response.
      # @rbs row: Integer
      # @rbs col: Integer
      def move_cursor(row, col)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @buffers.move_cursor(@name, row, col)
      end

      # Returns a WindowResponse.
      # @rbs title: String
      # @rbs side: String
      # @rbs width: Integer
      # @rbs lines: Array[String]
      # @rbs bindings: untyped
      def open_scratch(title, side, width, lines, bindings)
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.open_scratch(@name, title, side, width, lines, bindings)
      end

      # Returns a Response.
      # @rbs title: String
      # @rbs lines: Array[String]
      def set_scratch_lines(title, lines)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @windows.set_scratch_lines(@name, title, lines)
      end

      # Returns a Response.
      # @rbs title: String
      def close_scratch(title)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @windows.close_scratch(@name, title)
      end

      # Returns a WindowResponse.
      # @rbs window: Integer
      def focus_window(window)
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.focus_window(@name, window)
      end

      # Returns a WindowResponse.
      # @rbs window: Integer
      # @rbs path: String
      def open_file(window, path)
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.open_file(@name, window, path)
      end

      # Returns a WindowResponse.
      # @rbs window: Integer
      # @rbs path: String
      # @rbs vertical: bool
      def open_in_split(window, path, vertical)
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.open_in_split(@name, window, path, vertical)
      end

      # Returns a WindowResponse.
      # @rbs path: String
      def open_in_tab(path)
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.open_in_tab(@name, path)
      end

      # Returns a Response.
      # @rbs text: String
      # @rbs error: bool
      def message(text, error)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @ui.message(@name, text, error)
      end

      # Returns a Response.
      # @rbs text: String
      def set_status(text)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @ui.set_status(@name, text)
      end

      # Returns a Response.
      # @rbs buffer: Integer
      # @rbs row: Integer
      # @rbs icon: String
      def place_sign(buffer, row, icon)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @buffers.place_sign(@name, buffer, row, icon)
      end

      # Returns a Response.
      # @rbs buffer: Integer
      def clear_signs(buffer)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @buffers.clear_signs(@name, buffer)
      end

      # Returns a Response.
      # @rbs text: String
      def run_ex(text)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @ui.run_ex(@name, text)
      end

      # Returns a Response.
      # @rbs path: String
      def list_dir(path)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @files.list_dir(@name, path)
      end

      # Returns a FileInfo.
      # @rbs path: String
      def stat(path)
        why = refusal
        return PluginApi::FileInfo.missing unless why.empty?
        @files.stat(@name, path)
      end

      # Returns a TextResponse.
      # @rbs name: String
      def icon(name)
        why = refusal
        return PluginApi::TextResponse.failure(why) unless why.empty?
        @ui.icon(@name, name)
      end

      # Returns a TextResponse.
      # @rbs name: String
      def option(name)
        why = refusal
        return PluginApi::TextResponse.failure(why) unless why.empty?
        @ui.option(@name, name)
      end

      # Returns a TextResponse.
      # @rbs skip
      def working_directory
        why = refusal
        return PluginApi::TextResponse.failure(why) unless why.empty?
        @ui.working_directory(@name)
      end

      # Returns a WindowResponse.
      # @rbs skip
      def editing_window
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.editing_window(@name)
      end

      # Returns a WindowResponse.
      # @rbs title: String
      def scratch_window(title)
        why = refusal
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        @windows.scratch_window(@name, title)
      end

      # Returns a Response.
      # @rbs root: String
      # @rbs path: String
      def make_file(root, path)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @files.make_file(@name, root, path)
      end

      # Returns a Response.
      # @rbs root: String
      # @rbs path: String
      def make_dir(root, path)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @files.make_dir(@name, root, path)
      end

      # Returns a Response.
      # @rbs root: String
      # @rbs path: String
      # @rbs name: String
      def rename_path(root, path, name)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @files.rename_path(@name, root, path, name)
      end

      # Returns a Response.
      # @rbs root: String
      # @rbs path: String
      def delete_path(root, path)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @files.delete_path(@name, root, path)
      end

      # Returns a Response.
      # @rbs id: String
      # @rbs text: String
      # @rbs initial: String
      def prompt(id, text, initial)
        why = refusal
        return PluginApi::Response.failure(why) unless why.empty?
        @ui.prompt(@name, id, text, initial)
      end

      private

      # Why a request of this plugin is refused, "" while it is enabled.
      #: () -> String
      def refusal
        @registry.refusal(@name)
      end
    end
  end
end
