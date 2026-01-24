@tool
extends Node
class_name RandomizedSoundPlayer

signal finished(node_to_be_removed: AudioStreamPlayer, source_node: AudioStreamPlayer)

@export
var sound_selection: Array[AudioStreamPlayer]

@export
var pitch_variation := InputMinMax.new()

@export
var volume_linear_variation := InputMinMax.new()

var playing_sounds: Array[AudioStreamPlayer]

func play() -> void:
	if len(sound_selection) == 0: return

	var source_node: AudioStreamPlayer = sound_selection.pick_random()

	var sound_node := source_node.duplicate()
	source_node.add_sibling(sound_node)
	playing_sounds.push_back(sound_node)

	sound_node.pitch_scale *= pitch_variation.generate_value()
	sound_node.volume_linear *= volume_linear_variation.generate_value()
	sound_node.play()

	await sound_node.finished
	finished.emit(sound_node, source_node)
	sound_node.queue_free()
	var idx = playing_sounds.find(sound_node)
	if idx != null:
		playing_sounds.remove_at(idx)

func stop() -> void:
	for sound_node in playing_sounds:
		sound_node.finished.emit()