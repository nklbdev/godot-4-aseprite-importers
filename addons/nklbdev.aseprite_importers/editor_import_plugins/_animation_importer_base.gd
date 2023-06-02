extends "_sprite_sheet_importer_base.gd"

# Base class for all nested animation import plugins

func set_preset(name: StringName, options: Array[Dictionary]) -> void:
	var combined_options: Array[Dictionary] = _parent_plugin.common_animation_options.duplicate()
	combined_options.append_array(options)
	super.set_preset(name, combined_options)

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)

class FrameData:
	var region_rect: Rect2i
	var region_rect_offset: Vector2i
	var duration_ms: int

class AnimationTag:
	var name: String
	var frames: Array[FrameData]
	var duration_ms: int
	var looped: bool

class SpriteSheetMetadata:
	var source_size: Vector2i
	var sprite_sheet_size: Vector2i
	var animation_tags: Array[AnimationTag]

class TrackFrame:
	var duration_ms: int
	var value: Variant
	func _init(duration_ms: int, value: Variant) -> void:
		self.duration_ms = duration_ms
		self.value = value

func _parse_animation_tags(sprite_sheet_export_result: SpriteSheetExportResult, animation_options: Common.ParsedAnimationOptions) -> Array[AnimationTag]:
	var frames_data: Array[FrameData]
	for frame_data in sprite_sheet_export_result.parsed_json.data.frames:
		var fd: FrameData = FrameData.new()
		fd.region_rect = Rect2i(
			frame_data.frame.x, frame_data.frame.y,
			frame_data.frame.w, frame_data.frame.h)
		fd.region_rect_offset = Vector2i(
			frame_data.spriteSourceSize.x, frame_data.spriteSourceSize.y)
		if sprite_sheet_export_result.border_type == Common.BorderType.Transparent:
			fd.region_rect = fd.region_rect.grow(-1)
			fd.region_rect_offset += Vector2i.ONE
		fd.duration_ms = frame_data.duration
		frames_data.append(fd)

	var tags_data: Array = sprite_sheet_export_result.parsed_json.data.meta.frameTags
	var unique_names: Array[String] = []
	var animation_tags: Array[AnimationTag] = []
	if tags_data.is_empty():
		var default_animation_tag = AnimationTag.new()
		default_animation_tag.name = animation_options.default_animation_name
		if animation_options.default_animation_repeat_count > 0:
			for cycle_index in animation_options.default_animation_repeat_count:
				default_animation_tag.frames.append_array(frames_data)
		else:
			default_animation_tag.frames = frames_data
			default_animation_tag.looped = true
		animation_tags.append(default_animation_tag)
	else:
		for tag_data in tags_data:
			var animation_tag = AnimationTag.new()
			animation_tag.name = tag_data.name.strip_edges().strip_escapes()
			if animation_tag.name.is_empty():
				push_error("Found empty tag name")
				return []
			if unique_names.has(animation_tag.name):
				push_error("Found duplicated tag name")
				return []
			unique_names.append(animation_tag.name)

			var animation_direction = Common.ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS.find(tag_data.direction)
			var animation_frames: Array = frames_data.slice(tag_data.from, tag_data.to + 1)
			# Apply animation direction
			if animation_direction & Common.AnimationDirection.REVERSE > 0:
				animation_frames.reverse()
			if animation_direction & Common.AnimationDirection.PING_PONG > 0:
				if animation_frames.size() > 2:
					animation_frames += animation_frames.slice(-2, 0, -1)

			var repeat_count: int = int(tag_data.get("repeat", "0"))
			if repeat_count > 0:
				for cycle_index in repeat_count:
					animation_tag.frames.append_array(animation_frames)
			else:
				animation_tag.frames.append_array(animation_frames)
				animation_tag.looped = true
			animation_tags.append(animation_tag)

	return animation_tags


static func _create_animation_player(
	animation_tags: Array[AnimationTag],
	track_value_getters_by_property_path: Dictionary,
	animation_autoplay_name: String = ""
	) -> AnimationPlayer:
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	var animation_library: AnimationLibrary = AnimationLibrary.new()

	for animation_tag in animation_tags:
		var animation: Animation = Animation.new()
		for property_path in track_value_getters_by_property_path.keys():
			__create_track(animation, property_path,
				animation_tag, track_value_getters_by_property_path[property_path])

		animation.length = animation_tag.frames.reduce(
			func (accum: int, frame_data: FrameData):
				return accum + frame_data.duration_ms, 0) * 0.001

		animation.loop_mode = Animation.LOOP_LINEAR if animation_tag.looped else Animation.LOOP_NONE
		animation_library.add_animation(animation_tag.name, animation)
	animation_player.add_animation_library("", animation_library)

	if not animation_autoplay_name.is_empty():
		if animation_player.has_animation(animation_autoplay_name):
			animation_player.autoplay = animation_autoplay_name
		else:
			push_warning("Not found animation to set autoplay with name \"%s\"" %
				animation_autoplay_name)

	return animation_player

static func __create_track(
	animation: Animation,
	property_path: NodePath,
	animation_tag: AnimationTag,
	track_value_getter: Callable # func(fd: FrameData) -> Variant for each fd in animation_tag.frames
	) -> int:
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, property_path)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_loop_wrap(track_index, false)
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
	var track_frames = animation_tag.frames.map(
		func (frame_data: FrameData):
			return TrackFrame.new(
				frame_data.duration_ms,
				track_value_getter.call(frame_data)))

	var transition: float = 1
	var track_length_ms: int = 0
	var previous_track_frame: TrackFrame = null
	for track_frame in track_frames:
		if previous_track_frame == null or track_frame.value != previous_track_frame.value:
			animation.track_insert_key(track_index,
				track_length_ms * 0.001, track_frame.value, transition)
		previous_track_frame = track_frame
		track_length_ms += track_frame.duration_ms

	return track_index
