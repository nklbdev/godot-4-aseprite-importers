extends Object

const AUTHOR: StringName = "nklbdev"
const PLUGIN_BUNDLE_NAME: StringName = "aseprite_importers"
const PLUGIN_DIR: StringName = "res://addons/" + AUTHOR + "." + PLUGIN_BUNDLE_NAME
const IMPORT_PLUGINS_DIR: StringName = PLUGIN_DIR + "/editor_import_plugins"
const ASEPRITE_EXECUTABLE_PATH_SETTING_NAME: StringName = PLUGIN_BUNDLE_NAME + "/aseprite_executable_path"

enum Presets {
	AUTODETECT_2D3D = 0,
	FOR_2D = 1,
	FOR_3D = 2
}

enum CompressMode {
	LOSSLESS = 0,
	LOSSY = 1,
	VRAM_COMPRESSED = 2,
	VRAM_UNCOMPRESSED = 3,
	BASIS_UNIVERSAL = 4
}
const COMPRESS_MODES_NAMES: PackedStringArray = [
	"Lossless",
	"Lossy",
	"VRAM Compressed",
	"VRAM Uncompressed",
	"Basis Universal"
]

# ONLY FOR VRAM_COMPRESSED
enum HdrCompression {
	DISABLED = 0,
	OPAQUE_ONLY = 1,
	ALWAYS = 2
}
const HDR_COMPRESSION_NAMES: PackedStringArray = [
	"Disabled",
	"Opaque Only",
	"Always"
]

# EXCEPT LOSSLESS
enum NormalMap {
	DETECT = 0,
	ENABLE = 1,
	DISABLED = 2
}
const NORMAL_MAP_NAMES: PackedStringArray = [
	"Detect",
	"Enable",
	"Disabled"
]

enum ChannelPack {
	SRGB_FRIENDLY = 0,
	OPTIMIZED = 1
}
const CHANNEL_PACK_NAMES: PackedStringArray = [
	"sRGB Friendly",
	"Optimized"
]

enum Roughness {
	DETECT = 0,
	DISABLED = 1,
	RED = 2,
	GREEN = 3,
	BLUE = 4,
	ALPHA = 5,
	GRAY = 6
}
const ROUGHNESS_NAMES: PackedStringArray = [
	"Detect",
	"Disabled",
	"Red",
	"Green",
	"Blue",
	"Alpha",
	"Gray"
]

enum CompressMode3D {
	DISABLED = 0,
	VRAM_COMPRESSED = 1,
	BASIS_UNIVERSAL = 3
}
const COMPRESS_MODE_3D_NAMES: PackedStringArray = [
	"Disabled",
	"VRAM Compressed",
	"Basis Universal"
]

enum MarkerPosition {
	PREFIX = 0,
	SUFFIX = 1
}
const MARKER_POSITION_NAMES: PackedStringArray = [
	"Prefix",
	"Suffix"
]

static func create_option(
	name: String,
	type: Variant.Type,
	property_hint: PropertyHint,
	hint_string: String,
	default_value: Variant,
	usage: PropertyUsageFlags,
	get_is_visible: Callable = func(options: Dictionary): return true) -> Dictionary:
	return {
			name = name,
			type = type,
			property_hint = property_hint,
			hint_string = hint_string,
			default_value = default_value,
			usage = usage,
			get_is_visible = get_is_visible
		}

enum AnimationDirection {
	FORWARD,
	REVERSE,
	PING_PONG
}
const ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS: PackedStringArray = [
	"forward", "reverse", "pingpong" ]
const PRESET_OPTIONS_ANIMATION_DIRECTIONS: PackedStringArray = [
	"Forward", "Reverse", "Ping-pong" ]

enum SpriteSheetLayout { BY_ROWS, BY_COLUMNS, PACKED }
const SPRITE_SHEET_LAYOUTS: PackedStringArray = [ "By rows", "By columns", "Packed"]

const OPTION_SPRITESHEET_EXTRUDE: String = "spritesheet/extrude"
const OPTION_SPRITESHEET_LAYOUT: String = "spritesheet/layout"
const OPTION_ANIMATION_DEFAULT_DIRECTION: String = "animation/default/direction"
const OPTION_ANIMATION_DEFAULT_LOOPED: String = "animation/default/looped"
const OPTION_ANIMATION_LOOPING_MARKER_POSITION: String = "animation/looping/marker_position"
const OPTION_ANIMATION_LOOPING_MARKER: String = "animation/looping/marker"
const OPTION_ANIMATION_LOOPING_TRIM_MARKER: String = "animation/looping/trim_marker"
const OPTION_LAYERS_INCLUDE_REG_EX: String = "layers/include_reg_ex"
const OPTION_LAYERS_EXCLUDE_REG_EX: String = "layers/exclude_reg_ex"
const OPTION_TAGS_INCLUDE_REG_EX: String = "tags/include_reg_ex"
const OPTION_TAGS_EXCLUDE_REG_EX: String = "tags/exclude_reg_ex"
const SPRITESHEET_FIXED_ROWS_COUNT: String = "spritesheet/fixed_rows_count"
const SPRITESHEET_FIXED_COLUMNS_COUNT: String = "spritesheet/fixed_columns_count"
const SPRITESHEET_FIXED_WIDTH: String = "spritesheet/fixed_width"
const SPRITESHEET_FIXED_HEIGHT: String = "spritesheet/fixed_height"



class Options:
	var extrude: bool
	var sprite_sheet_layout: SpriteSheetLayout
	var default_animation_direction: AnimationDirection
	var is_default_animation_looped: bool
	var animation_looping_marker_position: MarkerPosition
	var animation_looping_marker: String
	var trim_animation_looping_marker: bool
	var layers_include_regex: String
	var layers_exclude_regex: String
	var tags_include_regex: String
	var tags_exclude_regex: String
	func _init(options: Dictionary) -> void:
		extrude = options[OPTION_SPRITESHEET_EXTRUDE]
		sprite_sheet_layout = SPRITE_SHEET_LAYOUTS.find(options[OPTION_SPRITESHEET_LAYOUT])
		default_animation_direction = PRESET_OPTIONS_ANIMATION_DIRECTIONS.find(options[OPTION_ANIMATION_DEFAULT_DIRECTION])
		is_default_animation_looped = options[OPTION_ANIMATION_DEFAULT_LOOPED]
		animation_looping_marker_position = MARKER_POSITION_NAMES.find(options[OPTION_ANIMATION_LOOPING_MARKER_POSITION])
		animation_looping_marker = options[OPTION_ANIMATION_LOOPING_MARKER].strip_edges()
		if animation_looping_marker.is_empty(): animation_looping_marker = "_"
		trim_animation_looping_marker = options[OPTION_ANIMATION_LOOPING_TRIM_MARKER]
		layers_include_regex = options[OPTION_LAYERS_INCLUDE_REG_EX]
		layers_exclude_regex = options[OPTION_LAYERS_EXCLUDE_REG_EX]
		tags_include_regex = options[OPTION_TAGS_INCLUDE_REG_EX]
		tags_exclude_regex = options[OPTION_TAGS_EXCLUDE_REG_EX]

static func create_common_options() -> Array[Dictionary]:
	return [
		# TODO: Испортилась работа с опциями: не хочет работать нормально PROPERTY_HINT_ENUM и TYPE_INT
		create_option(OPTION_SPRITESHEET_EXTRUDE, TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option(OPTION_SPRITESHEET_LAYOUT, TYPE_STRING, PROPERTY_HINT_ENUM, ",".join(SPRITE_SHEET_LAYOUTS), SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.PACKED], PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED ),
		create_option(SPRITESHEET_FIXED_ROWS_COUNT, TYPE_INT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR, func(options): return options[OPTION_SPRITESHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.BY_COLUMNS]),
		create_option(SPRITESHEET_FIXED_COLUMNS_COUNT, TYPE_INT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR, func(options): return options[OPTION_SPRITESHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.BY_ROWS]),
		create_option(SPRITESHEET_FIXED_WIDTH, TYPE_INT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR, func(options): return options[OPTION_SPRITESHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.PACKED]),
		create_option(SPRITESHEET_FIXED_HEIGHT, TYPE_INT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR, func(options): return options[OPTION_SPRITESHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.PACKED]),
		create_option(OPTION_ANIMATION_DEFAULT_DIRECTION, TYPE_STRING, PROPERTY_HINT_ENUM, ",".join(PRESET_OPTIONS_ANIMATION_DIRECTIONS), PRESET_OPTIONS_ANIMATION_DIRECTIONS[AnimationDirection.FORWARD], PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_DEFAULT_LOOPED, TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_LOOPING_MARKER_POSITION, TYPE_STRING, PROPERTY_HINT_ENUM, ",".join(MARKER_POSITION_NAMES), MARKER_POSITION_NAMES[MarkerPosition.PREFIX], PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_LOOPING_MARKER, TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "_", "_", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_LOOPING_TRIM_MARKER, TYPE_BOOL, PROPERTY_HINT_NONE, "", true, PROPERTY_USAGE_EDITOR),
		create_option(OPTION_LAYERS_INCLUDE_REG_EX, TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "*", "*", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_LAYERS_EXCLUDE_REG_EX, TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "", "", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_TAGS_INCLUDE_REG_EX, TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "*", "*", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_TAGS_EXCLUDE_REG_EX, TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, "", "", PROPERTY_USAGE_EDITOR)
	]

# TODO: Убрать отсюда неподходящие варианты, например, Bitmap
static func create_texture_2d_options() -> Array[Dictionary]:
	return [
		create_option("compress/mode", TYPE_INT, PROPERTY_HINT_ENUM, ",".join(COMPRESS_MODES_NAMES),
			COMPRESS_MODES_NAMES[CompressMode.LOSSLESS], PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED),
		create_option("compress/high_quality", TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR, func(options): return options["compress/mode"] == COMPRESS_MODES_NAMES[CompressMode.VRAM_COMPRESSED]), # only for VRAM Compressed
		create_option("compress/lossy_quality", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,1,0.01", 0.7, PROPERTY_USAGE_EDITOR, func(options): return options["compress/mode"] == COMPRESS_MODES_NAMES[CompressMode.LOSSY]), # only for Lossy
		create_option("compress/hdr_compression", TYPE_INT, PROPERTY_HINT_ENUM, ",".join(HDR_COMPRESSION_NAMES),
			HDR_COMPRESSION_NAMES[HdrCompression.DISABLED], PROPERTY_USAGE_EDITOR, func(options): return options["compress/mode"] == COMPRESS_MODES_NAMES[CompressMode.VRAM_COMPRESSED]), # only for VRAM Compressed
		create_option("compress/normal_map", TYPE_INT, PROPERTY_HINT_ENUM, ",".join(NORMAL_MAP_NAMES),
			NORMAL_MAP_NAMES[NormalMap.DETECT], PROPERTY_USAGE_EDITOR, func(options): return options["compress/mode"] != COMPRESS_MODES_NAMES[CompressMode.LOSSLESS]), # everywhere except Lossless
		create_option("compress/channel_pack", TYPE_INT, PROPERTY_HINT_ENUM, ",".join(CHANNEL_PACK_NAMES),
			CHANNEL_PACK_NAMES[ChannelPack.SRGB_FRIENDLY], PROPERTY_USAGE_EDITOR), # everywhere

		create_option("mipmaps/generate", TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("mipmaps/limit", TYPE_INT, PROPERTY_HINT_RANGE, "-1,256,1", -1, PROPERTY_USAGE_EDITOR), # STRANGE! Appears only on 3D preset. Independently from other properties

		create_option("roughness/mode", TYPE_INT, PROPERTY_HINT_ENUM, ",".join(ROUGHNESS_NAMES),
			ROUGHNESS_NAMES[Roughness.DETECT], PROPERTY_USAGE_EDITOR),
		create_option("roughness/src_normal", TYPE_STRING, PROPERTY_HINT_FILE,
			"*.bmp,*.dds,*.exr,*.jpeg,*.jpg,*.hdr,*.png,*.svg,*.tga,*.webp", "", PROPERTY_USAGE_EDITOR),

		create_option("process/fix_alpha_border", TYPE_BOOL, PROPERTY_HINT_NONE, "", true, PROPERTY_USAGE_EDITOR),
		create_option("process/premult_alpha", TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/normal_map_invert_y", TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/hdr_as_srgb", TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/hdr_clamp_exposure", TYPE_BOOL, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/size_limit", TYPE_INT, PROPERTY_HINT_RANGE, "0,4096,1", 0, PROPERTY_USAGE_EDITOR),

		create_option("detect_3d/compress_to", TYPE_INT, PROPERTY_HINT_ENUM, ",".join(COMPRESS_MODE_3D_NAMES),
			COMPRESS_MODE_3D_NAMES[CompressMode3D.VRAM_COMPRESSED], PROPERTY_USAGE_EDITOR),
	]

static func extrude_edges_into_padding(image, json):
	for frame_data in json.data.frames:
		var frame = frame_data.frame
		var x = 0
		var y = frame.y
		for i in range(frame.w):
			x = frame.x + i
			image.set_pixel(x, y, image.get_pixel(x, y + 1))
		x = frame.x + frame.w - 1
		for i in range(frame.h):
			y = frame.y + i
			image.set_pixel(x, y, image.get_pixel(x - 1, y))
		y = frame.y + frame.h - 1
		for i in range(frame.w):
			x = frame.x + i
			image.set_pixel(x, y, image.get_pixel(x, y - 1))
		x = frame.x
		for i in range(frame.h):
			y = frame.y + i
			image.set_pixel(x, y, image.get_pixel(x + 1, y))
		frame.x += 1
		frame.y += 1
		frame.w -= 2
		frame.h -= 2
