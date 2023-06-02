@tool
extends EditorPlugin

# TODO: разобраться с ошибкой:
# editor/editor_node.cpp:8152 - Condition "plugins_list.has(p_plugin)" is true.

const Common = preload("common.gd")
const SettingsRegistry = preload("settings_registry.gd")
const ImportPlugin = preload("editor_import_plugins/_base.gd")

var __import_plugins: Array[ImportPlugin]

var settings_registry: SettingsRegistry = SettingsRegistry.new()
var common_options: Array[Dictionary] = Common.create_common_options()
var texture_2d_options: Array[Dictionary] = Common.create_texture_2d_options()

func _enter_tree() -> void:
	settings_registry.register_project_setting(
		Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME, "",
		TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE, "*.exe")
	var dir: DirAccess = DirAccess.open(Common.IMPORT_PLUGINS_DIR)
	for file_name in dir.get_files():
		if file_name.ends_with(".gd") and not file_name.begins_with("_"):
			var import_plugin: ImportPlugin = \
				load(Common.IMPORT_PLUGINS_DIR.path_join(file_name)) \
				.new(self)
			add_import_plugin(import_plugin)
			__import_plugins.append(import_plugin)

func _exit_tree() -> void:
	for import_plugin in __import_plugins:
		remove_import_plugin(import_plugin)
	__import_plugins.clear()
