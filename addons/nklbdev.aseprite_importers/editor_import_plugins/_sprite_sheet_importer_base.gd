extends "_importer_base.gd"

# Base class for all sprite_sheet import plugins

func set_preset(name: StringName, options: Array[Dictionary]) -> void:
	var combined_options: Array[Dictionary] = _parent_plugin.common_sprite_sheet_options.duplicate()
	combined_options.append_array(options)
	super.set_preset(name, combined_options)

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)

class SpriteSheetExportResult:
	var raw_output: String
	var parsed_json: JSON
	var texture: PortableCompressedTexture2D
	var source_size: Vector2i
	var sprite_sheet_size: Vector2i
	var border_type: Common.BorderType

const __sheet_types_by_sprite_sheet_layout: Dictionary = {
	Common.SpriteSheetLayout.PACKED: "packed",
	Common.SpriteSheetLayout.BY_ROWS: "rows",
	Common.SpriteSheetLayout.BY_COLUMNS: "columns",
}

func _export_sprite_sheet(source_file: String, sprite_sheet_options: Common.ParsedSpriteSheetOptions) -> SpriteSheetExportResult:
	var export_result = SpriteSheetExportResult.new()
	var png_path: String = source_file.get_basename() + ".png"
	var global_png_path: String = ProjectSettings.globalize_path(png_path)
	var is_png_file_present = FileAccess.file_exists(png_path)

	var aseprite_executable_path: String = ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME)
	if not FileAccess.file_exists(aseprite_executable_path):
		push_error("Cannot fild Aseprite executable. Check Aseprite executable path in project settings.")
		return null

	var variable_options: Array
	if sprite_sheet_options.sprite_sheet_layout == Common.SpriteSheetLayout.BY_ROWS:
		variable_options += ["--sheet-columns", str(sprite_sheet_options.sprite_sheet_fixed_columns_count)]
	if sprite_sheet_options.sprite_sheet_layout == Common.SpriteSheetLayout.BY_COLUMNS:
		variable_options += ["--sheet-rows", str(sprite_sheet_options.sprite_sheet_fixed_rows_count)]
	match sprite_sheet_options.border_type:
		Common.BorderType.Transparent: variable_options += ["--inner-padding", "1"]
		Common.BorderType.Extruded: variable_options += ["--extrude"]
		Common.BorderType.None: pass
		_: push_error("unexpected border type")
	if sprite_sheet_options.ignore_empty: variable_options += ["--ignore-empty"]
	if sprite_sheet_options.merge_duplicates: variable_options += ["--merge-duplicates"]
	if sprite_sheet_options.trim: variable_options += ["--trim" if sprite_sheet_options.sprite_sheet_layout == Common.SpriteSheetLayout.PACKED else "--trim-sprite"]

	var command_line_params: PackedStringArray = PackedStringArray([
		"--batch",
		"--filename-format", "{tag}{tagframe}",
		"--format", "json-array",
		"--list-tags",
		"--trim" if sprite_sheet_options.sprite_sheet_layout == Common.SpriteSheetLayout.PACKED else "--trim-sprite" if sprite_sheet_options.trim else "",
		"--sheet-type", __sheet_types_by_sprite_sheet_layout[sprite_sheet_options.sprite_sheet_layout],
		] + variable_options + [
		"--sheet", global_png_path,
		ProjectSettings.globalize_path(source_file)
	])

	var output: Array = []
	var err: Error = OS.execute(
		ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME),
		command_line_params, output, true)
	var json = JSON.new()
	json.parse(output[0])

	var sourceSizeData = json.data.frames[0].sourceSize
	export_result.source_size = Vector2i(sourceSizeData.w, sourceSizeData.h)
	export_result.sprite_sheet_size = Vector2i(json.data.meta.size.w, json.data.meta.size.h)

	var image = Image.load_from_file(global_png_path)
	var texture = PortableCompressedTexture2D.new()
	texture.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	DirAccess.remove_absolute(global_png_path)

	export_result.texture = texture
	export_result.raw_output = output[0]
	export_result.parsed_json = json
	export_result.border_type = sprite_sheet_options.border_type
	return export_result
