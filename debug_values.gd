extends RichTextLabel
class_name DebugValues

static var instance: DebugValues

var values_dict := {}

func _ready() -> void:
    instance = self

func _process(_delta: float) -> void:
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