extends "_animation_importer_base.gd"


const OPTION_PACKED_SPRITESHEET_ANIMATION_STRATEGY: String = "animation/strategy_(packed_spritesheet)"

const PACKED_SPRITESHEET_ANIMATION_STRATEGIES: PackedStringArray = [
	"Animate single atlas texture's region and margin",
	"Animate multiple atlas texture instances",
]

enum PackedSpritesheetAnimationStrategy
{
	TextureRegionAndMargin = 0,
	TextureInstances = 1
}


const OPTION_GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY: String = "animation/strategy_(grid-based_spritesheet)"

const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGIES: PackedStringArray = [
	"Animate single atlas texture's region",
	"Animate multiple atlas texture instances",
]

enum GridBasedSpritesheetAnimationStrategy
{
	TextureRegion = 0,
	TextureInstances = 1
}

class TextureRectParsedAnimationOptions:
	extends Common.ParsedAnimationOptions
	var centered: bool
	var packed_animation_strategy: PackedSpritesheetAnimationStrategy
	var grid_based_animation_strategy: GridBasedSpritesheetAnimationStrategy
	func _init(options: Dictionary) -> void:
		packed_animation_strategy = PACKED_SPRITESHEET_ANIMATION_STRATEGIES \
			.find(options[OPTION_PACKED_SPRITESHEET_ANIMATION_STRATEGY])
		grid_based_animation_strategy = GRID_BASED_SPRITESHEET_ANIMATION_STRATEGIES \
			.find(options[OPTION_GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY])
		super(options)



func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite TextureRect Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "scn"
	_visible_name = "TextureRect (with AnimationPlayer)"

	set_preset("Animation", [
		Common.create_option(
			OPTION_PACKED_SPRITESHEET_ANIMATION_STRATEGY,
			PackedSpritesheetAnimationStrategy.TextureRegionAndMargin,
			PROPERTY_HINT_ENUM, ",".join(PACKED_SPRITESHEET_ANIMATION_STRATEGIES),
			PROPERTY_USAGE_EDITOR,
			func (options:Dictionary) -> bool:
				return options[Common.OPTION_SPRITESHEET_LAYOUT] == Common.SpritesheetLayout.PACKED),
		Common.create_option(
			OPTION_GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY,
			GridBasedSpritesheetAnimationStrategy.TextureRegion,
			PROPERTY_HINT_ENUM, ",".join(GRID_BASED_SPRITESHEET_ANIMATION_STRATEGIES),
			PROPERTY_USAGE_EDITOR,
			func (options:Dictionary) -> bool:
				return options[Common.OPTION_SPRITESHEET_LAYOUT] != Common.SpritesheetLayout.PACKED),
	])


func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var status: Error = OK
	var parsed_options: TextureRectParsedAnimationOptions = TextureRectParsedAnimationOptions.new(options)
	var export_result: ExportResult = _export_texture(source_file, parsed_options, options, gen_files)
	if export_result.error:
		push_error("There was an error during exporting texture: %s with message: %s" %
			[error_string(export_result.error), export_result.error_message])
		return export_result.error

	var frame_size: Vector2i = export_result.spritesheet_metadata.source_size

	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = export_result.texture
	atlas_texture.filter_clip = true
	atlas_texture.resource_local_to_scene = true
	# for TextureRect, AtlasTexture must have region with area
	# we gave it frame size and negative position to avoid to show any visible pixel of the texture
	atlas_texture.region = Rect2(-frame_size - Vector2i.ONE, frame_size)

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.name = source_file.get_file().get_basename()
	texture_rect.texture = atlas_texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.size = frame_size





	var ssmd: SpritesheetMetadata = export_result.spritesheet_metadata
	var autoplay: String = parsed_options.animation_autoplay_name
	var animation_player: AnimationPlayer
	match parsed_options.spritesheet_layout:
		Common.SpritesheetLayout.PACKED:
			match parsed_options.packed_animation_strategy:

				PackedSpritesheetAnimationStrategy.TextureRegionAndMargin:
					animation_player = _create_animation_player(ssmd, {
						".:texture:margin": func (frame_data: FrameData) -> Rect2:
							return Rect2(frame_data.region_rect_offset, ssmd.source_size - frame_data.region_rect.size),
						".:texture:region" : func (frame_data: FrameData) -> Rect2i:
							return  frame_data.region_rect },
						parsed_options.animation_autoplay_name)

				PackedSpritesheetAnimationStrategy.TextureInstances:
					var texture_cache: Array[AtlasTexture]
					animation_player = _create_animation_player(ssmd, {
						".:texture": func (frame_data: FrameData) -> Texture2D:
							var margin = Rect2(frame_data.region_rect_offset, ssmd.source_size - frame_data.region_rect.size)
							var region = Rect2(frame_data.region_rect)
							var cached_result = texture_cache.filter(func (t: AtlasTexture) -> bool: return t.margin == margin and t.region == region)
							var texture: AtlasTexture
							if not cached_result.is_empty():
								return cached_result.front()
							texture = AtlasTexture.new()
							texture.atlas = export_result.texture
							texture.filter_clip = true
							texture.margin = margin
							texture.region = region
							texture_cache.append(texture)
							return texture},
						autoplay)

		Common.SpritesheetLayout.BY_ROWS, Common.SpritesheetLayout.BY_COLUMNS:
			match parsed_options.grid_based_animation_strategy:

				GridBasedSpritesheetAnimationStrategy.TextureRegion:
					var random_frame_data: FrameData = ssmd.animation_tags[0].frames[0]
					atlas_texture.margin = Rect2(random_frame_data.region_rect_offset, random_frame_data.region_rect_offset * 2)
					animation_player = _create_animation_player(ssmd, {
						".:texture:region" : func (frame_data: FrameData) -> Rect2i:
							return  frame_data.region_rect },
						autoplay)

				GridBasedSpritesheetAnimationStrategy.TextureInstances:
					var random_frame_data: FrameData = ssmd.animation_tags[0].frames[0]
					var common_atlas_texture_margin: Rect2 = Rect2(
						random_frame_data.region_rect_offset,
						ssmd.source_size - random_frame_data.region_rect.size)
					var texture_cache: Array[AtlasTexture]
					animation_player = _create_animation_player(ssmd, {
						".:texture": func (frame_data: FrameData) -> Texture2D:
							var region = Rect2(frame_data.region_rect)
							var cached_result = texture_cache.filter(func (t: AtlasTexture) -> bool: return t.region == region)
							var texture: AtlasTexture
							if not cached_result.is_empty():
								return cached_result.front()
							texture = AtlasTexture.new()
							texture.atlas = export_result.texture
							texture.filter_clip = true
							texture.region = region
							texture.margin = common_atlas_texture_margin
							texture_cache.append(texture)
							return texture},
						autoplay)

	texture_rect.add_child(animation_player)
	animation_player.owner = texture_rect

	var packed_scene: PackedScene
	if ResourceLoader.exists(source_file):
		# This is a working way to reuse a previously imported resource. Don't change it!
		packed_scene = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if not packed_scene:
		packed_scene = PackedScene.new()

	packed_scene.pack(texture_rect)

	status = ResourceSaver.save(
		packed_scene,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_BUNDLE_RESOURCES)
	if status: push_error("Can't save imported resource.", status)

	return status
