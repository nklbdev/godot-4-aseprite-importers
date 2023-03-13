@tool
extends "_base.gd"

# TODO:
# Может использоваться только 1 слайс. Либо по имени, либо первый.
# Иначе - либо задать дефолтные параметры в импорте,
# либо использовать всю текстуру как среднюю часть
#
# Анимацию сделать с помощью AnimationPlayer'а,
# который управляет позицией NinePatchRect:region_rect:position

func _init(parent_plugin: EditorPlugin) -> void:
	super(parent_plugin)
	_import_order = 0
	_importer_name = "Aseprite NinePatchRect Import"
	_priority = 1
	_recognized_extensions = ["ase", "aseprite"]
	_resource_type = "PackedScene"
	_save_extension = "tscn"
	_visible_name = "NinePatchRect"
	set_preset("Animation", [])

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:

	var common_options: Common.Options = Common.Options.new(options)
			# "--list-layers",
			# "--list-slices",
	var json: JSON = _export_texture(source_file, common_options, options, gen_files)
	var texture: Texture2D = load(source_file.get_base_dir().path_join(json.data.meta.image))

	_add_default_tag_if_needed(json, common_options)

	var nine_patch_rect = NinePatchRect.new()
	nine_patch_rect.texture = texture

	#AxisStretchMode axis_stretch_horizontal [default: 0]
	#AxisStretchMode axis_stretch_vertical [default: 0]
	#bool draw_center [default: true]
	#MouseFilter mouse_filter [overrides Control: 2]
	#int patch_margin_bottom [default: 0]
	#int patch_margin_left [default: 0]
	#int patch_margin_right [default: 0]
	#int patch_margin_top [default: 0]
	#Rect2 region_rect [default: Rect2(0, 0, 0, 0)]
	#Texture2 Dtexture

	nine_patch_rect.name = source_file.get_file().get_basename()
	var packed_scene = PackedScene.new()
	var e = packed_scene.pack(nine_patch_rect)
	if e:
		push_error("Can't pack.", e)

	var status = ResourceSaver.save(
		packed_scene,
		save_path + "." + _get_save_extension(),
		ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_BUNDLE_RESOURCES | ResourceSaver.FLAG_RELATIVE_PATHS)
	if status != OK:
		push_error("Can't save imported resource.", status)
#	sprite_frames.emit_signal("changed")
#	sprite_frames.emit_changed()
	return status

#func get_sprite_frames(source_file) -> SpriteFrames:
##	var sprite_frames: SpriteFrames
##	if ResourceLoader.exists(source_file):
##		# НУЖНО ИМЕННО ТАК. IGNORE... или REPLACE!!!!!!!!!!!!
##		return ResourceLoader.load(source_file, "SpriteFrames", ResourceLoader.CACHE_MODE_IGNORE) as SpriteFrames
#	return SpriteFrames.new()
