extends RichTextLabel
class_name DebugValues

static var instance: DebugValues

var values_dict := {}

func _ready() -> void:
    instance = self

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("debug_toggle"):
        if visible:
            hide()
        else:
            show()
    rewrite_text()

func rewrite_text() -> void:
    text = ""
    for key in values_dict.keys():
        var value = values_dict[key]
        text += str(key) + ": " + str(value) + "\n"

static func debug(key, value):
    instance.values_dict[key] = value

static func remove(key):
    instance.values_dict.erase(key)