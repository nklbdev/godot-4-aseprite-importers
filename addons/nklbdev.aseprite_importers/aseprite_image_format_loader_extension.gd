extends ImageFormatLoaderExtension

const Common = preload("common.gd")

const __recognized_extensions: PackedStringArray = ["ase", "aseprite"]

func _get_recognized_extensions() -> PackedStringArray:
	return __recognized_extensions

#func _load_image(image: Image, file_access: FileAccess, flags: int, scale: float) -> Error:
# type hints is removed because different releases of Godot have different signature of this method
func _load_image(image, file_access, flags, scale):
	flags = flags as ImageFormatLoader.LoaderFlags

	var source_file_path: String = ProjectSettings.globalize_path(file_access.get_path_absolute())
	var global_png_path: String = source_file_path + ".png"
	var aseprite_executable_path: String = ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME)

	var command_line_params: PackedStringArray = PackedStringArray([
		"--batch",
		source_file_path,
		"--frame-range", "0,0",
		"--save-as",
		global_png_path
	])

	var output: Array = []
	var err: Error = OS.execute(
		ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME),
		command_line_params, output, true)
	if err:
		push_error("There was an error while executing aseprite command: %s" % error_string(err))
		return err

	image.load_png_from_buffer(FileAccess.get_file_as_bytes(global_png_path))
	DirAccess.remove_absolute(global_png_path)

	return OK
