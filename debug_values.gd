extends RichTextLabel
class_name DebugValues

static var instance: DebugValues

static var categories: Dictionary[String, CategoryData] = {}

func _ready() -> void:
	instance = self

var was_toggled := false
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		if visible:
			hide()
		else:
			show()
	
	var is_toggled = false
	if Input.is_key_pressed(KEY_CTRL):
		for cat in categories.values():
			if cat.toggle_key != KEY_NONE and Input.is_key_pressed(cat.toggle_key):
				if not was_toggled:
					cat.is_enabled = not cat.is_enabled
				is_toggled = true
				break
	
	was_toggled = is_toggled

	rewrite_text()

func rewrite_text() -> void:
	text = ""
	for cat in categories.values():
		if not cat.is_enabled: continue

		if cat.name != "":
			text += cat.name + ": =======\n"
		
		for key in cat.values.keys():
			var value = cat.values[key]
			text += str(key) + ": " + str(value) + "\n"

static func category(cat_name, toggle_key:=KEY_NONE, default_enable:=false):
	if not str(cat_name) in categories:
		var new_category = CategoryData.new()
		new_category.name = cat_name
		new_category.toggle_key = toggle_key
		new_category.is_enabled = default_enable
		categories[str(cat_name)] = new_category
		if toggle_key != KEY_NONE:
			category("HELP", KEY_H, false)
			debug("CTRL+" + OS.get_keycode_string(toggle_key), "Toggle " + cat_name, "HELP")
	
static var is_first := true
static func debug(key, value, cat_name="BASIC"):
	if is_first:
		is_first = false
		category("BASIC", KEY_D, true)
		debug("CTRL+H", "Toggle Help")
		debug("CTRL+D", "Toggle Basic")
	var cat := categories[cat_name]
	if not cat: return

	cat.values[key] = value

static func remove(key, cat_name=""):
	var cat := categories[cat_name]
	if not cat: return

	cat.values.erase(key)


class CategoryData:
	extends RefCounted

	var name: String
	var toggle_key := KEY_NONE
	var is_enabled := false
	var values := {}