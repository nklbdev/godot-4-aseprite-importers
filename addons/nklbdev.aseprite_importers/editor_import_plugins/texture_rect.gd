@tool
extends "_base.gd"

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite TextureRect Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "tscn"
	_visible_name = "TextureRect"

	set_preset("Animation", [])

func _import_internal(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:

	var common_options: Common.Options = Common.Options.new(options)
	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

	return ERR_UNCONFIGURED
	# var common_options: Common.Options = Common.Options.new(options)

	# var png_path: String = source_file.get_basename() + ".png"
	# var global_png_path: String = ProjectSettings.globalize_path(png_path)
	# var output: Array = []
	# var err: Error = OS.execute(
	# 	ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME),
	# 	PackedStringArray([
	# 		"--batch",
	# 		"--filename-format", "{tag}{tagframe}",
	# 		"--format", "json-array",
	# 		"--list-tags",
	# 		"--ignore-empty",
	# 		"--trim",
	# 		"--inner-padding", "1" if common_options.extrude else "0",
	# 		"--sheet-type", "packed",
	# 		"--sheet", ProjectSettings.globalize_path(png_path),
	# 		ProjectSettings.globalize_path(source_file)
	# 	]), output, true)
	# var json = JSON.new()
	# json.parse(output[0])

	# var image = Image.load_from_file(global_png_path)

	# if common_options.extrude:
	# 	Common.extrude_edges_into_padding(image, json)
	# image.save_png(global_png_path)
	# image = null

	# # Эта функция не импортирует файл. Но ее вызов нужен для того, чтобы append прошел без ошибок
	# _parent_plugin.get_editor_interface().get_resource_filesystem().update_file(png_path)
	# append_import_external_resource(png_path, options, "texture")
	# gen_files.append(png_path)

	# # НУЖНО ИМЕННО ТАК. IGNORE!!!!!!!!!!!!
	# var texture: Texture2D = ResourceLoader.load(png_path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	# texture.emit_changed()

	# if json.data.meta.frameTags.is_empty():
	# 	var default_animation_name = "default"
	# 	if common_options.is_default_animation_looped:
	# 		match common_options.animation_looping_marker_position:
	# 			Common.MarkerPosition.PREFIX: default_animation_name = common_options.animation_looping_marker + default_animation_name
	# 			Common.MarkerPosition.SUFFIX: default_animation_name = default_animation_name + common_options.animation_looping_marker
	# 	json.data.meta.frameTags.push_back({
	# 		name = default_animation_name,
	# 		from = 0,
	# 		to = json.data.frames.size() - 1,
	# 		direction = Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS[common_options.default_animation_direction]
	# 	})

# 	var sprite_frames: SpriteFrames
# 	if ResourceLoader.exists(source_file):
# 		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
# 		sprite_frames = ResourceLoader.load(source_file, "SpriteFrames", ResourceLoader.CACHE_MODE_IGNORE) as SpriteFrames
# 	if not sprite_frames:
# 		sprite_frames = SpriteFrames.new()

# 	var unique_names = []
# 	for frame_tag in json.data.meta.frameTags:
# 		frame_tag.name = frame_tag.name.strip_edges().strip_escapes()
# 		if frame_tag.name.is_empty():
# 			push_error("Found empty tag name")
# 			return ERR_INVALID_DATA

# 		frame_tag.looped = false
# 		match common_options.animation_looping_marker_position:
# 			Common.MarkerPosition.PREFIX:
# 				if frame_tag.name.begins_with(common_options.animation_looping_marker):
# 					frame_tag.looped = true
# 					if common_options.trim_animation_looping_marker:
# 						frame_tag.name = frame_tag.name.trim_prefix(common_options.animation_looping_marker)
# 			Common.MarkerPosition.SUFFIX:
# 				if frame_tag.name.ends_with(common_options.animation_looping_marker):
# 					frame_tag.looped = true
# 					if common_options.trim_animation_looping_marker:
# 						frame_tag.name = frame_tag.name.trim_suffix(common_options.animation_looping_marker)

# 		if unique_names.has(frame_tag.name):
# 			push_error("Found duplicated tag name")
# 			return ERR_INVALID_DATA
# 		unique_names.append(frame_tag.name)

# 	var names = sprite_frames.get_animation_names()
# 	for name in names:
# 		if unique_names.has(name):
# 			sprite_frames.clear(name)
# 		else:
# 			sprite_frames.remove_animation(name)

# 	var atlas_textures = {}

# 	for frame_tag in json.data.meta.frameTags:
# 		var name = frame_tag.name
# 		if not sprite_frames.has_animation(name):
# 			sprite_frames.add_animation(name)
# 		sprite_frames.set_animation_loop(name, frame_tag.looped)
# 		var frame_indices = []
# 		for frame_index in range(frame_tag.from, frame_tag.to + 1):
# 			frame_indices.append(frame_index)
# 		match frame_tag.direction:
# 			"forward":
# 				pass
# 			"reverse":
# 				frame_indices.reverse()
# 			"pingpong":
# 				var l = frame_indices.size()
# 				if l > 2:
# 					for frame_index in range(frame_tag.to - 1, frame_tag.from, -1):
# 						frame_indices.append(frame_index)

# 		var frame_duration = null
# 		for frame_index in frame_indices:
# 			var frame_data = json.data.frames[frame_index]
# 			var frame = frame_data.frame
# 			var sprite_source_size = frame_data.spriteSourceSize
# 			var source_size = frame_data.sourceSize

# 			var key = Rect2i(frame.x, frame.y, frame.w, frame.h)
# 			var atlas_texture = atlas_textures.get(key)
# 			if atlas_texture == null:
# 				atlas_texture = AtlasTexture.new()
# 				atlas_texture.atlas = texture
# 				atlas_texture.region = key
# 				atlas_texture.margin = Rect2i(
# 					sprite_source_size.x, sprite_source_size.y,
# 					source_size.w - frame.w, source_size.h - frame.h)
# 				atlas_textures[key] = atlas_texture

# 			sprite_frames.add_frame(name, atlas_texture)
# 			if frame_duration == null:
# 				frame_duration = json.data.frames[frame_index].duration
# 		sprite_frames.set_animation_speed(name, 1000 / frame_duration)

# 	var status = ResourceSaver.save(
# 		sprite_frames,
# 		save_path + "." + _get_save_extension(),
# 		ResourceSaver.FLAG_COMPRESS)
# 	if status != OK:
# 		push_error("Can't save imported resource.", status)
# 	sprite_frames.emit_signal("changed")
# 	sprite_frames.emit_changed()
# 	return status

# func is_animation_looped(animation_name: String) -> bool:
# 	return true
# 	pass
