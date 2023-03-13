@tool
extends "_base.gd"

const SpriteFramesImporter = preload("sprite_frames.gd")

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite AnimatedSprite2D Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "tscn"
	_visible_name = "AnimatedSprite2D"

	set_preset("Animation", [])


func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:

	var common_options: Common.Options = Common.Options.new(options)
	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

	_add_default_tag_if_needed(json, common_options)
	
	var packed_animated_sprite: PackedScene
	var animated_sprite: AnimatedSprite2D
	var sprite_frames: SpriteFrames

	if ResourceLoader.exists(source_file):
		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
		packed_animated_sprite = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene

	if packed_animated_sprite and packed_animated_sprite.can_instantiate():
		animated_sprite = packed_animated_sprite.instantiate() as AnimatedSprite2D

	if animated_sprite:
		sprite_frames = animated_sprite.sprite_frames

	if not sprite_frames:
		sprite_frames = SpriteFrames.new()
	
	if not animated_sprite:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = source_file.get_file().get_basename()
	
	animated_sprite.sprite_frames = sprite_frames
	
	if not packed_animated_sprite:
		packed_animated_sprite = PackedScene.new()


	var e: Error = SpriteFramesImporter.update_sprite_frames(json, common_options, texture, sprite_frames)
	if e: push_error("Cannot update SpriteFrames", e); return e

	packed_animated_sprite.pack(animated_sprite)

	e = ResourceSaver.save(packed_animated_sprite, save_path + "." + _get_save_extension()) # ResourceSaver.FLAG_COMPRESS)
	if e: push_error("Can't save imported resource.", e)

	packed_animated_sprite.emit_changed()
	return e
