@tool
extends "_base.gd"

const OPTION_ANIMATION_STRATEGY: String = "animation/strategy"

const ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN: String = "Animate single atlas texture's region and margin"
const ANIMATION_STRATEGY_TEXTURE_INSTANCES: String = "Animate multiple atlas texture instances"
const ANIMATION_STRATEGIES: PackedStringArray = [
	ANIMATION_STRATEGY_TEXTURE_REGION_AND_MARGIN,
	ANIMATION_STRATEGY_TEXTURE_INSTANCES,
]

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite TextureRect Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "scn"
	_visible_name = "TextureRect"

	set_preset("Animation", [
		Common.create_option(OPTION_ANIMATION_STRATEGY, PROPERTY_HINT_ENUM, ",".join(ANIMATION_STRATEGIES), ANIMATION_STRATEGIES[0], PROPERTY_USAGE_EDITOR)
	])


func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var status: Error

	var common_options: Common.Options = Common.Options.new(options)
	var export_result: ExportResult = _export_texture(source_file, common_options, options, gen_files)

	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = export_result.texture
	atlas_texture.filter_clip = true
	atlas_texture.resource_local_to_scene = true

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.name = source_file.get_file().get_basename()
	texture_rect.texture = atlas_texture

	var frame_size: Vector2i = export_result.spritesheet_metadata.source_size
	var animation_player = _create_animation_player(
		export_result.spritesheet_metadata, {
			".:texture:margin": func (frame_data: FrameData) -> Rect2:
				return Rect2(frame_data.region_rect_offset, frame_size - frame_data.region_rect.size),
			".:texture:region" : func (frame_data: FrameData) -> Rect2i:
				return  frame_data.region_rect })

	texture_rect.add_child(animation_player)
	animation_player.owner = texture_rect

	var packed_sprite: PackedScene
	if ResourceLoader.exists(source_file):
		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
		packed_sprite = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if not packed_sprite:
		packed_sprite = PackedScene.new()

	packed_sprite.pack(texture_rect)

	status = ResourceSaver.save(
		packed_sprite,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS)
	if status: push_error("Can't save imported resource.", status)

	packed_sprite.emit_changed()
	return status
