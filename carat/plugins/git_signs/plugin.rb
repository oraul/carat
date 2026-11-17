require_relative "../../plugin_api"
require_relative "line_diff"

module Carat
  module Plugins
    module GitSigns
      # The git branch of the editor's working directory in the status bar
      # and a sign on each line of a buffer that differs from its file at
      # HEAD. The segment is the git icon, the branch, and the ahead and
      # behind icons with the counts against its upstream, each count only
      # when above zero, at the branch's priority; the signs are the
      # git_added, git_changed, and git_deleted icons LineDiff places,
      # comparing the buffer's text, unsaved edits included, with the
      # file's text at HEAD. It asks git through the host's run_program
      # when it activates, when a buffer opens or is saved, and when a
      # window gains the focus; every command reads refs and objects only,
      # never the work tree, so no filter or hook a repository configures
      # runs. A focus asks no git while the HEAD key, what .git/HEAD, its
      # branch's ref file, packed-refs, and logs/HEAD read, is the one of
      # the last git run and the plugin holds the text of the buffer's
      # path at it, so a buffer renamed under the same id asks git again.
      # After a command runs past the host's deadline no event runs git
      # until the HEAD key changes, so one slow repository stalls one
      # event. Outside a repository, on a detached head, or without git
      # the segment is empty, no sign shows, and nothing is said, and so
      # it is outside a root of language.trusted_roots, where the host runs
      # no program. A repository's configuration is untrusted even there:
      # each command refuses the ext:: transport and the fsmonitor hook on
      # its command line, which outranks the repository's, and the host
      # turns git's lazy fetch off, so a promisor remote runs nothing.
      # git's output is untrusted text: for the branch the first line only,
      # control characters dropped, at most NAME_LIMIT characters; a count
      # that is not one to nine digits reads as zero; a file's text longer
      # than TEXT_LIMIT bytes, which a capture may have cut, or holding a
      # NUL shows no sign.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "git_signs"
        PRIORITY = 40
        NAME_LIMIT = 60
        TEXT_LIMIT = 65_532
        TIMEOUT = "ran past 2 seconds"
        BRANCH = ["git", "-c", "protocol.ext.allow=never", "-c", "core.fsmonitor=false", "symbolic-ref", "--short", "-q", "HEAD"]
        COUNTS = ["git", "-c", "protocol.ext.allow=never", "-c", "core.fsmonitor=false", "rev-list", "--left-right", "--count", "HEAD...@{upstream}"]
        TEXT = ["git", "-c", "protocol.ext.allow=never", "-c", "core.fsmonitor=false", "cat-file", "blob"]
        SIGNS = ["", "git_added", "git_changed", "git_deleted"]

        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @shown: String
        # @rbs @key: String
        # @rbs @stalled: bool
        # @rbs @stalled_key: String
        # @rbs @buffers: Array[Integer]
        # @rbs @keys: Array[String]
        # @rbs @paths: Array[String]
        # @rbs @texts: Array[String]

        #: () -> void
        def initialize
          @host = nil
          @shown = ""
          @key = ""
          @stalled = false
          @stalled_key = ""
          @buffers = []
          @keys = []
          @paths = []
          @texts = []
        end

        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(name: NAME, version: "0.1.0", api_version: Carat::PluginApi::VERSION, actions: {}, commands: {}, bindings: [], events: ["buffer_open", "buffer_save", "buffer_close", "window_focus"], options: [], option_types: {}, filetypes: [])
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
          forget
          view = host.read_buffer(0)
          refresh("activate", view.buffer, view.ok ? view.path : "")
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        #: (Carat::PluginApi::Event) -> void
        def on_event(event)
          if event.name == "buffer_close"
            drop(event.buffer)
            return
          end
          refresh(event.name, event.buffer, event.path)
        end

        private

        # Clears what the plugin learned: the segment shown, the HEAD key of
        # the last git run, the stall, and the texts it holds.
        #: () -> void
        def forget
          @shown = ""
          @key = ""
          @stalled = false
          @stalled_key = ""
          @buffers.clear
          @keys.clear
          @paths.clear
          @texts.clear
        end

        # Sets the segment and the signs of the buffer at path, asking git
        # unless the event is a focus with nothing git knows changed, or a
        # command timed out at the current HEAD key; a timeout stops the
        # event's remaining commands and keeps what shows. The buffer is
        # read only to place its signs.
        #: (String, Integer, String) -> void
        def refresh(name, buffer, path)
          host = @host
          return if host.nil?
          key = head_key(host)
          if @stalled
            return if key == @stalled_key
            @stalled = false
          end
          if name == "window_focus" && !key.empty? && key == @key
            file = relative_path(host, path)
            if file.empty? || held?(buffer, key, file)
              show_signs(host, buffer, held_text(buffer)) unless file.empty?
              return
            end
          end
          branch = branch_name(run(host, BRANCH, key))
          return if @stalled
          text = segment(host, branch, key)
          return if @stalled
          show_segment(host, text)
          @key = key
          if branch.empty?
            drop(buffer)
            return
          end
          file = relative_path(host, path)
          return if file.empty?
          unless held?(buffer, key, file)
            output = run(host, TEXT + ["HEAD:./#{file}"], key)
            return if @stalled
            keep(buffer, key, file, output)
          end
          show_signs(host, buffer, held_text(buffer))
        end

        # The segment's text, "" when there is no branch to show.
        #: (Carat::PluginApi::Host, String, String) -> String
        def segment(host, branch, key)
          return "" if branch.empty?
          text = "#{host.icon("git").text} #{branch}"
          counts = run(host, COUNTS, key).split
          ahead = counts.length == 2 ? count(counts[0]) : 0
          behind = counts.length == 2 ? count(counts[1]) : 0
          text += " #{host.icon("ahead").text}#{ahead}" if ahead > 0
          text += " #{host.icon("behind").text}#{behind}" if behind > 0
          text
        end

        # Sets the segment when its text changed.
        #: (Carat::PluginApi::Host, String) -> void
        def show_segment(host, text)
          return if text == @shown
          @shown = text
          host.set_segment(text, PRIORITY)
        end

        # git's output, "" when it did not run; a run past the deadline
        # records the HEAD key as stalled.
        #: (Carat::PluginApi::Host, Array[String], String) -> String
        def run(host, argv, key)
          response = host.run_program(argv)
          return response.text if response.ok
          if response.message.end_with?(TIMEOUT)
            @stalled = true
            @stalled_key = key
          end
          ""
        end

        # What .git/HEAD, its branch's ref file, packed-refs, and logs/HEAD
        # read below the working directory, joined; "" when .git/HEAD
        # cannot be read or names a ref outside refs/. A stat comes first,
        # so outside a repository nothing is read.
        #: (Carat::PluginApi::Host) -> String
        def head_key(host)
          return "" unless host.stat(".git/HEAD").ok
          answer = host.read_file(".git/HEAD", 1)
          return "" unless answer.ok && answer.lines.length == 1
          line = answer.lines[0]
          key = +""
          key << line
          if line.start_with?("ref: ")
            ref = line.byteslice(5, line.bytesize - 5).to_s
            return "" unless ref.start_with?("refs/") && !ref.include?("..")
            target = host.read_file(".git/#{ref}", 1)
            key << "\n" << (target.ok && target.lines.length == 1 ? target.lines[0] : "-")
          end
          key << "\n" << stamp(host.stat(".git/packed-refs"))
          key << "\n" << stamp(host.stat(".git/logs/HEAD"))
          key
        end

        # A file's size and modification time, "-" when it cannot be read.
        #: (Carat::PluginApi::FileInfo) -> String
        def stamp(info)
          info.ok ? "#{info.size} #{info.mtime}" : "-"
        end

        # The buffer's path relative to the working directory, "" for no
        # path or one outside it.
        #: (Carat::PluginApi::Host, String) -> String
        def relative_path(host, path)
          return "" if path.empty?
          cwd = Carat::PluginApi::Paths.normalize(host.working_directory.text)
          full = Carat::PluginApi::Paths.absolute(cwd, path)
          return "" unless Carat::PluginApi::Paths.inside?(cwd, full)
          Carat::PluginApi::Paths.relative(cwd, full)
        end

        # Places the buffer's signs against the text at HEAD, none when it
        # has no lines.
        #: (Carat::PluginApi::Host, Integer, String) -> void
        def show_signs(host, buffer, text)
          host.clear_signs(buffer)
          head = head_lines(text)
          return if head.empty?
          view = host.read_buffer(buffer)
          return unless view.ok
          marks = LineDiff.marks(head, view.lines)
          row = 0
          while row < marks.length
            host.place_sign(view.buffer, row, SIGNS[marks[row]]) if marks[row] != LineDiff::NONE
            row += 1
          end
        end

        # The lines of git's text at HEAD without their newlines, none when
        # it may have been cut or holds a NUL.
        #: (String) -> Array[String]
        def head_lines(text)
          lines = [""]
          lines.clear
          return lines if text.bytesize > TEXT_LIMIT || text.include?("\0")
          text.each_line do |line|
            lines << (line.end_with?("\n") ? line.byteslice(0, line.bytesize - 1).to_s : line)
          end
          lines
        end

        # Whether the plugin holds the buffer's text at the HEAD key for
        # the relative path, which a rename of the buffer changes.
        #: (Integer, String, String) -> bool
        def held?(buffer, key, file)
          at = @buffers.index(buffer)
          !at.nil? && !key.empty? && @keys[at] == key && @paths[at] == file
        end

        # The buffer's text at HEAD the plugin holds, "" for none.
        #: (Integer) -> String
        def held_text(buffer)
          at = @buffers.index(buffer)
          at.nil? ? "" : @texts[at]
        end

        #: (Integer, String, String, String) -> void
        def keep(buffer, key, file, text)
          at = @buffers.index(buffer)
          if at.nil?
            @buffers << buffer
            @keys << key
            @paths << file
            @texts << text
          else
            @keys[at] = key
            @paths[at] = file
            @texts[at] = text
          end
        end

        # Forgets the buffer's text and clears its signs.
        #: (Integer) -> void
        def drop(buffer)
          at = @buffers.index(buffer)
          return if at.nil?
          @buffers.delete_at(at)
          @keys.delete_at(at)
          @paths.delete_at(at)
          @texts.delete_at(at)
          host = @host
          host.clear_signs(buffer) unless host.nil?
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
