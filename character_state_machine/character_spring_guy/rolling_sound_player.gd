extends AudioStreamPlayer
class_name RollingSoundPlayer

const min_playback_speed: float = 0.2
const playback_speed_max_volume: float = 0.4

const revs_per_loop: int = 30

var sound_length: float

var shift = AudioEffectPitchShift.new()

func _ready() -> void:
	shift.pitch_scale = 1.0

	sound_length = stream.get_length()

	AudioServer.add_bus_effect(AudioServer.get_bus_index(bus), shift)

func set_playback_speed_to(speed_multiplier: float) -> void:
	pitch_scale = speed_multiplier
	shift.pitch_scale = 1.0 / speed_multiplier

#func set_wheel_speed(speed_radians: float) -> void:
