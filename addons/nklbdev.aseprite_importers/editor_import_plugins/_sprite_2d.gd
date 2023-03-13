@tool
extends "_base.gd"

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite Sprite2D Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "tscn"
	_visible_name = "Sprite2D"

	# Есть 2 пути:
	# 1. GRID:
	#    1. Задать в спрайте сетку с помощью hframes и vframes
	#    2. управлять анимацией с помощью frame или frame_coords (Vector2i по сетке)
	# 2. PACKED:
	#    1. Установить region_enabled
	#    2. управлять region_rect
	set_preset("Animation", [])


func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:

	var common_options: Common.Options = Common.Options.new(options)
	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

	_add_default_tag_if_needed(json, common_options)
	
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = source_file.get_file().get_basename()
	sprite.texture = texture
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	sprite.add_child(animation_player)
	animation_player.owner = sprite



	var e: Error
	# e = SpriteFramesImporter.update_sprite_frames(json, common_options, texture, sprite_frames)
	# if e: push_error("Cannot update SpriteFrames", e); return e

	var packed_sprite: PackedScene
	if ResourceLoader.exists(source_file):
		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
		packed_sprite = ResourceLoader.load(source_file, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if not packed_sprite:
		packed_sprite = PackedScene.new()

	packed_sprite.pack(sprite)

	e = ResourceSaver.save(packed_sprite, save_path + "." + _get_save_extension()) # ResourceSaver.FLAG_COMPRESS)
	if e: push_error("Can't save imported resource.", e)

	packed_sprite.emit_changed()
	return e
