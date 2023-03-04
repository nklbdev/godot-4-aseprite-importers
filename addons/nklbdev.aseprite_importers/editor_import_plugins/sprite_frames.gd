@tool
extends "_base.gd"

enum Presets { ANIMATION }

const DIRECTION_MAP: Dictionary = {
	"Forward": "forward",
	"Reverse": "reverse",
	"Ping-pong": "pingpong"
}

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	match preset_index:
		Presets.ANIMATION:
			return [
				{
					"name": "extrude",
					"type": TYPE_BOOL,
					"default_value": false,
					"usage": PROPERTY_USAGE_EDITOR
				},
				{
					"name": "default_direction",
					"type": TYPE_STRING,
					"property_hint": PROPERTY_HINT_ENUM,
					"hint_string": "Forward,Reverse,Ping-pong",
					"default_value": "Forward",
					"usage": PROPERTY_USAGE_EDITOR
				},
				{
					"name": "default_loop",
					"type": TYPE_BOOL,
					"default_value": false,
					"usage": PROPERTY_USAGE_EDITOR
				}
			]
		_:
			return []

func _get_import_order() -> int:
	return 0

func _get_importer_name() -> String:
	return "Aseprite SpriteFrames Import"

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

const __resource_type: StringName = "SpriteFrames"
func _get_resource_type() -> String:
	return __resource_type

const __save_extension: StringName = "res"
func _get_save_extension() -> String:
	return __save_extension

const __visible_name: StringName = "SpriteFrames"
func _get_visible_name() -> String:
	return __visible_name

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var export_result: Dictionary = export_sprite_sheet(save_path, source_file, false)

	if export_result.error != OK:
		return export_result.error

	if export_result.json.meta.frameTags.is_empty():
		export_result.json.meta.frameTags.push_back({
			"name": ("_" if options.default_loop else "") + "default",
			"from": 0,
			"to": export_result.json.frames.size() - 1,
			"direction": DIRECTION_MAP[options.default_direction]
		})

	var sprite_frames = get_sprite_frames(source_file)

	var unique_names = []
	for frame_tag in export_result.json.meta.frameTags:
		frame_tag.name = frame_tag.name.strip_edges().strip_escapes()
		if frame_tag.name.is_empty():
			push_error("Found empty tag name")
			return ERR_INVALID_DATA
		var loop = frame_tag.name.left(1)
		frame_tag.looped = loop == "_"
		if frame_tag.looped:
			frame_tag.name = frame_tag.name.substr(1)
		if unique_names.has(frame_tag.name):
			push_error("Found duplicated tag name")
			return ERR_INVALID_DATA
		unique_names.append(frame_tag.name)

	var names = sprite_frames.get_animation_names()
	for name in names:
		if unique_names.has(name):
			sprite_frames.clear(name)
		else:
			sprite_frames.remove_animation(name)

	var atlas_textures = {}

	for frame_tag in export_result.json.meta.frameTags:
		var name = frame_tag.name
		if not sprite_frames.has_animation(name):
			sprite_frames.add_animation(name)
		sprite_frames.set_animation_loop(name, frame_tag.looped)
		var frame_indices = []
		for frame_index in range(frame_tag.from, frame_tag.to + 1):
			frame_indices.append(frame_index)
		match frame_tag.direction:
			"forward":
				pass
			"reverse":
				frame_indices.invert()
			"pingpong":
				var l = frame_indices.size()
				if l > 2:
					for frame_index in range(frame_tag.to - 1, frame_tag.from, -1):
						frame_indices.append(frame_index)

		var frame_duration = null
		for frame_index in frame_indices:
			var frame_data = export_result.json.frames[frame_index]
			var frame = frame_data.frame
			var sprite_source_size = frame_data.spriteSourceSize
			var source_size = frame_data.sourceSize

			var x = frame.x + 1 if options.extrude else frame.x
			var y = frame.y + 1 if options.extrude else frame.y
			var w = frame.w - 2 if options.extrude else frame.w
			var h = frame.h - 2 if options.extrude else frame.h

			var key = "%d_%d_%d_%d" % [x, y, w, h]
			var atlas_texture = atlas_textures.get(key)
			if atlas_texture == null:
				atlas_texture = AtlasTexture.new()
				atlas_texture.atlas = export_result.texture
				atlas_texture.region = Rect2(x, y, w, h)
				atlas_texture.margin = Rect2(sprite_source_size.x, sprite_source_size.y, source_size.w - w, source_size.h - h)
				atlas_textures[key] = atlas_texture

			sprite_frames.add_frame(name, atlas_texture)
			if frame_duration == null:
				frame_duration = export_result.json.frames[frame_index].duration
		sprite_frames.set_animation_speed(name, 1000 / frame_duration)

	var status = ResourceSaver.save(
		sprite_frames,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS |
		ResourceSaver.FLAG_BUNDLE_RESOURCES |
		ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
	)
	if status != OK:
		push_error("Can't save imported resource.", status)
	return status

func get_sprite_frames(source_file):
	var sprite_frames
	if ResourceLoader.exists(source_file):
		sprite_frames = ResourceLoader.load(source_file, "SpriteFrames", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		sprite_frames = SpriteFrames.new()
	return sprite_frames

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
	var texture = ImageTexture.create_from_image(image)
	var status = DirAccess.remove_absolute(png_path)
	if status != OK:
		push_error("Can't remove temporary png image.", status)
		return { "error": status }
	return { "texture": texture, "json": json, "error": OK }

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
