extends Object

const AUTHOR: StringName = "nklbdev"
const PLUGIN_BUNDLE_NAME: StringName = "aseprite_importers"
const PLUGIN_DIR: StringName = "res://addons/" + AUTHOR + "." + PLUGIN_BUNDLE_NAME
const IMPORT_PLUGINS_DIR: StringName = PLUGIN_DIR + "/editor_import_plugins"
const ASEPRITE_EXECUTABLE_PATH_SETTING_NAME: StringName = PLUGIN_BUNDLE_NAME + "/aseprite_executable_path"

enum Presets {
	AUTODETECT_2D3D,
	FOR_2D,
	FOR_3D
}

enum CompressMode {
	LOSSLESS,
	LOSSY,
	VRAM_COMPRESSED,
	VRAM_UNCOMPRESSED,
	BASIS_UNIVERSAL
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
	DISABLED,
	OPAQUE_ONLY,
	ALWAYS
}
const HDR_COMPRESSION_NAMES: PackedStringArray = [
	"Disabled",
	"Opaque Only",
	"Always"
]

# EXCEPT LOSSLESS
enum NormalMap {
	DETECT,
	ENABLE,
	DISABLED
}
const NORMAL_MAP_NAMES: PackedStringArray = [
	"Detect",
	"Enable",
	"Disabled"
]

enum ChannelPack {
	SRGB_FRIENDLY,
	OPTIMIZED
}
const CHANNEL_PACK_NAMES: PackedStringArray = [
	"sRGB Friendly",
	"Optimized"
]

enum Roughness {
	DETECT,
	DISABLED,
	RED,
	GREEN,
	BLUE,
	ALPHA,
	GRAY
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
	DISABLED,
	VRAM_COMPRESSED,
	BASIS_UNIVERSAL
}
const COMPRESS_MODE_3D_NAMES: PackedStringArray = [
	"Disabled",
	"VRAM Compressed",
	"Basis Universal"
]

static func create_option(
	name: String,
	property_hint: PropertyHint,
	hint_string: String,
	default_value,
	usage: PropertyUsageFlags,
	get_is_visible: Callable = func(options: Dictionary): return true) -> Dictionary:
	return {
		name = name,
		property_hint = property_hint,
		hint_string = hint_string,
		default_value = default_value,
		usage = usage,
		get_is_visible = get_is_visible
	}

enum AnimationDirection {
	FORWARD = 0,
	REVERSE = 1,
	PING_PONG = 2,
	PING_PONG_REVERSE = 3
}
const ASEPRITE_OUTPUT_ANIMATION_DIRECTIONS: PackedStringArray = [
	"forward", "reverse", "pingpong", "pingpong_reverse" ]
const PRESET_OPTIONS_ANIMATION_DIRECTIONS: PackedStringArray = [
	"Forward", "Reverse", "Ping-pong", "Ping-pong reverse" ]

enum SpriteSheetLayout { PACKED, BY_ROWS, BY_COLUMNS }
const SPRITE_SHEET_LAYOUTS: PackedStringArray = ["Packed", "By rows", "By columns"]

const OPTION_SPRITESHEET_EXTRUDE: String = "spritesheet/extrude"
const OPTION_SPRITESHEET_LAYOUT: String = "spritesheet/layout"
const OPTION_ANIMATION_DEFAULT_NAME: String = "animation/default/name"
const OPTION_ANIMATION_DEFAULT_DIRECTION: String = "animation/default/direction"
const OPTION_ANIMATION_DEFAULT_REPEAT_COUNT: String = "animation/default/repeat_count"
const OPTION_ANIMATION_AUTOPLAY_NAME: String = "animation/autoplay"
const OPTION_ANIMATION_STRATEGY: String = "animation/strategy"
const OPTION_LAYERS_INCLUDE_REG_EX: String = "layers/include_reg_ex"
const OPTION_LAYERS_EXCLUDE_REG_EX: String = "layers/exclude_reg_ex"
const OPTION_TAGS_INCLUDE_REG_EX: String = "tags/include_reg_ex"
const OPTION_TAGS_EXCLUDE_REG_EX: String = "tags/exclude_reg_ex"
const SPRITESHEET_FIXED_ROWS_COUNT: String = "spritesheet/fixed_rows_count"
const SPRITESHEET_FIXED_COLUMNS_COUNT: String = "spritesheet/fixed_columns_count"



class Options:
	var extrude: bool
	var sprite_sheet_layout: SpriteSheetLayout
	var default_animation_name: String
	var default_animation_direction: AnimationDirection
	var default_animation_repeat_count: int
	var animation_autoplay_name: String
	#var animation_strategy: String
	var layers_include_regex: String
	var layers_exclude_regex: String
	var tags_include_regex: String
	var tags_exclude_regex: String
	func _init(options: Dictionary) -> void:
		extrude = options[OPTION_SPRITESHEET_EXTRUDE]
		sprite_sheet_layout = SPRITE_SHEET_LAYOUTS.find(options[OPTION_SPRITESHEET_LAYOUT])
		default_animation_name = options[OPTION_ANIMATION_DEFAULT_NAME].strip_edges().strip_escapes()
		if default_animation_name.is_empty(): default_animation_name = "default"
		default_animation_direction = PRESET_OPTIONS_ANIMATION_DIRECTIONS.find(options[OPTION_ANIMATION_DEFAULT_DIRECTION])
		default_animation_repeat_count = options[OPTION_ANIMATION_DEFAULT_REPEAT_COUNT]
		animation_autoplay_name = options[OPTION_ANIMATION_AUTOPLAY_NAME].strip_edges().strip_escapes()
		# animation_strategy = /*select enum value*/ options[OPTION_ANIMATION_STRATEGY]
		layers_include_regex = options[OPTION_LAYERS_INCLUDE_REG_EX]
		layers_exclude_regex = options[OPTION_LAYERS_EXCLUDE_REG_EX]
		tags_include_regex = options[OPTION_TAGS_INCLUDE_REG_EX]
		tags_exclude_regex = options[OPTION_TAGS_EXCLUDE_REG_EX]

# К интам привести опции-перечисления увы, не получится. Потому что в движке есть какой-то баг,
# из-за которого первая инициализация значением по умолчанию происходит
# в виде строки кэпшена первого элемента, переданного в запакованном HintString
# После изменения опции в редакторе уже проставляется нормальный INT. Надеюсь, скоро починят
# Проблема находится примерно здесь:
# https://github.com/godotengine/godot/blob/e9c7b8d2246bd0797af100808419c994fa43a9d2/editor/editor_file_system.cpp#L1855
static func create_common_options() -> Array[Dictionary]:
	return [
		create_option(OPTION_SPRITESHEET_EXTRUDE, PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option(OPTION_SPRITESHEET_LAYOUT, PROPERTY_HINT_ENUM, ",".join(SPRITE_SHEET_LAYOUTS), SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.PACKED], PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED ),
		create_option(SPRITESHEET_FIXED_ROWS_COUNT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR,
			func(options): return options[OPTION_SPRITESHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.BY_COLUMNS]),
		create_option(SPRITESHEET_FIXED_COLUMNS_COUNT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR,
			func(options): return options[OPTION_SPRITESHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.BY_ROWS]),
		create_option(OPTION_ANIMATION_DEFAULT_NAME, PROPERTY_HINT_PLACEHOLDER_TEXT, "default", "default", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_DEFAULT_DIRECTION, PROPERTY_HINT_ENUM, ",".join(PRESET_OPTIONS_ANIMATION_DIRECTIONS), PRESET_OPTIONS_ANIMATION_DIRECTIONS[0], PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_DEFAULT_REPEAT_COUNT, PROPERTY_HINT_RANGE, "0,32,1,or_greater", 0, PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_AUTOPLAY_NAME, PROPERTY_HINT_NONE, "", "", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_LAYERS_INCLUDE_REG_EX, PROPERTY_HINT_PLACEHOLDER_TEXT, "*", "*", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_LAYERS_EXCLUDE_REG_EX, PROPERTY_HINT_PLACEHOLDER_TEXT, "", "", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_TAGS_INCLUDE_REG_EX, PROPERTY_HINT_PLACEHOLDER_TEXT, "*", "*", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_TAGS_EXCLUDE_REG_EX, PROPERTY_HINT_PLACEHOLDER_TEXT, "", "", PROPERTY_USAGE_EDITOR)
	]

# TODO: Убрать отсюда неподходящие варианты, например, Bitmap
static func create_texture_2d_options() -> Array[Dictionary]:
	return [
		create_option("compress/mode", PROPERTY_HINT_ENUM, ",".join(COMPRESS_MODES_NAMES),
			COMPRESS_MODES_NAMES[CompressMode.LOSSLESS], PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED),
		create_option("compress/high_quality", PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR,
			func(options): return options["compress/mode"] == COMPRESS_MODES_NAMES[CompressMode.VRAM_COMPRESSED]),
		create_option("compress/lossy_quality", PROPERTY_HINT_RANGE, "0,1,0.01", 0.7, PROPERTY_USAGE_EDITOR,
			func(options): return options["compress/mode"] == COMPRESS_MODES_NAMES[CompressMode.LOSSY]),
		create_option("compress/hdr_compression", PROPERTY_HINT_ENUM, ",".join(HDR_COMPRESSION_NAMES), HDR_COMPRESSION_NAMES[HdrCompression.DISABLED], PROPERTY_USAGE_EDITOR,
			func(options): return options["compress/mode"] == COMPRESS_MODES_NAMES[CompressMode.VRAM_COMPRESSED]),
		create_option("compress/normal_map", PROPERTY_HINT_ENUM, ",".join(NORMAL_MAP_NAMES), NORMAL_MAP_NAMES[NormalMap.DETECT], PROPERTY_USAGE_EDITOR,
			func(options): return options["compress/mode"] != COMPRESS_MODES_NAMES[CompressMode.LOSSLESS]),
		create_option("compress/channel_pack", PROPERTY_HINT_ENUM, ",".join(CHANNEL_PACK_NAMES),
			ChannelPack.SRGB_FRIENDLY, PROPERTY_USAGE_EDITOR), # everywhere

		create_option("mipmaps/generate", PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		# STRANGE! Appears only on 3D preset. Independently from other properties
		create_option("mipmaps/limit", PROPERTY_HINT_RANGE, "-1,256,1", -1, PROPERTY_USAGE_EDITOR),

		create_option("roughness/mode", PROPERTY_HINT_ENUM, ",".join(ROUGHNESS_NAMES),
			ROUGHNESS_NAMES[Roughness.DETECT], PROPERTY_USAGE_EDITOR),
		create_option("roughness/src_normal", PROPERTY_HINT_FILE,
			"*.bmp,*.dds,*.exr,*.jpeg,*.jpg,*.hdr,*.png,*.svg,*.tga,*.webp", "", PROPERTY_USAGE_EDITOR),

		create_option("process/fix_alpha_border", PROPERTY_HINT_NONE, "", true, PROPERTY_USAGE_EDITOR),
		create_option("process/premult_alpha", PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/normal_map_invert_y", PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/hdr_as_srgb", PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/hdr_clamp_exposure", PROPERTY_HINT_NONE, "", false, PROPERTY_USAGE_EDITOR),
		create_option("process/size_limit", PROPERTY_HINT_RANGE, "0,4096,1", 0, PROPERTY_USAGE_EDITOR),

		create_option("detect_3d/compress_to", PROPERTY_HINT_ENUM, ",".join(COMPRESS_MODE_3D_NAMES),
			COMPRESS_MODE_3D_NAMES[CompressMode3D.VRAM_COMPRESSED], PROPERTY_USAGE_EDITOR),
	]
