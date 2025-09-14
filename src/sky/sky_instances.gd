# Universal Sky
# Description:
# - Sky instances in current scene.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
extends Node

signal pre_instance_added
signal pre_instance_removed

signal instance_added
signal instance_removed

var instances: Array[SkyHandler3D]:
	get: return instances

var current_instance: SkyHandler3D:
	get: 
		if instances.size() > 0:
			return instances[0]
		return null

func set_instance(p_instance: SkyHandler3D) -> void:
	pre_instance_removed.emit()
	instances.push_back(p_instance)
	instance_added.emit()

func remove_instance(p_instance: SkyHandler3D) -> void:
	pre_instance_removed.emit()
	instances.erase(p_instance)
	instance_removed.emit()
