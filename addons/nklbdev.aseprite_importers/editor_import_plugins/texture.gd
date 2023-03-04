@tool
extends "_base.gd"

enum Presets {
	ANIMATION
}

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	match preset_index:
#		Presets.ANIMATION:
#			return [
#				{
#					"name": "extrude",
#					"type": TYPE_BOOL,
#					"default_value": false,
#					"usage": PROPERTY_USAGE_EDITOR
#				},
#				{
#					"name": "default_direction",
#					"type": TYPE_STRING,
#					"property_hint": PROPERTY_HINT_ENUM,
#					"hint_string": "Forward,Reverse,Ping-pong",
#					"default_value": "Forward",
#					"usage": PROPERTY_USAGE_EDITOR
#				},
#				{
#					"name": "default_loop",
#					"type": TYPE_BOOL,
#					"default_value": false,
#					"usage": PROPERTY_USAGE_EDITOR
#				}
#			]
		_:
			return []

func _get_import_order() -> int:
	return 0

func _get_importer_name() -> String:
	return "Aseprite Texture2D Import"

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_preset_count() -> int:
	return Presets.size()

func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		Presets.ANIMATION:
			return "Animation"
		_:
			return "Unknown"

func _get_priority() -> float:
	return 1

const __recognized_extensions: PackedStringArray = ["aseprite", "ase"]
func _get_recognized_extensions() -> PackedStringArray:
	return __recognized_extensions

const __resource_type: StringName = "CompressedTexture2D"
func _get_resource_type() -> String:
	return __resource_type

const __save_extension: StringName = "ctex"
func _get_save_extension() -> String:
	return __save_extension

const __visible_name: StringName = "Texture2D"
func _get_visible_name() -> String:
	return __visible_name

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var export_result: Dictionary = export_sprite_sheet(save_path, source_file, false)

	if export_result.error != OK:
		return export_result.error

	var texture: ImageTexture = ImageTexture.create_from_image(export_result.image)
	var d: texture
	var status = ResourceSaver.save(
		texture,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS)
	if status != OK:
		push_error("Can't save imported resource.", status)
	return status

func export_sprite_sheet(save_path: String, source_file: String, extrude: bool) -> Dictionary:
	var png_path: String = save_path + ".png"
	var output: Array = []
	var err: Error = OS.execute(
		ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME),
		PackedStringArray([
			"--batch",
			"--filename-format", "{tag}{tagframe}",
			"--format", "json-array",
			"--list-tags",
			"--ignore-empty",
			"--trim",
			"--inner-padding", "1" if extrude else "0",
			"--sheet-type", "packed",
			"--sheet", ProjectSettings.globalize_path(png_path),
			ProjectSettings.globalize_path(source_file)
		]), output, true)
	var json = JSON.parse_string(output[0])
	var image = Image.load_from_file(png_path)
	if extrude:
		extrude_edges_into_padding(image, json)
	var status = DirAccess.remove_absolute(png_path)
	if status != OK:
		push_error("Can't remove temporary png image.", status)
		return { error = status }
	return { image = image, error = OK }

func extrude_edges_into_padding(image, json):
	image.lock()
	for frame_data in json.frames:
		var frame = frame_data.frame
		var x = 0
		var y = frame.y
		for i in range(frame.w):
			x = frame.x + i
			image.set_pixel(x, y, image.get_pixel(x, y + 1))
		x = frame.x + frame.w - 1
		for i in range(frame.h):
			y = frame.y + i
			image.set_pixel(x, y, image.get_pixel(x - 1, y))
		y = frame.y + frame.h - 1
		for i in range(frame.w):
			x = frame.x + i
			image.set_pixel(x, y, image.get_pixel(x, y - 1))
		x = frame.x
		for i in range(frame.h):
			y = frame.y + i
			image.set_pixel(x, y, image.get_pixel(x + 1, y))
	image.unlock()
