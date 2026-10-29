require_relative "../../plugin_api"

module Carat
  module UseCases
    # The host a plugin receives at activation: one per plugin, carrying
    # the plugin's name, so every request reaches the plugin host with the
    # name of the plugin that made it. Each method forwards to the host
    # use case; the return values are described on PluginApi::Host.
    class PluginLink < PluginApi::Host
      # @rbs @host: PluginHost
      # @rbs @name: String

      #: (PluginHost, String) -> void
      def initialize(host, name)
        @host = host
        @name = name
      end

      #: () -> String
      def name
        @name
      end

      # Returns a BufferView.
      # @rbs number: Integer
      def read_buffer(number)
        @host.read_buffer(@name, number)
      end

      # Returns a Response.
      # @rbs number: Integer
      # @rbs edits: Array[untyped]
      def edit_buffer(number, edits)
        @host.edit_buffer(@name, number, edits)
      end

      # Returns a Response.
      # @rbs row: Integer
      # @rbs col: Integer
      def move_cursor(row, col)
        @host.move_cursor(@name, row, col)
      end

      # Returns a Response with the window number.
      # @rbs title: String
      # @rbs side: Symbol
      # @rbs width: Integer
      # @rbs lines: Array[String]
      # @rbs bindings: untyped
      def open_scratch(title, side, width, lines, bindings)
        @host.open_scratch(@name, title, side, width, lines, bindings)
      end

      # Returns a Response.
      # @rbs title: String
      # @rbs lines: Array[String]
      def set_scratch_lines(title, lines)
        @host.set_scratch_lines(@name, title, lines)
      end

      # Returns a Response.
      # @rbs title: String
      def close_scratch(title)
        @host.close_scratch(@name, title)
      end

      # Returns a Response.
      # @rbs number: Integer
      def focus_window(number)
        @host.focus_window(@name, number)
      end

      # Returns a Response.
      # @rbs number: Integer
      # @rbs path: String
      def open_file(number, path)
        @host.open_file(@name, number, path)
      end

      # Returns a Response.
      # @rbs text: String
      # @rbs error: bool
      def message(text, error)
        @host.message(@name, text, error)
      end

      # Returns a Response.
      # @rbs text: String
      def set_status(text)
        @host.set_status(@name, text)
      end

      # Returns a Response.
      # @rbs number: Integer
      # @rbs row: Integer
      # @rbs icon: String
      def place_sign(number, row, icon)
        @host.place_sign(@name, number, row, icon)
      end

      # Returns a Response.
      # @rbs number: Integer
      def clear_signs(number)
        @host.clear_signs(@name, number)
      end

      # Returns a Response.
      # @rbs text: String
      def run_ex(text)
        @host.run_ex(@name, text)
      end

      # Returns a Response whose lines are the entries.
      # @rbs path: String
      def list_dir(path)
        @host.list_dir(@name, path)
      end

      # Returns a FileInfo.
      # @rbs path: String
      def stat(path)
        @host.stat(@name, path)
      end

      # Returns the glyph.
      # @rbs name: String
      def icon(name)
        @host.icon(@name, name)
      end

      # Returns the option value as text.
      # @rbs name: String
      def option(name)
        @host.option(@name, name)
      end
    end
  end
end
