@tool
extends EditorPlugin

const Common = preload("common.gd")
const SettingsRegistry = preload("settings_registry.gd")
const ImportPlugin = preload("editor_import_plugins/_base.gd")

var __is_enabled: bool
var __import_plugins: Array[ImportPlugin]
var __settings_registry: SettingsRegistry = SettingsRegistry.new()

func _enter_tree() -> void:
	_enable_plugin()
	pass

func _exit_tree() -> void:
	if __is_enabled:
		__unlod_import_plugins()
		__is_enabled = false

func _enable_plugin() -> void:
	if not __is_enabled:
		__settings_registry.register_project_setting(
			Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME, "",
			TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE, "*.exe")
		__load_import_plugins()
		__is_enabled = true

func _disable_plugin() -> void:
	__is_enabled = false
	__unlod_import_plugins()
	__settings_registry.clear_registered_project_settings()

func __load_import_plugins() -> void:
	var dir: DirAccess = DirAccess.open(Common.IMPORT_PLUGINS_DIR)
	for file_name in dir.get_files():
		if file_name.ends_with(".gd"):
			var import_plugin: ImportPlugin = \
				load(Common.IMPORT_PLUGINS_DIR.path_join(file_name)) \
				.new(__settings_registry)
			add_import_plugin(import_plugin)
			__import_plugins.append(import_plugin)

func __unlod_import_plugins() -> void:
	for import_plugin in __import_plugins:
		remove_import_plugin(import_plugin)
	__import_plugins.clear()
