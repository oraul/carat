module Carat
  module UseCases
    # The one path every call into a plugin takes, so nothing a plugin
    # raises reaches the editor: StandardError, ScriptError (an
    # unimplemented method's NotImplementedError among them), and
    # SystemStackError are caught, and the plugin is disabled with the
    # message. The registry is told when the call begins and ends, which is
    # how it knows the depth of nested plugin calls and which plugin caused
    # what happens meanwhile.
    #
    # Readers the including class provides: registry (PluginRegistry).
    module Guarded
      # Runs the block as a call into the plugin of the entry and returns
      # whether it completed without raising.
      # @rbs skip
      def guarded(entry)
        registry.enter(entry.name)
        failure = ""
        begin
          yield
        rescue StandardError, ScriptError, SystemStackError => error
          failure = error.message
          failure = error.class.name.to_s if failure.empty?
        end
        registry.leave
        registry.disable(entry, failure) unless failure.empty?
        failure.empty?
      end
    end
  end
end
