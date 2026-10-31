require_relative "../../plugin_api"

module Carat
  module Plugins
    module Hello
      # The proof plugin: one action, plugin.hello.greet, bound by default
      # to <leader>hh, one ex command, :Hello [name] with the abbreviation
      # :Hel, a subscription to buffer_open, which it counts, the option
      # greeting, a message with the info icon of the configured set, and a
      # status segment with the number of greetings. It exercises the API
      # from inside the project; the explorer change may keep or remove it.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "hello"
        GREET = "plugin.hello.greet"

        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @opened: Integer
        # @rbs @greeted: Integer

        #: () -> void
        def initialize
          @host = nil
          @opened = 0
          @greeted = 0
        end

        # Returns the manifest.
        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(
            NAME,
            "0.1.0",
            Carat::PluginApi::VERSION,
            { "plugin.hello.greet" => "Show a greeting with the info icon and count it in the status line" },
            { "Hello" => "Hel" },
            { "normal" => { "<leader>hh" => GREET } },
            ["buffer_open"],
            { "greeting" => "Hello" },
            { "greeting" => "string" }
          )
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        #: (Carat::PluginApi::Event) -> void
        def on_event(event)
          @opened += 1 if event.name == "buffer_open"
        end

        #: (String, Carat::PluginApi::Context) -> void
        def on_action(name, context)
          greet("world") if name == GREET
        end

        #: (Carat::PluginApi::Command) -> void
        def on_command(command)
          greet(command.args.empty? ? "world" : command.args)
        end

        private

        #: (String) -> void
        def greet(who)
          host = @host
          return if host.nil?
          @greeted += 1
          plural = @opened == 1 ? "buffer" : "buffers"
          host.message("#{host.icon("info").text} #{host.option("greeting").text}, #{who}! #{@opened} #{plural} opened", false)
          host.set_status("hello #{@greeted}")
        end
      end
    end
  end
end
