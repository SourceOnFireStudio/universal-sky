# Universal Sky
# Description:
# - Sky instances in current scene.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
extends Node

var instances: Array[SkyHandler]:
	get: return instances

var current_instance: SkyHandler:
	get: return instances[0]

func set_instance(p_instance: SkyHandler) -> void:
	instances.push_back(p_instance)

func remove_instance(p_instance: SkyHandler) -> void:
	instances.erase(p_instance)
