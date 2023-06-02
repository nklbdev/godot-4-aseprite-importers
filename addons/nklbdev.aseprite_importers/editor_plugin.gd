@tool
extends EditorPlugin

const PLUGIN_SCRIPTS: Array[GDScript] = [
	preload("editor_import_plugins/animated_sprite_2d.gd"),
	preload("editor_import_plugins/animated_sprite_3d.gd"),
	preload("editor_import_plugins/sprite_2d.gd"),
	preload("editor_import_plugins/sprite_3d.gd"),
	preload("editor_import_plugins/sprite_frames.gd"),
	preload("editor_import_plugins/texture_rect.gd"),
	preload("editor_import_plugins/sprite_sheet.gd"),
]

const Common = preload("common.gd")
const SpriteSheetImportPlugin = preload("editor_import_plugins/_sprite_sheet_importer_base.gd")
const AsepriteImageFormatLoaderExtension = preload("aseprite_image_format_loader_extension.gd")

var __sprite_sheet_import_plugins: Array[SpriteSheetImportPlugin]
var __aseprite_image_format_loader_extension: AsepriteImageFormatLoaderExtension

var common_sprite_sheet_options: Array[Dictionary] = Common.create_common_sprite_sheet_options()
var common_animation_options: Array[Dictionary] = Common.create_common_animation_options()

func _enter_tree() -> void:
	__register_project_setting(
		Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME, "",
		TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE, "*.exe")

	for plugin_script in PLUGIN_SCRIPTS:
		var sprite_sheet_import_plugin = plugin_script.new(self) as SpriteSheetImportPlugin
		__sprite_sheet_import_plugins.append(sprite_sheet_import_plugin)
		add_import_plugin(sprite_sheet_import_plugin)

	__aseprite_image_format_loader_extension = AsepriteImageFormatLoaderExtension.new()
	__aseprite_image_format_loader_extension.add_format_loader()

func _exit_tree() -> void:
	for sprite_sheet_import_plugin in __sprite_sheet_import_plugins:
		remove_import_plugin(sprite_sheet_import_plugin)
	__sprite_sheet_import_plugins.clear()

	__aseprite_image_format_loader_extension.remove_format_loader()
	__aseprite_image_format_loader_extension = null

func __register_project_setting(name: StringName, initial_value, type: int, hint: int, hint_string: String = "") -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, initial_value)
		ProjectSettings.set_initial_value(name, initial_value)
		var property_info: Dictionary = { name = name, type = type, hint = hint }
		if hint_string: property_info.hint_string = hint_string
		ProjectSettings.add_property_info(property_info)
