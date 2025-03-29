@tool
extends EditorPlugin

const _sky_script = preload("res://addons/universal-sky/src/sky/sky-manager/usky3d.gd")
const _sky_icon = preload("res://addons/universal-sky/assets/icons/Sky.svg")

const _sun_script = preload("res://addons/universal-sky/src/sky/celestials/usky_sun_3d.gd")
const _sun_icon = preload("res://addons/universal-sky/assets/icons/sun.svg")

const _moon_script = preload("res://addons/universal-sky/src/sky/celestials/usky_moon_3d.gd")
const _moon_icon = preload("res://addons/universal-sky/assets/icons/moon.svg")

func _enter_tree() -> void:
	add_custom_type("USky3D", "Node3D", _sky_script, _sky_icon)
	add_custom_type("USkySun3D", "DirectionalLight3D", _sun_script, _sun_icon)
	add_custom_type("USkyMoon3D", "DirectionalLight3D", _moon_script, _moon_icon)

func _exit_tree() -> void:
	remove_custom_type("USky3D")
	remove_custom_type("USkySun3D")
	remove_custom_type("USkyMoon3D")
