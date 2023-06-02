extends Object

const PLUGIN_BUNDLE_NAME: StringName = "aseprite_importers"
const ASEPRITE_EXECUTABLE_PATH_SETTING_NAME: StringName = PLUGIN_BUNDLE_NAME + "/aseprite_executable_path"

const EMPTY_CALLABLE: Callable = Callable()

static func create_option(
	name: String,
	default_value: Variant,
	property_hint: PropertyHint = PROPERTY_HINT_NONE,
	hint_string: String = "",
	usage: PropertyUsageFlags = PROPERTY_USAGE_NONE,
	get_is_visible: Callable = EMPTY_CALLABLE
	) -> Dictionary:
	var option_data: Dictionary = {
		name = name,
		default_value = default_value,
	}
	if hint_string: option_data["hint_string"] = hint_string
	if property_hint: option_data["property_hint"] = property_hint
	if usage: option_data["usage"] = usage
	if get_is_visible != EMPTY_CALLABLE: option_data["get_is_visible"] = get_is_visible
	return option_data

enum BorderType {
	None = 0,
	Transparent = 1,
	Extruded = 2
}
const SPRITE_SHEET_BORDER_TYPES: PackedStringArray = ["None", "Transparent", "Extruded"]

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

const OPTION_SPRITE_SHEET_FIXED_ROWS_COUNT: String = "sprite_sheet/fixed_rows_count"
const OPTION_SPRITE_SHEET_FIXED_COLUMNS_COUNT: String = "sprite_sheet/fixed_columns_count"
const OPTION_SPRITE_SHEET_BORDER_TYPE: String = "sprite_sheet/border_type"
const OPTION_SPRITE_SHEET_TRIM: String = "sprite_sheet/trim"
const OPTION_SPRITE_SHEET_IGNORE_EMPTY: String = "sprite_sheet/ignore_empty"
const OPTION_SPRITE_SHEET_MERGE_DUPLICATES: String = "sprite_sheet/merge_duplicates"
const OPTION_SPRITE_SHEET_LAYOUT: String = "sprite_sheet/layout"
const OPTION_SPRITE_SHEET_LAYERS_INCLUDE_REG_EX: String = "layers/include_reg_ex"
const OPTION_SPRITE_SHEET_LAYERS_EXCLUDE_REG_EX: String = "layers/exclude_reg_ex"

class ParsedSpriteSheetOptions:
	var border_type: BorderType
	var trim: bool
	var ignore_empty: bool
	var merge_duplicates: bool
	var sprite_sheet_layout: SpriteSheetLayout
	var sprite_sheet_fixed_rows_count: int
	var sprite_sheet_fixed_columns_count: int
	#var layers_include_regex: String
	#var layers_exclude_regex: String
	func _init(options: Dictionary) -> void:
		border_type = SPRITE_SHEET_BORDER_TYPES.find(options[OPTION_SPRITE_SHEET_BORDER_TYPE])
		trim = options[OPTION_SPRITE_SHEET_TRIM]
		ignore_empty = options[OPTION_SPRITE_SHEET_IGNORE_EMPTY]
		merge_duplicates = options[OPTION_SPRITE_SHEET_MERGE_DUPLICATES]
		sprite_sheet_layout = SPRITE_SHEET_LAYOUTS.find(options[OPTION_SPRITE_SHEET_LAYOUT])
		sprite_sheet_fixed_rows_count = options[OPTION_SPRITE_SHEET_FIXED_ROWS_COUNT]
		sprite_sheet_fixed_columns_count = options[OPTION_SPRITE_SHEET_FIXED_COLUMNS_COUNT]
#		layers_include_regex = options[OPTION_LAYERS_INCLUDE_REG_EX]
#		layers_exclude_regex = options[OPTION_LAYERS_EXCLUDE_REG_EX]

const OPTION_ANIMATION_DEFAULT_NAME: String = "animation/default/name"
const OPTION_ANIMATION_DEFAULT_DIRECTION: String = "animation/default/direction"
const OPTION_ANIMATION_DEFAULT_REPEAT_COUNT: String = "animation/default/repeat_count"
const OPTION_ANIMATION_AUTOPLAY_NAME: String = "animation/autoplay"
const OPTION_ANIMATION_STRATEGY: String = "animation/strategy"
const OPTION_ANIMATION_TAGS_INCLUDE_REG_EX: String = "tags/include_reg_ex"
const OPTION_ANIMATION_TAGS_EXCLUDE_REG_EX: String = "tags/exclude_reg_ex"

class ParsedAnimationOptions:
	var default_animation_name: String
	var default_animation_direction: AnimationDirection
	var default_animation_repeat_count: int
	var animation_autoplay_name: String
	#var tags_include_regex: String
	#var tags_exclude_regex: String
	func _init(options: Dictionary) -> void:
		default_animation_name = options[OPTION_ANIMATION_DEFAULT_NAME].strip_edges().strip_escapes()
		if default_animation_name.is_empty(): default_animation_name = "default"
		default_animation_direction = PRESET_OPTIONS_ANIMATION_DIRECTIONS.find(options[OPTION_ANIMATION_DEFAULT_DIRECTION])
		default_animation_repeat_count = options[OPTION_ANIMATION_DEFAULT_REPEAT_COUNT]
		animation_autoplay_name = options[OPTION_ANIMATION_AUTOPLAY_NAME].strip_edges().strip_escapes()
#		tags_include_regex = options[OPTION_TAGS_INCLUDE_REG_EX]
#		tags_exclude_regex = options[OPTION_TAGS_EXCLUDE_REG_EX]

# It's a pity, but options typed PROPERTY_HINT_ENUM cannot be cast to a numeric type today (2023.04.09),
# because there is some kind of bug in the engine. Because of it, the first initialization
# with a default value occurs with string value of the first element passed in the HintString.
# After changing the option in the editor, the normal numeric value is already set. Hope this gets fixed soon.
# The problem is located here:
# https://github.com/godotengine/godot/blob/e9c7b8d2246bd0797af100808419c994fa43a9d2/editor/editor_file_system.cpp#L1855

static func create_common_sprite_sheet_options() -> Array[Dictionary]:
	return [
		create_option(OPTION_SPRITE_SHEET_LAYOUT, SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.PACKED], PROPERTY_HINT_ENUM, ",".join(SPRITE_SHEET_LAYOUTS), PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED ),
		create_option(OPTION_SPRITE_SHEET_FIXED_ROWS_COUNT, 0, PROPERTY_HINT_RANGE, "0,32,1,or_greater", PROPERTY_USAGE_EDITOR,
			func(options): return options[OPTION_SPRITE_SHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.BY_COLUMNS]),
		create_option(OPTION_SPRITE_SHEET_FIXED_COLUMNS_COUNT, 0, PROPERTY_HINT_RANGE, "0,32,1,or_greater", PROPERTY_USAGE_EDITOR,
			func(options): return options[OPTION_SPRITE_SHEET_LAYOUT] == SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.BY_ROWS]),
		create_option(OPTION_SPRITE_SHEET_BORDER_TYPE, SPRITE_SHEET_BORDER_TYPES[BorderType.None], PROPERTY_HINT_ENUM, ",".join(SPRITE_SHEET_BORDER_TYPES), PROPERTY_USAGE_EDITOR),
		create_option(OPTION_SPRITE_SHEET_TRIM, false, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR,
			func(options): return options[OPTION_SPRITE_SHEET_LAYOUT] != SPRITE_SHEET_LAYOUTS[SpriteSheetLayout.PACKED]),
		create_option(OPTION_SPRITE_SHEET_IGNORE_EMPTY, false, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_SPRITE_SHEET_MERGE_DUPLICATES, false, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_SPRITE_SHEET_LAYERS_INCLUDE_REG_EX, "*", PROPERTY_HINT_PLACEHOLDER_TEXT, "*", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_SPRITE_SHEET_LAYERS_EXCLUDE_REG_EX, "", PROPERTY_HINT_PLACEHOLDER_TEXT, "", PROPERTY_USAGE_EDITOR),
	]

static func create_common_animation_options() -> Array[Dictionary]:
	return [
		create_option(OPTION_ANIMATION_DEFAULT_NAME, "default", PROPERTY_HINT_PLACEHOLDER_TEXT, "default", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_DEFAULT_DIRECTION, PRESET_OPTIONS_ANIMATION_DIRECTIONS[0], PROPERTY_HINT_ENUM, ",".join(PRESET_OPTIONS_ANIMATION_DIRECTIONS), PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_DEFAULT_REPEAT_COUNT, 0, PROPERTY_HINT_RANGE, "0,32,1,or_greater", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_AUTOPLAY_NAME, "", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_TAGS_INCLUDE_REG_EX, "*", PROPERTY_HINT_PLACEHOLDER_TEXT, "*", PROPERTY_USAGE_EDITOR),
		create_option(OPTION_ANIMATION_TAGS_EXCLUDE_REG_EX, "", PROPERTY_HINT_PLACEHOLDER_TEXT, "", PROPERTY_USAGE_EDITOR)
	]
