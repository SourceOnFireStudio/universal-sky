# Universal Sky
# Description:
# - Sun celestial body.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
extends USkyCelestialBody3D
class_name USkySun3D

@export
var moon: USkyMoon3D:
	get: return moon
	set(value):
		if is_instance_valid(value):
			moon = value
			_connect_moon_signals()
		else:
			_disconnect_moon_signals()
			moon = value

@export_group("Eclipse")
@export
var eclipse_threshold: float = -0.01:
	get: return eclipse_threshold
	set(value):
		eclipse_threshold = value
		_update_eclipse()

@export
var eclipse_slope: float = 200:
	get: return eclipse_slope
	set(value):
		eclipse_slope = value
		_update_eclipse()

@export
var min_eclipse_attenuation: float = 0.01:
	get: return min_eclipse_attenuation
	set(value):
		min_eclipse_attenuation = value
		_update_eclipse()

func _on_init() -> void:
	super()
	body_color = Color(1, 0.7058, 0.4470)
	body_intensity = 10.0
	body_size = 1.0

func _connect_moon_signals() -> void:
	if not is_instance_valid(moon):
		return
	if not moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.connect(_on_moon_direction_changed)

func _disconnect_moon_signals() -> void:
	if not is_instance_valid(moon):
		return
	if moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.disconnect(_on_moon_direction_changed)

func _update_params() -> void:
	super()
	_update_eclipse()

func _on_moon_direction_changed() -> void:
	_update_eclipse()

func _update_eclipse() -> void:
	if not is_instance_valid(moon):
		return
	const celestialSizeBase = 0.017453293
	var sunSize = body_size * celestialSizeBase
	var moonSize = moon.body_size * celestialSizeBase
	var threshold = eclipse_threshold - (-sunSize - moonSize)
	var factor = USkyMath.angular_intensity_sig(
		direction, moon.direction, threshold, eclipse_slope
	)
	factor = clamp(factor, min_eclipse_attenuation, 1.0) \
		if sunSize <= moonSize + celestialSizeBase else clamp(factor, 0.9, 1.0)
	
	_eclipse_multiplier = factor
	_update_light_energy()
