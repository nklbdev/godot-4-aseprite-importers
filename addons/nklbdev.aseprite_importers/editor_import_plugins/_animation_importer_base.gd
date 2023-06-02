@tool
extends EditorImportPlugin

const Common = preload("../common.gd")

func set_preset(name: StringName, options: Array[Dictionary]) -> void:
	var preset: Array[Dictionary] = []
	preset.append_array(_parent_plugin.common_options)
	preset.append_array(options)
	preset.append_array(_parent_plugin.texture_2d_options)
	__option_visibility_checkers.clear()
	for option in preset:
		var option_visibility_checker: Callable = option.get("get_is_visible", Common.EMPTY_CALLABLE)
		if option_visibility_checker != Common.EMPTY_CALLABLE:
			__option_visibility_checkers[option.name] = option_visibility_checker
	_presets[name] = preset

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
	var option_visibility_checker: Callable = __option_visibility_checkers.get(option_name, Common.EMPTY_CALLABLE)
	if option_visibility_checker:
		if option_visibility_checker == Common.EMPTY_CALLABLE:
			return true
		else:
			return option_visibility_checker.call(options)
	else:
		return true

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


class ExportResult:
	var raw_output: String
	var parsed_json: JSON
	var texture: Texture2D
	var spritesheet_metadata: SpritesheetMetadata

class FrameData:
	var region_rect: Rect2i
	var region_rect_offset: Vector2i
	var duration_ms: int

class AnimationTag:
	var name: String
	var frames: Array[FrameData]
	var duration_ms: int
	var looped: bool

class SpritesheetMetadata:
	var source_size: Vector2i
	var spritesheet_size: Vector2i
	var animation_tags: Array[AnimationTag]

class TrackFrame:
	var duration_ms: int
	var value: Variant
	func _init(duration_ms: int, value: Variant) -> void:
		self.duration_ms = duration_ms
		self.value = value

var __editor_filesystem: EditorFileSystem

const __sheet_types_by_spritesheet_layout: Dictionary = {
	Common.SpritesheetLayout.PACKED: "packed",
	Common.SpritesheetLayout.BY_ROWS: "rows",
	Common.SpritesheetLayout.BY_COLUMNS: "columns",
}

func _export_texture(source_file: String, options: Common.Options, image_options: Dictionary, gen_files: Array[String]) -> ExportResult:
	var spritesheet_metadata = SpritesheetMetadata.new()
	var png_path: String = source_file.get_basename() + ".png"
	var global_png_path: String = ProjectSettings.globalize_path(png_path)

	var aseprite_executable_path: String = ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME)
	if not FileAccess.file_exists(aseprite_executable_path):
		push_error("Cannot fild Aseprite executable. Check Aseprite executable path in project settings.")
		return null

	var variable_options: Array
	if options.spritesheet_layout == Common.SpritesheetLayout.BY_ROWS:
		variable_options += ["--sheet-columns", str(options.spritesheet_fixed_columns_count)]
	if options.spritesheet_layout == Common.SpritesheetLayout.BY_COLUMNS:
		variable_options += ["--sheet-rows", str(options.spritesheet_fixed_rows_count)]
	match options.border_type:
		Common.BorderType.Transparent: variable_options += ["--inner-padding", "1"]
		Common.BorderType.Extruded: variable_options += ["--extrude"]
		Common.BorderType.None: pass
		_: push_error("unexpected border type")
	if options.ignore_empty: variable_options += ["--ignore-empty"]
	if options.merge_duplicates: variable_options += ["--merge-duplicates"]
	if options.trim: variable_options += ["--trim" if options.spritesheet_layout == Common.SpritesheetLayout.PACKED else "--trim-sprite"]

	var command_line_params: PackedStringArray = PackedStringArray([
		"--batch",
		"--filename-format", "{tag}{tagframe}",
		"--format", "json-array",
		"--list-tags",
		"--trim" if options.spritesheet_layout == Common.SpritesheetLayout.PACKED else "--trim-sprite",
		"--sheet-type", __sheet_types_by_spritesheet_layout[options.spritesheet_layout],
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
	spritesheet_metadata.source_size = Vector2i(sourceSizeData.w, sourceSizeData.h)
	spritesheet_metadata.spritesheet_size = Vector2i(json.data.meta.size.w, json.data.meta.size.h)
	var frames_data: Array[FrameData]
	for frame_data in json.data.frames:
		var fd: FrameData = FrameData.new()
		fd.region_rect = Rect2i(
			frame_data.frame.x, frame_data.frame.y,
			frame_data.frame.w, frame_data.frame.h)
		fd.region_rect_offset = Vector2i(
			frame_data.spriteSourceSize.x, frame_data.spriteSourceSize.y)
		if options.border_type == Common.BorderType.Transparent:
			fd.region_rect = fd.region_rect.grow(-1)
			fd.region_rect_offset += Vector2i.ONE
		fd.duration_ms = frame_data.duration
		frames_data.append(fd)

	var tags_data: Array = json.data.meta.frameTags
	var unique_names: Array[String] = []
	if tags_data.is_empty():
		var default_animation_tag = AnimationTag.new()
		default_animation_tag.name = options.default_animation_name
		if options.default_animation_repeat_count > 0:
			for cycle_index in options.default_animation_repeat_count:
				default_animation_tag.frames.append_array(frames_data)
		else:
			default_animation_tag.frames = frames_data
			default_animation_tag.looped = true
		spritesheet_metadata.animation_tags.append(default_animation_tag)
	else:
		for tag_data in tags_data:
			var animation_tag = AnimationTag.new()
			animation_tag.name = tag_data.name.strip_edges().strip_escapes()
			if animation_tag.name.is_empty():
				push_error("Found empty tag name")
				return null
			if unique_names.has(animation_tag.name):
				push_error("Found duplicated tag name")
				return null
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
			spritesheet_metadata.animation_tags.append(animation_tag)

	var image = Image.load_from_file(global_png_path)
	image.save_png(global_png_path)
	image = null

	# This function does not import the file. But its call is needed
	# so that the call to the "append" function passes without errors
	_parent_plugin.get_editor_interface().get_resource_filesystem().update_file(png_path)
	append_import_external_resource(png_path, image_options, "texture")
	gen_files.append(png_path)

	# This is a working way to reuse a previously imported resource. Don't change it!
	var texture: Texture2D = ResourceLoader.load(png_path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE) as Texture2D

	var export_result = ExportResult.new()
	export_result.texture = texture
	export_result.raw_output = output[0]
	export_result.parsed_json = json
	export_result.spritesheet_metadata = spritesheet_metadata
	return export_result

static func _create_animation_player(
	spritesheet_metadata: SpritesheetMetadata,
	track_value_getters_by_property_path: Dictionary,
	animation_autoplay_name: String = ""
	) -> AnimationPlayer:
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	var animation_library: AnimationLibrary = AnimationLibrary.new()

	for animation_tag in spritesheet_metadata.animation_tags:
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
