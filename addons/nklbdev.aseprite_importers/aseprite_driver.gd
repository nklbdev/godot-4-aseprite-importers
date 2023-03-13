#extends RefCounted
#
#enum Constraints {
#	NONE,
#	FIXED_NUM_OF_COLUMNS,
#	FIXED_NUM_OF_ROWS,
#	FIXED_WIDTH,
#	FIXED_HEIGHT,
#	FIXED_SIZE }
#
#enum SpriteSource {
#	SPRITE,
#	SPRITE_GRID,
#	TILESETS }
#
#enum LayersMode {
#	VISIBLE,
#	ALL,
#	ONLY_SELECTED,
#	ALL_EXCEPT_SELECTED,
#	} # some concrete layer
#
#enum FramesMode {
#	FIRST, # --oneframe
#	ALL,
#	TAGGED, # --frame-tag tagname
#	RANGED, # --frame-range from, to
#
#}
#
#enum FramesToExport {
#	VISIBLE_FRAMES,
#	SELECTED_FRAMES }
#
## for "--sheet-type" parameter
#enum JsonDataFormat {
#	HASH, ARRAY }
#const JsonDataFormatParams: PackedStringArray = [
#	"json-hash",
#	"json-array" ]
#
#
#
#const Common = preload("common.gd")
#
#class SheetLayout:
#	static func horizontal_strip() -> __SheetLayoutHorizontalStrip: return __SheetLayoutHorizontalStrip.new()
#	static func vertical_strip() -> __SheetLayoutHorizontalStrip: return __SheetLayoutHorizontalStrip.new()
#	static func by_rows() -> __SheetLayoutByRows: return __SheetLayoutByRows.new()
#	static func by_columns() -> __SheetLayoutByColumns: return __SheetLayoutByColumns.new()
#	static func packed() -> __SheetLayoutPacked: return __SheetLayoutPacked.new()
#	func _get_command_line_fragment() -> PackedStringArray: return []
#
#class __SheetLayoutHorizontalStrip:
#	extends SheetLayout
#	func _get_command_line_fragment() -> PackedStringArray:
#		return ["--sheet-type", "horizontal"]
#	# Constraints are not allowed
#
#class __SheetLayoutVerticalStrip:
#	extends SheetLayout
#	func _get_command_line_fragment() -> PackedStringArray:
#		return ["--sheet-type", "vertical"]
#	# Constraints are not allowed
#
#class __SheetLayoutByRows:
#	extends SheetLayout
#	var __constraint: Array[String]
#	func constraint_columns_count(columns_count: int) -> SheetLayout:
#		__constraint = ["--sheet-columns", str(columns_count)]
#		return self
#	func constraint_width(width: int) -> SheetLayout:
#		__constraint = ["--sheet-width", str(width)]
#	func _get_command_line_fragment() -> PackedStringArray:
#		return ["--sheet-type", "rows"] + __constraint
#
#class __SheetLayoutByColumns:
#	extends SheetLayout
#	var __constraint: Array[String]
#	func constraint_rows_count(rows_count: int) -> SheetLayout:
#		__constraint = ["--sheet-rows", str(rows_count)]
#	func constraint_height(height: int) -> SheetLayout:
#		__constraint = ["--sheet-height", str(height)]
#	func _get_command_line_fragment() -> PackedStringArray:
#		return ["--sheet-type", "columns"] + __constraint
#
#class __SheetLayoutPacked:
#	extends SheetLayout
#	var __constraint: Array[String]
#	func constraint_width(width: int) -> void:
#		__constraint = ["--sheet-width", str(width)]
#	func constraint_height(height: int) -> void:
#		__constraint = ["--sheet-height", str(height)]
#	func constraint_size(width: int, height: int) -> void:
#		__constraint = ["--sheet-width", str(width), "--sheet-height", str(height)]
#	func constraint_sizev(size: Vector2i) -> void:
#		constraint_size(size.x, size.y)
#	func _get_command_line_fragment() -> PackedStringArray:
#		return ["--sheet-type", "packed"] + __constraint
#
#
#class ExportParameters:
#	# SPRITESHEET
#	var sheet_type: int
#	var constraint: Constraints
#	var merge_duplicates: bool
#	var ignore_empty: bool
#	var size_constraint: int
#	var sheet_width: int # --sheet-width
#	var sheet_height: int # --sheet-height
#	var sheet_columns: int # --sheet_columns
#	var sheet_rows: int # --sheet_rows
#	# SPRITE
#	var source: SpriteSource
#	var layers_mode: LayersMode
#	var layer_names: PackedStringArray
#	var frames: FramesToExport
#	var split_layers: bool # --split-layers
#	var split_tags: bool # --split-tags
#	var split_slices: bool # --split-slices
#	var scale: float = 1
#	# BORDERS
#	var border_padding: int
#	var spacing: int
#	var inner_padding: int
#	var trim_sprite: bool
#	var trim_cels: bool
#	var crop: bool
#	var crop_rect: Rect2i
#	var extrude: bool # not allowed in CLI
#	# OUTPUT
##	var export_output_file: bool # hide!
##	var output_file: String # hide!
##	var export_json_data: bool # always true
##	var json_data: String # Not needed - json data is received from output
#	var json_data_format: JsonDataFormat
#	var export_layers_meta: bool # --list-layers
#	var export_tags_meta: bool # --list-tags
#	var export_slices_meta: bool # --list-slices
#	var sprite_name_format: String
#	pass
#
#var __resource_filesystem: EditorFileSystem
#
#func _init(resource_filesystem: EditorFileSystem) -> void:
#	__resource_filesystem = resource_filesystem
#	pass
#
#func export(source_file_path: String, target: String, parameters: ExportParameters) -> JSON:
#	var image_file_path: String = source_file_path.get_basename() + ".png"
#	var global_image_file_path: String = ProjectSettings.globalize_path(image_file_path)
#	var output: Array = []
#
#	var params: Array[String]
#	params.append("--batch")
#	if parameters.sprite_name_format: params.append_array(["--filename-format", parameters.sprite_name_format]) # "{tag}{tagframe}"
#	params.append_array(["--format", JsonDataFormatParams[parameters.json_data_format]])
#	if parameters.export_layers_meta: params.append("--list-layers")
#	if parameters.export_tags_meta:   params.append("--list-tags")
#	if parameters.export_slices_meta: params.append("--list-slices")
#	if parameters.ignore_empty: params.append("--ignore-empty")
#	if parameters.trim_cels: params.append("--trim")
#	if parameters.crop: params.append("--crop %s, %s, %s, %s" % [
#		parameters.crop_rect.position.x,
#		parameters.crop_rect.position.y,
#		parameters.crop_rect.size.x,
#		parameters.crop_rect.size.y ])
#	if parameters.scale != 1: params.append_array(["--scale", str(parameters.scale)])
##	params.append_array(["--sheet-type", SheetTypeParams[parameters.sheet_type]])
#	params.append_array(["--sheet", global_image_file_path])
#
#	var err: Error = OS.execute(
#		ProjectSettings.get_setting(Common.ASEPRITE_EXECUTABLE_PATH_SETTING_NAME),
#		params, output, true)
#
#	var json = JSON.new()
#	json.parse(output[0], true)
#	var image = Image.load_from_file(global_image_file_path)
#	if parameters.extrude:
#		extrude_edges_into_padding(image, json)
#	image.save_png(global_image_file_path)
#	__resource_filesystem.update_file(image_file_path)
#	return json
#
#func extrude_edges_into_padding(image, json):
#	for frame_data in json.frames:
#		var frame = frame_data.frame
#		var x = 0
#		var y = frame.y
#		for i in range(frame.w):
#			x = frame.x + i
#			image.set_pixel(x, y, image.get_pixel(x, y + 1))
#		x = frame.x + frame.w - 1
#		for i in range(frame.h):
#			y = frame.y + i
#			image.set_pixel(x, y, image.get_pixel(x - 1, y))
#		y = frame.y + frame.h - 1
#		for i in range(frame.w):
#			x = frame.x + i
#			image.set_pixel(x, y, image.get_pixel(x, y - 1))
#		x = frame.x
#		for i in range(frame.h):
#			y = frame.y + i
#			image.set_pixel(x, y, image.get_pixel(x + 1, y))
#		# TODO: fix json frames rects
