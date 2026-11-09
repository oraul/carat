# The test runner: every test program under test/ in one Spinel program,
# compiled once. Each test is a module named after its file whose main is
# the test; the runner runs the one named by its argument, so every test
# runs in a process of its own, with its own output and exit status, which
# tools/run_tests.sh compares with the test's committed snapshot. spin
# treats only test/*.rb as test programs, so this file, one directory
# down, is not run as a test of its own.
require_relative "../adapters_assembly"
require_relative "../adapters_config_gateway"
require_relative "../adapters_dirty_rows"
require_relative "../adapters_frame_presenter"
require_relative "../adapters_hover"
require_relative "../adapters_key_decoder"
require_relative "../adapters_language_gateway"
require_relative "../adapters_screen_presenter"
require_relative "../adapters_server_completions"
require_relative "../adapters_signature"
require_relative "../adapters_status_bar"
require_relative "../adapters_tab_bar"
require_relative "../config_sync"
require_relative "../domain_buffer"
require_relative "../domain_buffer_list"
require_relative "../domain_edits"
require_relative "../domain_ex_grammar"
require_relative "../domain_ex_range"
require_relative "../domain_filetype"
require_relative "../domain_float_layer"
require_relative "../domain_frame"
require_relative "../domain_fuzzy_match"
require_relative "../domain_global"
require_relative "../domain_grammar"
require_relative "../domain_icons"
require_relative "../domain_keymap"
require_relative "../domain_keys"
require_relative "../domain_layout"
require_relative "../domain_line_cache"
require_relative "../domain_markdown_text"
require_relative "../domain_options_config"
require_relative "../domain_plugin_manifest"
require_relative "../domain_rc_parser"
require_relative "../domain_registers"
require_relative "../domain_rpc_framer"
require_relative "../domain_search"
require_relative "../domain_selection"
require_relative "../domain_signature_request"
require_relative "../domain_slot"
require_relative "../domain_substitute"
require_relative "../domain_syntax_cache"
require_relative "../domain_tab_list"
require_relative "../domain_theme"
require_relative "../domain_undo_tree"
require_relative "../domain_utf8"
require_relative "../domain_vim_pattern"
require_relative "../drivers_disk_files"
require_relative "../drivers_main_loop"
require_relative "../drivers_process_runner"
require_relative "../editor_buffers"
require_relative "../editor_cmdline"
require_relative "../editor_completion"
require_relative "../editor_explorer"
require_relative "../editor_floats"
require_relative "../editor_global"
require_relative "../editor_grammar"
require_relative "../editor_insert"
require_relative "../editor_key_hints"
require_relative "../editor_leader"
require_relative "../editor_lsp"
require_relative "../editor_motions"
require_relative "../editor_normal"
require_relative "../editor_operators"
require_relative "../editor_palette"
require_relative "../editor_plugins"
require_relative "../editor_registers"
require_relative "../editor_repeat"
require_relative "../editor_screen"
require_relative "../editor_scroll"
require_relative "../editor_search"
require_relative "../editor_slots"
require_relative "../editor_start_screen"
require_relative "../editor_substitute"
require_relative "../editor_syntax"
require_relative "../editor_tabs"
require_relative "../editor_text_objects"
require_relative "../editor_transactions"
require_relative "../editor_undo"
require_relative "../editor_visual"
require_relative "../editor_windows"
require_relative "../json"
require_relative "../lint"
require_relative "../plugins_explorer"
require_relative "../plugins_ruby"
require_relative "../smoke_editor"
require_relative "../use_cases_actions"
require_relative "../use_cases_arrange_view"
require_relative "../use_cases_ex"
require_relative "../use_cases_plugin_files"
require_relative "../use_cases_plugin_hardening"
require_relative "../use_cases_plugin_syntax"
require_relative "../use_cases_plugins"

case ARGV[0]
when "adapters_assembly" then AdaptersAssemblyTest.main
when "adapters_config_gateway" then AdaptersConfigGatewayTest.main
when "adapters_dirty_rows" then AdaptersDirtyRowsTest.main
when "adapters_frame_presenter" then AdaptersFramePresenterTest.main
when "adapters_hover" then AdaptersHoverTest.main
when "adapters_key_decoder" then AdaptersKeyDecoderTest.main
when "adapters_language_gateway" then AdaptersLanguageGatewayTest.main
when "adapters_screen_presenter" then AdaptersScreenPresenterTest.main
when "adapters_server_completions" then AdaptersServerCompletionsTest.main
when "adapters_signature" then AdaptersSignatureTest.main
when "adapters_status_bar" then AdaptersStatusBarTest.main
when "adapters_tab_bar" then AdaptersTabBarTest.main
when "config_sync" then ConfigSyncTest.main
when "domain_buffer" then DomainBufferTest.main
when "domain_buffer_list" then DomainBufferListTest.main
when "domain_edits" then DomainEditsTest.main
when "domain_ex_grammar" then DomainExGrammarTest.main
when "domain_ex_range" then DomainExRangeTest.main
when "domain_filetype" then DomainFiletypeTest.main
when "domain_float_layer" then DomainFloatLayerTest.main
when "domain_frame" then DomainFrameTest.main
when "domain_fuzzy_match" then DomainFuzzyMatchTest.main
when "domain_global" then DomainGlobalTest.main
when "domain_grammar" then DomainGrammarTest.main
when "domain_icons" then DomainIconsTest.main
when "domain_keymap" then DomainKeymapTest.main
when "domain_keys" then DomainKeysTest.main
when "domain_layout" then DomainLayoutTest.main
when "domain_line_cache" then DomainLineCacheTest.main
when "domain_markdown_text" then DomainMarkdownTextTest.main
when "domain_options_config" then DomainOptionsConfigTest.main
when "domain_plugin_manifest" then DomainPluginManifestTest.main
when "domain_rc_parser" then DomainRcParserTest.main
when "domain_registers" then DomainRegistersTest.main
when "domain_rpc_framer" then DomainRpcFramerTest.main
when "domain_search" then DomainSearchTest.main
when "domain_selection" then DomainSelectionTest.main
when "domain_signature_request" then DomainSignatureRequestTest.main
when "domain_slot" then DomainSlotTest.main
when "domain_substitute" then DomainSubstituteTest.main
when "domain_syntax_cache" then DomainSyntaxCacheTest.main
when "domain_tab_list" then DomainTabListTest.main
when "domain_theme" then DomainThemeTest.main
when "domain_undo_tree" then DomainUndoTreeTest.main
when "domain_utf8" then DomainUtf8Test.main
when "domain_vim_pattern" then DomainVimPatternTest.main
when "drivers_disk_files" then DriversDiskFilesTest.main
when "drivers_main_loop" then DriversMainLoopTest.main
when "drivers_process_runner" then DriversProcessRunnerTest.main
when "editor_buffers" then EditorBuffersTest.main
when "editor_cmdline" then EditorCmdlineTest.main
when "editor_completion" then EditorCompletionTest.main
when "editor_explorer" then EditorExplorerTest.main
when "editor_floats" then EditorFloatsTest.main
when "editor_global" then EditorGlobalTest.main
when "editor_grammar" then EditorGrammarTest.main
when "editor_insert" then EditorInsertTest.main
when "editor_key_hints" then EditorKeyHintsTest.main
when "editor_leader" then EditorLeaderTest.main
when "editor_lsp" then EditorLspTest.main
when "editor_motions" then EditorMotionsTest.main
when "editor_normal" then EditorNormalTest.main
when "editor_operators" then EditorOperatorsTest.main
when "editor_palette" then EditorPaletteTest.main
when "editor_plugins" then EditorPluginsTest.main
when "editor_registers" then EditorRegistersTest.main
when "editor_repeat" then EditorRepeatTest.main
when "editor_screen" then EditorScreenTest.main
when "editor_scroll" then EditorScrollTest.main
when "editor_search" then EditorSearchTest.main
when "editor_slots" then EditorSlotsTest.main
when "editor_start_screen" then EditorStartScreenTest.main
when "editor_substitute" then EditorSubstituteTest.main
when "editor_syntax" then EditorSyntaxTest.main
when "editor_tabs" then EditorTabsTest.main
when "editor_text_objects" then EditorTextObjectsTest.main
when "editor_transactions" then EditorTransactionsTest.main
when "editor_undo" then EditorUndoTest.main
when "editor_visual" then EditorVisualTest.main
when "editor_windows" then EditorWindowsTest.main
when "json" then JsonTest.main
when "lint" then LintTest.main
when "plugins_explorer" then PluginsExplorerTest.main
when "plugins_ruby" then PluginsRubyTest.main
when "smoke_editor" then SmokeEditorTest.main
when "use_cases_actions" then UseCasesActionsTest.main
when "use_cases_arrange_view" then UseCasesArrangeViewTest.main
when "use_cases_ex" then UseCasesExTest.main
when "use_cases_plugin_files" then UseCasesPluginFilesTest.main
when "use_cases_plugin_hardening" then UseCasesPluginHardeningTest.main
when "use_cases_plugin_syntax" then UseCasesPluginSyntaxTest.main
when "use_cases_plugins" then UseCasesPluginsTest.main
else
  STDERR.puts "run_all: unknown test #{ARGV[0].inspect}; add it to test/runner/run_all.rb"
  exit 2
end
