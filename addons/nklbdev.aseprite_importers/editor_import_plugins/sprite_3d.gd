@tool
extends "_animation_importer_base.gd"

const OPTION_SPRITE3D_CENTERED: String = "sprite3d/centered"

const OPTION_PACKED_SPRITESHEET_ANIMATION_STRATEGY: String = "animation/strategy_(packed_spritesheet)"

const PACKED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET: String = "Animate sprite's region and offset"
const PACKED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN: String = "Animate single atlas texture's region and margin"
const PACKED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES: String = "Animate multiple atlas texture instances"

const PACKED_SPRITESHEET_ANIMATION_STRATEGIES: PackedStringArray = [
	PACKED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET,
	PACKED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN,
	PACKED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES,
]



const OPTION_GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY: String = "animation/strategy_(grid-based_spritesheet)"

const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION: String = "Animate sprite's region"
const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_FRAME_INDEX: String = "Animate sprite's frame index"
const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_FRAME_COORDS: String = "Animate sprite's frame coords"
const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_REGION: String = "Animate single atlas texture's region"
const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES: String = "Animate multiple atlas texture instances"

const GRID_BASED_SPRITESHEET_ANIMATION_STRATEGIES: PackedStringArray = [
	GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION,
	GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_FRAME_INDEX,
	GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_FRAME_COORDS,
	GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_REGION,
	GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES,
]


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
			OPTION_PACKED_SPRITESHEET_ANIMATION_STRATEGY,
			PACKED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET,
			PROPERTY_HINT_ENUM, ",".join(PACKED_SPRITESHEET_ANIMATION_STRATEGIES),
			PROPERTY_USAGE_EDITOR,
			func (options:Dictionary) -> bool:
				return options[Common.OPTION_SPRITESHEET_LAYOUT] == Common.SPRITESHEET_LAYOUTS[Common.SpritesheetLayout.PACKED]),
		Common.create_option(
			OPTION_GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY,
			GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION,
			PROPERTY_HINT_ENUM, ",".join(GRID_BASED_SPRITESHEET_ANIMATION_STRATEGIES),
			PROPERTY_USAGE_EDITOR,
			func (options:Dictionary) -> bool:
				return options[Common.OPTION_SPRITESHEET_LAYOUT] != Common.SPRITESHEET_LAYOUTS[Common.SpritesheetLayout.PACKED]),
	])

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var status: Error

	var common_options: Common.Options = Common.Options.new(options)
	var centered = options[OPTION_SPRITE3D_CENTERED]

	var export_result: ExportResult = _export_texture(source_file, common_options, options, gen_files)

	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = source_file.get_file().get_basename()
	sprite.texture = export_result.texture
	sprite.centered = centered

	var ssmd: SpritesheetMetadata = export_result.spritesheet_metadata
	var autoplay: String = common_options.animation_autoplay_name
	var animation_player: AnimationPlayer
	match common_options.spritesheet_layout:
		Common.SpritesheetLayout.PACKED:
			match options[OPTION_PACKED_SPRITESHEET_ANIMATION_STRATEGY]:

				PACKED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET:
					sprite.region_enabled = true
					animation_player = _create_animation_player(ssmd, {
						".:offset": func (frame_data: FrameData) -> Vector2:
							return Vector2( # spatial sprite offset (the Y-axis is Up-directed)
								frame_data.region_rect_offset.x,
								ssmd.source_size.y -
								frame_data.region_rect_offset.y -
								frame_data.region_rect.size.y) + \
								# add center correction
								((frame_data.region_rect.size - ssmd.source_size) * 0.5
								if centered else Vector2.ZERO),
						".:region_rect" : func (frame_data: FrameData) -> Rect2i:
							return frame_data.region_rect },
						autoplay)

				PACKED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN:
					var atlas_texture: AtlasTexture = AtlasTexture.new()
					atlas_texture.filter_clip = true
					atlas_texture.resource_local_to_scene = true
					atlas_texture.atlas = sprite.texture
					sprite.texture = atlas_texture
					animation_player = _create_animation_player(ssmd, {
						".:texture:margin": func (frame_data: FrameData) -> Rect2:
							return Rect2(frame_data.region_rect_offset, ssmd.source_size - frame_data.region_rect.size),
						".:texture:region" : func (frame_data: FrameData) -> Rect2i:
							return  frame_data.region_rect },
						common_options.animation_autoplay_name)

				PACKED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES:
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
			match options[OPTION_GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY]:

				GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_REGION:
					sprite.region_enabled = true
					var random_frame_data: FrameData = ssmd.animation_tags[0].frames[0]
					sprite.offset = random_frame_data.region_rect_offset + \
						((random_frame_data.region_rect.size - ssmd.source_size) if centered else Vector2i.ZERO) / 2
					animation_player = _create_animation_player(ssmd, {
						".:region_rect" : func (frame_data: FrameData) -> Rect2i:
							return frame_data.region_rect },
						autoplay)

				GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_FRAME_INDEX:
					var random_frame_data: FrameData = ssmd.animation_tags[0].frames[0]
					var grid_cell_size: Vector2i = random_frame_data.region_rect.size
					if common_options.border_type == Common.BorderType.Extruded:
						grid_cell_size += Vector2i.ONE * 2
					match common_options.spritesheet_layout:
						Common.SpritesheetLayout.BY_ROWS:
							sprite.hframes = common_options.spritesheet_fixed_columns_count
							sprite.vframes = ssmd.spritesheet_size.y / grid_cell_size.y
						Common.SpritesheetLayout.BY_COLUMNS:
							sprite.hframes = ssmd.spritesheet_size.x / grid_cell_size.x
							sprite.vframes = common_options.spritesheet_fixed_rows_count
					animation_player = _create_animation_player(ssmd, {
						".:frame": func (frame_data: FrameData) -> int:
							var frame_coords: Vector2i = frame_data.region_rect.position / grid_cell_size
							match common_options.spritesheet_layout:
								Common.SpritesheetLayout.BY_ROWS:
									return common_options.spritesheet_fixed_columns_count * frame_coords.y + frame_coords.x
								Common.SpritesheetLayout.BY_COLUMNS:
									return common_options.spritesheet_fixed_rows_count * frame_coords.x + frame_coords.y
							push_error("Unexpected spritesheet layout type")
							return 0 },
						autoplay)

				GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_SPRITE_FRAME_COORDS:
					var random_frame_data: FrameData = ssmd.animation_tags[0].frames[0]
					var grid_cell_size: Vector2i = random_frame_data.region_rect.size
					if common_options.border_type == Common.BorderType.Extruded:
						grid_cell_size += Vector2i.ONE * 2
					match common_options.spritesheet_layout:
						Common.SpritesheetLayout.BY_ROWS:
							sprite.hframes = common_options.spritesheet_fixed_columns_count
							sprite.vframes = ssmd.spritesheet_size.y / grid_cell_size.y
						Common.SpritesheetLayout.BY_COLUMNS:
							sprite.hframes = ssmd.spritesheet_size.x / grid_cell_size.x
							sprite.vframes = common_options.spritesheet_fixed_rows_count
					animation_player = _create_animation_player(ssmd, {
						".:frame_coords": func (frame_data: FrameData) -> Vector2i:
							return frame_data.region_rect.position / grid_cell_size },
						autoplay)

				GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_REGION:
					var random_frame_data: FrameData = ssmd.animation_tags[0].frames[0]
					var atlas_texture = AtlasTexture.new()
					atlas_texture.atlas = export_result.texture
					atlas_texture.filter_clip = true
					atlas_texture.resource_local_to_scene = true
					atlas_texture.margin = Rect2(random_frame_data.region_rect_offset, ssmd.source_size - random_frame_data.region_rect.size)
					sprite.texture = atlas_texture
					animation_player = _create_animation_player(ssmd, {
						".:texture:region" : func (frame_data: FrameData) -> Rect2i:
							return  frame_data.region_rect },
						autoplay)

				GRID_BASED_SPRITESHEET_ANIMATION_STRATEGY_TEXTURE_INSTANCES:
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
							texture_cache.append(texture)
							return texture},
						autoplay)

	sprite.add_child(animation_player)
	animation_player.owner = sprite

	var packed_sprite: PackedScene
	if ResourceLoader.exists(source_file):
		# This is a working way to reuse a previously imported resource. Don't change it!
		packed_sprite = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if not packed_sprite:
		packed_sprite = PackedScene.new()

	packed_sprite.pack(sprite)

	status = ResourceSaver.save(
		packed_sprite,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS)
	if status: push_error("Can't save imported resource.", status)

	packed_sprite.emit_changed()
	return status
