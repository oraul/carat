require_relative "../../plugin_api"

module Carat
  module Plugins
    module GitSigns
      # The git branch of the editor's working directory in the status bar:
      # the git icon, the branch, and the ahead and behind icons with the
      # counts against its upstream, each count only when above zero, as
      # the plugin's segment at the branch's priority. It asks git through
      # the host's run_program, when it activates, when a buffer opens or
      # is saved, and when a window gains the focus; both commands read
      # refs and objects only, never the work tree, so no filter or hook a
      # repository configures runs. Outside a repository, on a detached
      # head, or without git the segment is empty and nothing is said, and
      # so it is outside a root of language.trusted_roots, where the host
      # runs no program. A repository's configuration is untrusted even
      # there: each command refuses the ext:: transport and the fsmonitor
      # hook on its command line, which outranks the repository's, and the
      # host turns git's lazy fetch off, so a promisor remote runs nothing.
      # git's output is untrusted text: the first line only, control
      # characters dropped, at most NAME_LIMIT characters, and a count
      # that is not one to nine digits reads as zero.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "git_signs"
        PRIORITY = 40
        NAME_LIMIT = 60
        BRANCH = ["git", "-c", "protocol.ext.allow=never", "-c", "core.fsmonitor=false", "symbolic-ref", "--short", "-q", "HEAD"]
        COUNTS = ["git", "-c", "protocol.ext.allow=never", "-c", "core.fsmonitor=false", "rev-list", "--left-right", "--count", "HEAD...@{upstream}"]

        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @shown: String

        #: () -> void
        def initialize
          @host = nil
          @shown = ""
        end

        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(name: NAME, version: "0.1.0", api_version: Carat::PluginApi::VERSION, actions: {}, commands: {}, bindings: [], events: ["buffer_open", "buffer_save", "window_focus"], options: [], option_types: {}, filetypes: [])
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
          @shown = ""
          refresh
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        #: (Carat::PluginApi::Event) -> void
        def on_event(event)
          refresh
        end

        private

        # Asks git again and sets the segment when its text changed.
        #: () -> void
        def refresh
          host = @host
          return if host.nil?
          text = segment(host)
          return if text == @shown
          @shown = text
          host.set_segment(text, PRIORITY)
        end

        # The segment's text, "" when there is no branch to show.
        #: (Carat::PluginApi::Host) -> String
        def segment(host)
          branch = branch_name(run(host, BRANCH))
          return "" if branch.empty?
          text = "#{host.icon("git").text} #{branch}"
          counts = run(host, COUNTS).split
          ahead = counts.length == 2 ? count(counts[0]) : 0
          behind = counts.length == 2 ? count(counts[1]) : 0
          text += " #{host.icon("ahead").text}#{ahead}" if ahead > 0
          text += " #{host.icon("behind").text}#{behind}" if behind > 0
          text
        end

        # git's output, "" when it did not run.
        #: (Carat::PluginApi::Host, Array[String]) -> String
        def run(host, argv)
          response = host.run_program(argv)
          response.ok ? response.text : ""
        end

        # The first line without its control characters, cut to NAME_LIMIT
        # characters.
        #: (String) -> String
        def branch_name(output)
          line = output.lines.empty? ? "" : output.lines[0]
          name = +""
          line.each_char do |char|
            code = char.ord
            next if code < 32 || code == 127
            name << char
            break if name.length >= NAME_LIMIT
          end
          name.strip
        end

        # The number one to nine digits spell, 0 for anything else.
        #: (String) -> Integer
        def count(word)
          return 0 if word.empty? || word.length > 9
          return 0 unless word.each_char.all? { |char| char >= "0" && char <= "9" }
          word.to_i
        end
      end
    end
  end
end
