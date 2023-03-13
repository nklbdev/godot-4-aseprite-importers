@tool
extends EditorImportPlugin

const Common = preload("../common.gd")

func set_preset(name: StringName, options: Array[Dictionary],
	with_common_options: bool = true, with_texture_2d_options: bool = true) -> void:
	_presets[name] = options.duplicate()
	if with_common_options:
		_presets[name].append_array(_parent_plugin.common_options)
	if with_texture_2d_options:
		_presets[name].append_array(_parent_plugin.texture_2d_options)
	for option in _presets[name]:
		__option_visibility_checkers[option.name] = option.get_is_visible

var _parent_plugin: EditorPlugin
var _import_order: int = 0
var _importer_name: String = ""
var _priority: float = 1
var _recognized_extensions: PackedStringArray
var _resource_type: StringName
var _save_extension: String
var _visible_name: String
var _presets: Dictionary
var __option_visibility_checkers: Dictionary

func _init(parent_plugin: EditorPlugin) -> void:
	_parent_plugin = parent_plugin

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return _presets.values()[preset_index] as Array[Dictionary]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	var lambda = __option_visibility_checkers[option_name]
	return lambda.call(options) if lambda else true

func _get_import_order() -> int:
	return _import_order

func _get_importer_name() -> String:
	return _importer_name

func _get_preset_count() -> int:
	return _presets.size()

func _get_preset_name(preset_index: int) -> String:
	return _presets.keys()[preset_index]

func _get_priority() -> float:
	return _priority

func _get_recognized_extensions() -> PackedStringArray:
	return _recognized_extensions

func _get_resource_type() -> String:
	return _resource_type

func _get_save_extension() -> String:
	return _save_extension

func _get_visible_name() -> String:
	return _visible_name

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	return ERR_UNCONFIGURED

func _export_texture(source_file: String, common_options: Common.Options, image_options: Dictionary, gen_files: Array[String]) -> JSON:
	print("export texture")
	var png_path: String = source_file.get_basename() + ".png"
	var global_png_path: String = ProjectSettings.globalize_path(png_path)
	var output: Array = []
	prints("inner padding:", "1" if common_options.extrude else "0")
	var err: Error = OS.execute(
		ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME),
		PackedStringArray([
			"--batch",
			"--filename-format", "{tag}{tagframe}",
			"--format", "json-array",
			"--list-tags",
			"--ignore-empty",
			"--trim",
			"--inner-padding", "1" if common_options.extrude else "0",
			"--sheet-type", "packed",
			"--sheet", ProjectSettings.globalize_path(png_path),
			ProjectSettings.globalize_path(source_file)
		]), output, true)
	var json = JSON.new()
	json.parse(output[0])

	var image = Image.load_from_file(global_png_path)

	print("extrusion???")
	if common_options.extrude:
		print("extrusion")
		Common.extrude_edges_into_padding(image, json)
	image.save_png(global_png_path)
	image = null

	# Эта функция не импортирует файл. Но ее вызов нужен для того, чтобы append прошел без ошибок
	_parent_plugin.get_editor_interface().get_resource_filesystem().update_file(png_path)
	append_import_external_resource(png_path, image_options, "texture")
	gen_files.append(png_path)

	# НУЖНО ИМЕННО ТАК. IGNORE!!!!!!!!!!!!
	var texture: Texture2D = ResourceLoader.load(png_path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	texture.emit_changed()

	return json

static func _add_default_tag_if_needed(json: JSON, common_options: Common.Options) -> void:
	if json.data.meta.frameTags.is_empty():
		var default_animation_name = "default"
		if common_options.is_default_animation_looped:
			match common_options.animation_looping_marker_position:
				Common.MarkerPosition.PREFIX: default_animation_name = common_options.animation_looping_marker + default_animation_name
				Common.MarkerPosition.SUFFIX: default_animation_name = default_animation_name + common_options.animation_looping_marker
		json.data.meta.frameTags.push_back({
			name = default_animation_name,
			from = 0,
			to = json.data.frames.size() - 1,
			direction = Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS[common_options.default_animation_direction]
		})