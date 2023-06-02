extends "_sprite_sheet_importer_base.gd"

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_resource_type = "PortableCompressedTexture2D"
	_import_order = 0
	_importer_name = "Aseprite sprite sheet (%s) Import" % _resource_type
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_save_extension = "res"
	_visible_name = "Sprite sheet (%s)" % _resource_type

	set_preset("Sprite sheet", [])

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var status: Error = OK
	var sprite_sheet_options = Common.ParsedSpriteSheetOptions.new(options)
	var export_result: SpriteSheetExportResult = _export_sprite_sheet(source_file, sprite_sheet_options)

	status = ResourceSaver.save(
		export_result.texture,
		save_path + "." + _get_save_extension())
	if status:
		push_error("Can't save imported resource.", status)
	return status
