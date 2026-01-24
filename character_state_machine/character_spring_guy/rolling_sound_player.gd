extends AudioStreamPlayer
class_name RollingSoundPlayer

const min_playback_speed: float = 0.1
const playback_speed_max_volume: float = 0.3

const revs_per_sound_length: int = 30

var sound_length_seconds: float
var sound_revs_per_minute: float

var shift := AudioEffectPitchShift.new()

func _ready() -> void:
	finished.connect(_on_finished)
	shift.pitch_scale = 1.0
	shift.oversampling = 8

	sound_length_seconds = stream.get_length()
	sound_revs_per_minute = (revs_per_sound_length / sound_length_seconds) * 60

	AudioServer.remove_bus_effect(AudioServer.get_bus_index(bus), 0)
	AudioServer.add_bus_effect(AudioServer.get_bus_index(bus), shift, 0)

	play()
	stream_paused = true

func set_playback_speed_to(speed_multiplier: float) -> void:
	# There is no speed_scale option in Godot, only pitch_scale,
	#  but the AudioStreamPlayer.pitch_scale changes the pitch and speed,
	#  while the AudioEffectPitchShift.pitch_scale changes the pitch without changing speed
	#  so by counteracting one with the other we effectively change speed without changing the pitch
	pitch_scale = speed_multiplier
	shift.pitch_scale = 1.0 / speed_multiplier

func process_wheel_speed(speed_radians_per_second: float) -> void:
	var wheel_revs_per_minute := speed_radians_per_second / (2 * PI) * 60

	var speed_multiplier = wheel_revs_per_minute / sound_revs_per_minute

	if (speed_multiplier < min_playback_speed):
		stream_paused = true
	else:
		set_playback_speed_to(speed_multiplier)
		stream_paused = false

		if speed_multiplier < playback_speed_max_volume:
			var progress: float = (speed_multiplier - min_playback_speed) / (playback_speed_max_volume - min_playback_speed)
			volume_linear = progress
		else:
			volume_linear = 1

func _on_finished() -> void:
	play()