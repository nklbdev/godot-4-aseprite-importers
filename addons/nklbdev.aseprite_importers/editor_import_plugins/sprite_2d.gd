@tool
extends "_base.gd"

const OPTION_SPRITE2D_CENTERED: String = "sprite2d/centered"

const OPTION_ANIMATION_STRATEGY: String = "animation/strategy"

const ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET: String = "Animate sprite's region and offset"
const ANIMATION_STRATEGY_SPRITE_FRAME_INDEX: String = "Animate sprite's frame index"
const ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN: String = "Animate single atlas texture's region and margin"
const ANIMATION_STRATEGY_TEXTURE_INSTANCES: String = "Animate multiple atlas texture instances"
const ANIMATION_STRATEGIES: PackedStringArray = [
	ANIMATION_STRATEGY_SPRITE_REGION_AND_OFFSET,
	ANIMATION_STRATEGY_SPRITE_FRAME_INDEX,
	ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN,
	ANIMATION_STRATEGY_TEXTURE_INSTANCES,
]

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite Sprite2D Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "scn"
	_visible_name = "Sprite2D"

	set_preset("Animation", [
		Common.create_option(OPTION_SPRITE2D_CENTERED, PROPERTY_HINT_NONE, "", true, PROPERTY_USAGE_EDITOR),
		Common.create_option(OPTION_ANIMATION_STRATEGY, PROPERTY_HINT_ENUM, ",".join(ANIMATION_STRATEGIES), ANIMATION_STRATEGIES[0], PROPERTY_USAGE_EDITOR)
	])

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var status: Error

	var common_options: Common.Options = Common.Options.new(options)
	var centered = options[OPTION_SPRITE2D_CENTERED]
	var export_result: ExportResult = _export_texture(source_file, common_options, options, gen_files)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = source_file.get_file().get_basename()
	sprite.texture = export_result.texture
	sprite.centered = centered
	sprite.region_enabled = true

	var frame_half_size: Vector2 = export_result.spritesheet_metadata.source_size / 2.0
	var animation_player = _create_animation_player(
		export_result.spritesheet_metadata, {
			".:offset": func (frame_data: FrameData) -> Vector2:
				return frame_data.region_rect_offset + \
					((frame_data.region_rect.size / 2.0 - frame_half_size) if centered else 0),
			".:region_rect" : func (frame_data: FrameData) -> Rect2i:
				return frame_data.region_rect })

	sprite.add_child(animation_player)
	animation_player.owner = sprite

	var packed_sprite: PackedScene
	if ResourceLoader.exists(source_file):
		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
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
