# Universal Sky
# Description:
# - Sun celestial body.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
extends USkyCelestialBody3D
class_name USkySun3D

func _on_init() -> void:
	super()
	body_color = Color(1, 0.7058, 0.4470)
	body_intensity = 2.0
	body_size = 1.0
