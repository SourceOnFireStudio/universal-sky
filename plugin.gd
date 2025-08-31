@tool
extends EditorPlugin

const _SKY_INSTANCES_NAME:= "SkyInstances"
const _SKY_INSTANCES_PATH:= "res://addons/universal-sky/src/sky/sky_instances.gd"

func _enter_tree() -> void:
	add_autoload_singleton(_SKY_INSTANCES_NAME, _SKY_INSTANCES_PATH)

func _exit_tree() -> void:
	remove_autoload_singleton(_SKY_INSTANCES_NAME)
