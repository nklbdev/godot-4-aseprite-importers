@tool
extends EditorImportPlugin

const Common = preload("../common.gd")

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return []

func _get_import_order() -> int:
	return 0

func _get_importer_name() -> String:
	return ""

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_preset_count() -> int:
	return 0

func _get_preset_name(preset_index: int) -> String:
	return ""

func _get_priority() -> float:
	return 1

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray()

func _get_resource_type() -> String:
	return ""

func _get_save_extension() -> String:
	return ""

func _get_visible_name() -> String:
	return ""

func _import(source_file: String, save_path: String, options: Dictionary,
	platform_variants: Array[String], gen_files: Array[String]) -> Error:
	return ERR_UNCONFIGURED # ERR_XXXXX

#func append_import_external_resource(path: String, custom_options: Dictionary = {},
#	custom_importer: String = "", generator_parameters: Variant = null) -> Error:
#	return 0
