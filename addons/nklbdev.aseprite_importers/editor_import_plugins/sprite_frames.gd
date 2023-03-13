@tool
extends "_base.gd"

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite SpriteFrames Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "SpriteFrames"
	_save_extension = "res"
	_visible_name = "SpriteFrames"

	set_preset("Animation", [])

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:

	var common_options: Common.Options = Common.Options.new(options)
	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

	_add_default_tag_if_needed(json, common_options)

	var sprite_frames: SpriteFrames
	if ResourceLoader.exists(source_file):
		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
		sprite_frames = ResourceLoader.load(source_file, "SpriteFrames", ResourceLoader.CACHE_MODE_IGNORE) as SpriteFrames
	if not sprite_frames:
		sprite_frames = SpriteFrames.new()

	var e: Error = update_sprite_frames(json, common_options, texture, sprite_frames)
	if e:
		push_error("Cannot update SpriteFrames", e)
		return e

	var status = ResourceSaver.save(
		sprite_frames,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS)
	if status != OK:
		push_error("Can't save imported resource.", status)
	sprite_frames.emit_changed()
	return status

static func update_sprite_frames(json: JSON, common_options: Common.Options, texture: Texture2D, sprite_frames: SpriteFrames) -> Error:
	var unique_names = []
	for frame_tag in json.data.meta.frameTags:
		frame_tag.name = frame_tag.name.strip_edges().strip_escapes()
		if frame_tag.name.is_empty():
			push_error("Found empty tag name")
			return ERR_INVALID_DATA

		frame_tag.looped = false
		match common_options.animation_looping_marker_position:
			Common.MarkerPosition.PREFIX:
				if frame_tag.name.begins_with(common_options.animation_looping_marker):
					frame_tag.looped = true
					if common_options.trim_animation_looping_marker:
						frame_tag.name = frame_tag.name.trim_prefix(common_options.animation_looping_marker)
			Common.MarkerPosition.SUFFIX:
				if frame_tag.name.ends_with(common_options.animation_looping_marker):
					frame_tag.looped = true
					if common_options.trim_animation_looping_marker:
						frame_tag.name = frame_tag.name.trim_suffix(common_options.animation_looping_marker)

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

	for frame_tag in json.data.meta.frameTags:
		var name = frame_tag.name
		if not sprite_frames.has_animation(name):
			sprite_frames.add_animation(name)
		sprite_frames.set_animation_loop(name, frame_tag.looped)
		var frame_indices = []
		for frame_index in range(frame_tag.from, frame_tag.to + 1):
			frame_indices.append(frame_index)
		match frame_tag.direction:
			Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS[Common.AnimationDirection.FORWARD]:
				pass
			Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS[Common.AnimationDirection.REVERSE]:
				frame_indices.reverse()
			Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS[Common.AnimationDirection.PING_PONG]:
				var l = frame_indices.size()
				if l > 2:
					for frame_index in range(frame_tag.to - 1, frame_tag.from, -1):
						frame_indices.append(frame_index)

		var frame_duration = null
		for frame_index in frame_indices:
			var frame_data = json.data.frames[frame_index]
			var frame = frame_data.frame
			var sprite_source_size = frame_data.spriteSourceSize
			var source_size = frame_data.sourceSize

			var key = Rect2i(frame.x, frame.y, frame.w, frame.h)
			var atlas_texture = atlas_textures.get(key)
			if atlas_texture == null:
				atlas_texture = AtlasTexture.new()
				atlas_texture.atlas = texture
				atlas_texture.region = key
				atlas_texture.margin = Rect2i(
					sprite_source_size.x, sprite_source_size.y,
					source_size.w - frame.w, source_size.h - frame.h)
				atlas_textures[key] = atlas_texture

			sprite_frames.add_frame(name, atlas_texture)
			if frame_duration == null:
				frame_duration = json.data.frames[frame_index].duration
		sprite_frames.set_animation_speed(name, 1000 / frame_duration)
	return OK