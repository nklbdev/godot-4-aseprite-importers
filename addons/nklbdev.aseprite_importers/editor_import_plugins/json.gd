@tool
extends "_base.gd"

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite JSON Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "JSON"
	_save_extension = "tres"
	_visible_name = "JSON"
	set_preset("Animation", [])

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:

	var common_options: Common.Options = Common.Options.new(options)
			# "--list-layers",
			# "--list-slices",
	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

	var status = ResourceSaver.save(
		json,
		save_path + "." + _get_save_extension(),
#		ResourceSaver.FLAG_COMPRESS
	)
	if status != OK:
		push_error("Can't save imported resource.", status)
	return status

func get_sprite_frames(source_file) -> SpriteFrames:
	var sprite_frames: SpriteFrames
	if ResourceLoader.exists(source_file):
		sprite_frames = ResourceLoader.load(source_file, "SpriteFrames", ResourceLoader.CACHE_MODE_IGNORE) as SpriteFrames
	return sprite_frames if sprite_frames else SpriteFrames.new()
