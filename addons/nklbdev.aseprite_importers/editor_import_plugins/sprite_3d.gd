extends "_animation_importer_base.gd"

const OPTION_SPRITE3D_CENTERED: String = "sprite3d/centered"

const OPTION_PACKED_SPRITE_SHEET_ANIMATION_STRATEGY: String = "animation/strategy_(packed_sprite_sheet)"

const PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET: String = "Animate sprite's region and offset"
const PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN: String = "Animate single atlas texture's region and margin"
const PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES: String = "Animate multiple atlas texture instances"

const PACKED_SPRITE_SHEET_ANIMATION_STRATEGIES: PackedStringArray = [
	PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET,
	PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN,
	PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES,
]

enum PackedSpriteSheetAnimationStrategy
{
	SpriteRegionAndOffset = 0,
	TextureRegionAndMargin = 1,
	TextureInstances = 2
}



const OPTION_GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY: String = "animation/strategy_(grid-based_sprite_sheet)"

const GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_REGION: String = "Animate sprite's region"
const GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_FRAME_INDEX: String = "Animate sprite's frame index"
const GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_FRAME_COORDS: String = "Animate sprite's frame coords"
const GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_REGION: String = "Animate single atlas texture's region"
const GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES: String = "Animate multiple atlas texture instances"

const GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGIES: PackedStringArray = [
	GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_REGION,
	GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_FRAME_INDEX,
	GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_FRAME_COORDS,
	GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_REGION,
	GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES,
]

enum GridBasedSpriteSheetAnimationStrategy
{
	SpriteRegion = 0,
	SpriteFrameIndex = 1,
	SpriteFrameCoords = 2,
	TextureRegion = 3,
	TextureInstances = 4
}

class Sprite3DParsedAnimationOptions:
	extends Common.ParsedAnimationOptions
	var centered: bool
	var packed_animation_strategy: PackedSpriteSheetAnimationStrategy
	var grid_based_animation_strategy: GridBasedSpriteSheetAnimationStrategy
	func _init(options: Dictionary) -> void:
		packed_animation_strategy = PACKED_SPRITE_SHEET_ANIMATION_STRATEGIES \
			.find(options[OPTION_PACKED_SPRITE_SHEET_ANIMATION_STRATEGY])
		grid_based_animation_strategy = GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGIES \
			.find(options[OPTION_GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY])
		super(options)


func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite Sprite3D Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "scn"
	_visible_name = "Sprite3D (with AnimationPlayer)"

	set_preset("Animation", [
		Common.create_option(OPTION_SPRITE3D_CENTERED, true, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR),
		Common.create_option(
			OPTION_PACKED_SPRITE_SHEET_ANIMATION_STRATEGY,
			PACKED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET,
			PROPERTY_HINT_ENUM, ",".join(PACKED_SPRITE_SHEET_ANIMATION_STRATEGIES),
			PROPERTY_USAGE_EDITOR,
			func (options:Dictionary) -> bool:
				return options[Common.OPTION_SPRITE_SHEET_LAYOUT] == Common.SPRITE_SHEET_LAYOUTS[Common.SpriteSheetLayout.PACKED]),
		Common.create_option(
			OPTION_GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY,
			GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGY_SPRITE_REGION,
			PROPERTY_HINT_ENUM, ",".join(GRID_BASED_SPRITE_SHEET_ANIMATION_STRATEGIES),
			PROPERTY_USAGE_EDITOR,
			func (options:Dictionary) -> bool:
				return options[Common.OPTION_SPRITE_SHEET_LAYOUT] != Common.SPRITE_SHEET_LAYOUTS[Common.SpriteSheetLayout.PACKED]),
	])

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var status: Error = OK
	var sprite_sheet_options = Common.ParsedSpriteSheetOptions.new(options)
	var animation_options = Common.ParsedAnimationOptions.new(options)
	var sprite_sheet_export_result: SpriteSheetExportResult = _export_sprite_sheet(source_file, sprite_sheet_options)
	var animation_tags: Array[AnimationTag] = _parse_animation_tags(sprite_sheet_export_result, animation_options)

	var centered = options[OPTION_SPRITE3D_CENTERED]

	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = source_file.get_file().get_basename()
	sprite.texture = sprite_sheet_export_result.texture
	sprite.centered = centered

	var autoplay: String = animation_options.animation_autoplay_name
	var animation_player: AnimationPlayer
	match sprite_sheet_options.sprite_sheet_layout:
		Common.SpriteSheetLayout.PACKED:
			match animation_options.packed_animation_strategy:

				PackedSpriteSheetAnimationStrategy.SpriteRegionAndOffset:
					sprite.region_enabled = true
					animation_player = _create_animation_player(animation_tags, {
						".:offset": func (frame_data: FrameData) -> Vector2:
							return Vector2( # spatial sprite offset (the Y-axis is Up-directed)
								frame_data.region_rect_offset.x,
								sprite_sheet_export_result.source_size.y -
								frame_data.region_rect_offset.y -
								frame_data.region_rect.size.y) + \
								# add center correction
								((frame_data.region_rect.size - sprite_sheet_export_result.source_size) * 0.5
								if centered else Vector2.ZERO),
						".:region_rect" : func (frame_data: FrameData) -> Rect2i:
							return frame_data.region_rect },
						autoplay)

				PackedSpriteSheetAnimationStrategy.TextureRegionAndMargin:
					var atlas_texture: AtlasTexture = AtlasTexture.new()
					atlas_texture.filter_clip = true
					atlas_texture.resource_local_to_scene = true
					atlas_texture.atlas = sprite.texture
					sprite.texture = atlas_texture
					animation_player = _create_animation_player(animation_tags, {
						".:texture:margin": func (frame_data: FrameData) -> Rect2:
							return Rect2(frame_data.region_rect_offset, sprite_sheet_export_result.source_size - frame_data.region_rect.size),
						".:texture:region" : func (frame_data: FrameData) -> Rect2i:
							return  frame_data.region_rect },
						animation_options.animation_autoplay_name)

				PackedSpriteSheetAnimationStrategy.TextureInstances:
					var texture_cache: Array[AtlasTexture]
					animation_player = _create_animation_player(animation_tags, {
						".:texture": func (frame_data: FrameData) -> Texture2D:
							var margin = Rect2(frame_data.region_rect_offset, sprite_sheet_export_result.source_size - frame_data.region_rect.size)
							var region = Rect2(frame_data.region_rect)
							var cached_result = texture_cache.filter(func (t: AtlasTexture) -> bool: return t.margin == margin and t.region == region)
							var texture: AtlasTexture
							if not cached_result.is_empty():
								return cached_result.front()
							texture = AtlasTexture.new()
							texture.atlas = sprite_sheet_export_result.texture
							texture.filter_clip = true
							texture.margin = margin
							texture.region = region
							texture_cache.append(texture)
							return texture},
						autoplay)

		Common.SpriteSheetLayout.BY_ROWS, Common.SpriteSheetLayout.BY_COLUMNS:
			match animation_options.grid_based_animation_strategy:

				GridBasedSpriteSheetAnimationStrategy.SpriteRegion:
					sprite.region_enabled = true
					var random_frame_data: FrameData = animation_tags[0].frames[0]
					sprite.offset = random_frame_data.region_rect_offset + \
						((random_frame_data.region_rect.size - sprite_sheet_export_result.source_size) if centered else Vector2i.ZERO) / 2
					animation_player = _create_animation_player(animation_tags, {
						".:region_rect" : func (frame_data: FrameData) -> Rect2i:
							return frame_data.region_rect },
						autoplay)

				GridBasedSpriteSheetAnimationStrategy.SpriteFrameIndex:
					var random_frame_data: FrameData = animation_tags[0].frames[0]
					var grid_cell_size: Vector2i = random_frame_data.region_rect.size
					if sprite_sheet_options.border_type == Common.BorderType.Extruded:
						grid_cell_size += Vector2i.ONE * 2
					sprite.hframes = sprite_sheet_export_result.sprite_sheet_size.x / grid_cell_size.x
					sprite.vframes = sprite_sheet_export_result.sprite_sheet_size.y / grid_cell_size.y
					animation_player = _create_animation_player(animation_tags, {
						".:frame": func (frame_data: FrameData) -> int:
							var frame_coords: Vector2i = frame_data.region_rect.position / grid_cell_size
							match sprite_sheet_options.sprite_sheet_layout:
								Common.SpriteSheetLayout.BY_ROWS:
									return sprite_sheet_options.sprite_sheet_fixed_columns_count * frame_coords.y + frame_coords.x
								Common.SpriteSheetLayout.BY_COLUMNS:
									return sprite_sheet_options.sprite_sheet_fixed_rows_count * frame_coords.x + frame_coords.y
							push_error("Unexpected sprite sheet layout type")
							return 0 },
						autoplay)

				GridBasedSpriteSheetAnimationStrategy.SpriteFrameCoords:
					var random_frame_data: FrameData = animation_tags[0].frames[0]
					var grid_cell_size: Vector2i = random_frame_data.region_rect.size
					if sprite_sheet_options.border_type == Common.BorderType.Extruded:
						grid_cell_size += Vector2i.ONE * 2
					sprite.hframes = sprite_sheet_export_result.sprite_sheet_size.x / grid_cell_size.x
					sprite.vframes = sprite_sheet_export_result.sprite_sheet_size.y / grid_cell_size.y
					animation_player = _create_animation_player(animation_tags, {
						".:frame_coords": func (frame_data: FrameData) -> Vector2i:
							return frame_data.region_rect.position / grid_cell_size },
						autoplay)

				GridBasedSpriteSheetAnimationStrategy.TextureRegion:
					var random_frame_data: FrameData = animation_tags[0].frames[0]
					var atlas_texture = AtlasTexture.new()
					atlas_texture.atlas = sprite_sheet_export_result.texture
					atlas_texture.filter_clip = true
					atlas_texture.resource_local_to_scene = true
					atlas_texture.margin = Rect2(random_frame_data.region_rect_offset, sprite_sheet_export_result.source_size - random_frame_data.region_rect.size)
					sprite.texture = atlas_texture
					animation_player = _create_animation_player(animation_tags, {
						".:texture:region" : func (frame_data: FrameData) -> Rect2i:
							return  frame_data.region_rect },
						autoplay)

				GridBasedSpriteSheetAnimationStrategy.TextureInstances:
					var texture_cache: Array[AtlasTexture]
					animation_player = _create_animation_player(animation_tags, {
						".:texture": func (frame_data: FrameData) -> Texture2D:
							var region = Rect2(frame_data.region_rect)
							var cached_result = texture_cache.filter(func (t: AtlasTexture) -> bool: return t.region == region)
							var texture: AtlasTexture
							if not cached_result.is_empty():
								return cached_result.front()
							texture = AtlasTexture.new()
							texture.atlas = sprite_sheet_export_result.texture
							texture.filter_clip = true
							texture.region = region
							texture_cache.append(texture)
							return texture},
						autoplay)

	sprite.add_child(animation_player)
	animation_player.owner = sprite

	var packed_scene: PackedScene
	if ResourceLoader.exists(source_file):
		# This is a working way to reuse a previously imported resource. Don't change it!
		packed_scene = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if not packed_scene:
		packed_scene = PackedScene.new()

	packed_scene.pack(sprite)

	status = ResourceSaver.save(
		packed_scene,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS)
	if status: push_error("Can't save imported resource.", status)

	return status
