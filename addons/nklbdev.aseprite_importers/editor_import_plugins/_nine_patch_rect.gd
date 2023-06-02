# @tool
# extends "_base.gd"

# const OPTION_CENTERED: String = "sprite2d/centered"

# func _init(parent_plugin: EditorPlugin) -> void:
# 	super(parent_plugin)
# 	_import_order = 0
# 	_importer_name = "Aseprite NinePatchRect Import"
# 	_priority = 1
# 	_recognized_extensions = ["ase", "aseprite"]
# 	_resource_type = "PackedScene"
# 	_save_extension = "scn"
# 	_visible_name = "NinePatchRect"

# 	set_preset("Animation", [
# 		Common.create_option(OPTION_CENTERED, PROPERTY_HINT_NONE, "", true, PROPERTY_USAGE_EDITOR)
# 	])


# func _import(source_file: String, save_path: String, options: Dictionary,
# 	platform_variants: Array[String], gen_files: Array[String]) -> Error:
# 	var status: Error

# 	var common_options: Common.Options = Common.Options.new(options)
# 	var centered = options[OPTION_CENTERED]
# 	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
# 	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

# 	var nine_patch_rect: NinePatchRect = NinePatchRect.new()
# 	nine_patch_rect.name = source_file.get_file().get_basename()
# 	nine_patch_rect.texture = texture
# #	sprite.centered = centered
# #	sprite.region_enabled = true
# 	var animation_player: AnimationPlayer = AnimationPlayer.new()
# 	animation_player.name = "AnimationPlayer"
# 	nine_patch_rect.add_child(animation_player)
# 	animation_player.owner = nine_patch_rect

# 	var animation_library: AnimationLibrary = AnimationLibrary.new()
# 	var animation_index = 0
# 	for frame_tag_data in json.data.meta.frameTags:
# 		var animation_direction: Common.AnimationDirection = Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS.find(frame_tag_data.direction)
# 		var animation: Animation = Animation.new()
# 		var offset_track_index: int = 0
# 		var region_rect_track_index: int = 1
# 		animation.add_track(Animation.TYPE_VALUE)
# 		animation.add_track(Animation.TYPE_VALUE)
# 		animation.track_set_path(offset_track_index, ".:offset")
# 		animation.track_set_path(region_rect_track_index, ".:region_rect")
# 		animation.value_track_set_update_mode(offset_track_index, Animation.UPDATE_DISCRETE)
# 		animation.value_track_set_update_mode(region_rect_track_index, Animation.UPDATE_DISCRETE)
# 		animation.track_set_interpolation_loop_wrap(offset_track_index, false)
# 		animation.track_set_interpolation_loop_wrap(region_rect_track_index, false)
# 		animation.track_set_interpolation_type(offset_track_index, Animation.INTERPOLATION_NEAREST)
# 		animation.track_set_interpolation_type(region_rect_track_index, Animation.INTERPOLATION_NEAREST)

# 		var transition: float = 1
# 		var forward_time_ms: int = 0
# 		var previous_offset: Variant = null
# 		var previous_region_rect: Variant = null
# 		var animation_length_ms: int = 0
# 		var first_frame_time_ms: int = json.data.frames[frame_tag_data.from].duration
# 		var last_frame_time_ms: int
# 		for frame_index in range(frame_tag_data.from, frame_tag_data.to + 1):
# 			var frame_data = json.data.frames[frame_index]
# 			last_frame_time_ms = frame_data.duration
# 			animation_length_ms += last_frame_time_ms
# 		if animation_direction == Common.AnimationDirection.PING_PONG:
# 			animation_length_ms *= 2
# 			animation_length_ms -= last_frame_time_ms
# 		var add_forward_animation_key: bool = animation_direction != Common.AnimationDirection.REVERSE
# 		var add_reverse_animation_key: bool = animation_direction != Common.AnimationDirection.FORWARD
# 		for frame_index in range(frame_tag_data.from, frame_tag_data.to + 1):
# 			var frame_data: Dictionary = json.data.frames[frame_index]
# 			var region_rect: Rect2i = Rect2(frame_data.frame.x, frame_data.frame.y, frame_data.frame.w, frame_data.frame.h)

# 			var offset: Vector2
# 			if centered:
# 				var frame_center = Vector2(frame_data.sourceSize.w / 2.0, frame_data.sourceSize.h / 2.0)
# 				var frame_region_center: Vector2 = Vector2(
# 					frame_data.spriteSourceSize.x + frame_data.spriteSourceSize.w / 2.0,
# 					frame_data.spriteSourceSize.y + frame_data.spriteSourceSize.h / 2.0)
# 				offset = frame_region_center - frame_center
# 			else:
# 				offset = Vector2(frame_data.spriteSourceSize.x, frame_data.spriteSourceSize.y)

# 			var is_frame_pingpong_edge = \
# 				animation_direction == Common.AnimationDirection.PING_PONG and \
# 				(frame_index == frame_tag_data.from or frame_index == frame_tag_data.to)
# 			var reversed_time_ms: float = animation_length_ms - forward_time_ms - frame_data.duration
# 			if offset != previous_offset:
# 				if add_forward_animation_key:
# 					animation.track_insert_key(offset_track_index, forward_time_ms * 0.001, offset, transition)
# 				if add_reverse_animation_key and not is_frame_pingpong_edge:
# 					animation.track_insert_key(offset_track_index, reversed_time_ms * 0.001, offset, transition)
# 			if region_rect != previous_region_rect:
# 				if add_forward_animation_key:
# 					animation.track_insert_key(region_rect_track_index, forward_time_ms * 0.001, region_rect, transition)
# 				if add_reverse_animation_key and not is_frame_pingpong_edge:
# 					animation.track_insert_key(region_rect_track_index, reversed_time_ms * 0.001, region_rect, transition)

# 			previous_offset = offset
# 			previous_region_rect = region_rect
# 			forward_time_ms += frame_data.duration
# 		if animation_direction == Common.AnimationDirection.PING_PONG:
# 			animation_length_ms -= first_frame_time_ms
# 		animation.length = animation_length_ms * 0.001
# 		animation.loop_mode = Animation.LOOP_LINEAR
# 		animation_library.add_animation(frame_tag_data.name, animation)
# 		animation_index += 1
# 	animation_player.add_animation_library("", animation_library)

# 	var packed_sprite: PackedScene
# 	if ResourceLoader.exists(source_file):
# 		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
# 		packed_sprite = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
# 	if not packed_sprite:
# 		packed_sprite = PackedScene.new()

# 	packed_sprite.pack(nine_patch_rect)

# 	status = ResourceSaver.save(
# 		packed_sprite,
# 		save_path + "." + _get_save_extension(),
# 		ResourceSaver.FLAG_COMPRESS)
# 	if status: push_error("Can't save imported resource.", status)

# 	packed_sprite.emit_changed()
# 	return status
