# Universal Sky
# Description:
# - Moon.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool 
@icon("res://addons/universal-sky/assets/icons/moon.svg")
extends CelestialBody3D
class_name Moon3D

const _DEFAULT_MOON_MAP_TEXTURE:= preload(
	"res://addons/universal-sky/assets/textures/moon/MoonMap.png"
)

signal yaw_offset_changed

var _light_transition_curve: Curve

var _sun: Sun3D:
	get: return _sun

var phases_mul: float:
	get:
		if is_instance_valid(_sun):
			return clamp(-_sun.direction.dot(_sun.direction) + 0.50, 0.0, 1.0)
		return 1.0

var clamped_matrix: Basis:
	get: return Basis(
		-(basis * Vector3.FORWARD),
		-(basis * Vector3.UP),
		-(basis * Vector3.RIGHT)
	).transposed()

@export_group("Texture")
@export
var use_custom_texture: bool = false:
	get: return use_custom_texture
	set(value):
		use_custom_texture = value
		if value:
			texture = texture
		else:
			texture = _DEFAULT_MOON_MAP_TEXTURE
		notify_property_list_changed()

@export
var texture: Texture = null:
	get: return texture
	set(value):
		texture = value
		param_changed.emit(CelestialParam.TEXTURE)

@export
var yaw_offset: float = -0.3:
	get: return yaw_offset
	set(value):
		yaw_offset = value
		yaw_offset_changed.emit()

@export_group("Phases")
@export
var enable_mie_phases: bool = false:
	get: return enable_mie_phases
	set(value):
		enable_mie_phases = value

@export
var enable_light_moon_phases: bool = false:
	get: return enable_light_moon_phases
	set(value):
		enable_light_moon_phases = value
		_update_light_energy()

@export_group("Light Transition")
@export
var light_transition_threshold: float = 0.8:
	get: return light_transition_threshold
	set(value):
		light_transition_threshold = value
		_update_light_energy()

@export
var light_transition_curve: Curve:
	get: return _light_transition_curve
	set(value):
		if is_instance_valid(value):
			_light_transition_curve = value
			_connect_light_transition_curve_changed()
		elif is_instance_valid(_light_transition_curve):
			_disconnect_light_transition_curve_changed()
			_light_transition_curve = null
		_update_light_energy()

#region Godot Node Overrides
func _on_init() -> void:
	super()
	body_size =  1.0
	body_intensity = 1.0
	body_color = Color.WHITE
	lighting_color = Color(0.54, 0.7, 0.9)
	lighting_energy = 0.3
	mie_color = Color(0.623, 0.786, 1.0)
	mie_intensity = 1.0
	
	# Initialize moon params.
	use_custom_texture = use_custom_texture
	texture = texture
	enable_light_moon_phases = enable_light_moon_phases
	light_transition_curve = light_transition_curve
	light_transition_threshold = light_transition_threshold

func _validate_property(property: Dictionary) -> void:
	if not use_custom_texture and property.name == "texture":
		property.usage &= ~PROPERTY_USAGE_EDITOR
#endregion

#region Connections
func _connect_sun_signals() -> void:
	if not _sun.direction_changed.is_connected(_on_sun_direction_changed):
		_sun.direction_changed.connect(_on_sun_direction_changed)

func _disconnect_sun_signals() -> void:
	if _sun.direction_changed.is_connected(_on_sun_direction_changed):
		_sun.direction_changed.disconnect(_on_sun_direction_changed)

func _connect_light_transition_curve_changed() -> void:
	if not _light_transition_curve.changed.is_connected(_on_light_transition_curve_changed):
		_light_transition_curve.changed.connect(_on_light_transition_curve_changed)

func _disconnect_light_transition_curve_changed() -> void:
	if _light_transition_curve.changed.is_connected(_on_light_transition_curve_changed):
		_light_transition_curve.changed.disconnect(_on_light_transition_curve_changed)
#endregion

# References
func set_sun(p_sun: Sun3D) -> void:
	if is_instance_valid(p_sun):
		_sun = p_sun
		_connect_sun_signals()
	else:
		_disconnect_sun_signals()
		_sun = null

#region Signal Events
func _on_sun_direction_changed() -> void:
	_update_light_energy()

func _on_light_transition_curve_changed() -> void: 
	_update_light_energy()
#endregion

# Lighting
func _get_light_energy() -> float:
	var energy: float = super()
	if enable_light_moon_phases:
		energy *= phases_mul

	if is_instance_valid(_sun):
		var invLE = 1.0 - clamp(_sun.light_energy, 0.0, 1.0)
		if is_instance_valid(light_transition_curve):
			var fade: float = clamp(invLE - (1.0-light_transition_threshold), 0.0, 1.0);
			return energy * light_transition_curve.sample_baked(fade)
			
		else:
			var fade: float = clamp(invLE - light_transition_threshold, 0.0, 1.0)
			return energy * lerp(0.0, 1.0, fade);
	
	return energy

func get_final_moon_mie_intensity() -> float:
	if enable_mie_phases:
		return mie_intensity * phases_mul
	return mie_intensity
