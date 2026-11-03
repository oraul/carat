# The test runner: every test program under test/ in one Spinel program,
# compiled once. Each test is a module named after its file whose main is
# the test; the runner runs the one named by its argument, so every test
# runs in a process of its own, with its own output and exit status, which
# tools/run_tests.sh compares with the test's committed snapshot. spin
# treats only test/*.rb as test programs, so this file, one directory
# down, is not run as a test of its own.
require_relative "../adapters_assembly"
require_relative "../adapters_dirty_rows"
require_relative "../adapters_frame_presenter"
require_relative "../adapters_key_decoder"
require_relative "../adapters_screen_presenter"
require_relative "../config_sync"
require_relative "../domain_buffer"
require_relative "../domain_buffer_list"
require_relative "../domain_edits"
require_relative "../domain_ex_grammar"
require_relative "../domain_frame"
require_relative "../domain_grammar"
require_relative "../domain_icons"
require_relative "../domain_keymap"
require_relative "../domain_keys"
require_relative "../domain_layout"
require_relative "../domain_line_cache"
require_relative "../domain_plugin_manifest"
require_relative "../domain_registers"
require_relative "../domain_selection"
require_relative "../domain_tab_list"
require_relative "../domain_undo_tree"
require_relative "../drivers_main_loop"
require_relative "../editor_cmdline"
require_relative "../editor_explorer"
require_relative "../editor_grammar"
require_relative "../editor_insert"
require_relative "../editor_motions"
require_relative "../editor_normal"
require_relative "../editor_operators"
require_relative "../editor_plugins"
require_relative "../editor_registers"
require_relative "../editor_repeat"
require_relative "../editor_screen"
require_relative "../editor_tabs"
require_relative "../editor_text_objects"
require_relative "../editor_transactions"
require_relative "../editor_undo"
require_relative "../editor_visual"
require_relative "../editor_windows"
require_relative "../json"
require_relative "../lint"
require_relative "../plugins_explorer"
require_relative "../smoke_editor"
require_relative "../use_cases_actions"
require_relative "../use_cases_arrange_view"
require_relative "../use_cases_ex"
require_relative "../use_cases_plugin_files"
require_relative "../use_cases_plugin_hardening"
require_relative "../use_cases_plugins"

case ARGV[0]
when "adapters_assembly" then AdaptersAssemblyTest.main
when "adapters_dirty_rows" then AdaptersDirtyRowsTest.main
when "adapters_frame_presenter" then AdaptersFramePresenterTest.main
when "adapters_key_decoder" then AdaptersKeyDecoderTest.main
when "adapters_screen_presenter" then AdaptersScreenPresenterTest.main
when "config_sync" then ConfigSyncTest.main
when "domain_buffer" then DomainBufferTest.main
when "domain_buffer_list" then DomainBufferListTest.main
when "domain_edits" then DomainEditsTest.main
when "domain_ex_grammar" then DomainExGrammarTest.main
when "domain_frame" then DomainFrameTest.main
when "domain_grammar" then DomainGrammarTest.main
when "domain_icons" then DomainIconsTest.main
when "domain_keymap" then DomainKeymapTest.main
when "domain_keys" then DomainKeysTest.main
when "domain_layout" then DomainLayoutTest.main
when "domain_line_cache" then DomainLineCacheTest.main
when "domain_plugin_manifest" then DomainPluginManifestTest.main
when "domain_registers" then DomainRegistersTest.main
when "domain_selection" then DomainSelectionTest.main
when "domain_tab_list" then DomainTabListTest.main
when "domain_undo_tree" then DomainUndoTreeTest.main
when "drivers_main_loop" then DriversMainLoopTest.main
when "editor_cmdline" then EditorCmdlineTest.main
when "editor_explorer" then EditorExplorerTest.main
when "editor_grammar" then EditorGrammarTest.main
when "editor_insert" then EditorInsertTest.main
when "editor_motions" then EditorMotionsTest.main
when "editor_normal" then EditorNormalTest.main
when "editor_operators" then EditorOperatorsTest.main
when "editor_plugins" then EditorPluginsTest.main
when "editor_registers" then EditorRegistersTest.main
when "editor_repeat" then EditorRepeatTest.main
when "editor_screen" then EditorScreenTest.main
when "editor_tabs" then EditorTabsTest.main
when "editor_text_objects" then EditorTextObjectsTest.main
when "editor_transactions" then EditorTransactionsTest.main
when "editor_undo" then EditorUndoTest.main
when "editor_visual" then EditorVisualTest.main
when "editor_windows" then EditorWindowsTest.main
when "json" then JsonTest.main
when "lint" then LintTest.main
when "plugins_explorer" then PluginsExplorerTest.main
when "smoke_editor" then SmokeEditorTest.main
when "use_cases_actions" then UseCasesActionsTest.main
when "use_cases_arrange_view" then UseCasesArrangeViewTest.main
when "use_cases_ex" then UseCasesExTest.main
when "use_cases_plugin_files" then UseCasesPluginFilesTest.main
when "use_cases_plugin_hardening" then UseCasesPluginHardeningTest.main
when "use_cases_plugins" then UseCasesPluginsTest.main
else
  STDERR.puts "run_all: unknown test #{ARGV[0].inspect}; add it to test/runner/run_all.rb"
  exit 2
end
