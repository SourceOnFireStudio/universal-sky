# Universal Sky
# Description:
# - Celestial body base.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
extends DirectionalLight3D
class_name USkyCelestialBody3D

#region Enums
enum BodyValueType{ COLOR = 0, INTENSITY = 1, SIZE = 2, TEXTURE = 3 }
enum MieValueType{ COLOR = 0, INTENSITY = 1, ANISOTROPY = 2 }
#endregion

#region Signals
const DIRECTION_CHANGED:= &"direction_changed"
const VALUE_CHANGED:= &"value_changed"
const MIE_VALUE_CHANGED:= &"mie_value_changed"
signal direction_changed()
signal value_changed(type)
signal mie_value_changed(type)
signal intensity_multiplier_changed
#endregion

@export
var intensity_multiplier: float = 1.0:
	get: return intensity_multiplier
	set(value):
		intensity_multiplier = value
		_on_intensity_multiplier()

@export_group("Body")
@export
var body_color:= Color.BISQUE:
	get: return body_color
	set(value):
		body_color = value
		emit_signal(VALUE_CHANGED, BodyValueType.COLOR)

@export
var body_intensity: float = 1.0:
	get: return body_intensity
	set(value):
		body_intensity = value
		emit_signal(VALUE_CHANGED, BodyValueType.INTENSITY)

@export
var body_size: float = 1.0:
	get: return body_size
	set(value):
		body_size = value
		emit_signal(VALUE_CHANGED, BodyValueType.SIZE)

@export_group("Mie")
@export_color_no_alpha
var mie_color:= Color.WHITE:
	get: return mie_color
	set(value):
		mie_color = value
		emit_signal(MIE_VALUE_CHANGED, MieValueType.COLOR)

@export
var mie_intensity: float = 1.0:
	get: return mie_intensity
	set(value):
		mie_intensity = value
		emit_signal(MIE_VALUE_CHANGED, MieValueType.INTENSITY)

@export_range(0.0, 0.9999)
var mie_anisotropy: float = 0.85:
	get: return mie_anisotropy
	set(value):
		mie_anisotropy = value
		emit_signal(MIE_VALUE_CHANGED, MieValueType.ANISOTROPY)

#region Lighting
@export_group("Lighting")
@export
var lighting_color:= Color(0.984314, 0.843137, 0.788235):
	get: return lighting_color
	set(value):
		lighting_color = value
		_update_light_color()

@export
var lighting_gradient: Gradient = null:
	get: return lighting_gradient
	set(value):
		lighting_gradient = value
		if !is_instance_valid(lighting_gradient):
			_disconnect_light_gradient_changed()
		_connect_light_gradient_changed()
		_update_light_color()

@export
var lighting_energy: float = 1.0:
	get: return lighting_energy
	set(value):
		lighting_energy = value
		_update_light_energy()

@export
var lighting_energy_curve: Curve = null:
	get: return lighting_energy_curve
	set(value):
		lighting_energy_curve = value
		if !is_instance_valid(lighting_energy_curve):
			_disconnect_light_curve_changed()
		_connect_light_curve_changed()
		_update_light_energy()
#endregion

var direction: Vector3:
	get: return -(basis * Vector3.FORWARD)

func _init() -> void:
	_on_init()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_params()
	if what == NOTIFICATION_ENTER_TREE:
		_on_enter_tree()
	if what == NOTIFICATION_EXIT_TREE:
		_on_exit_tree()

func _on_init() -> void:
	lighting_color = lighting_color
	lighting_gradient = lighting_gradient
	lighting_energy = lighting_energy
	lighting_energy_curve = lighting_energy_curve
	intensity_multiplier = intensity_multiplier

func _on_enter_tree() -> void:
	intensity_multiplier = intensity_multiplier

func _on_exit_tree() -> void:
	pass

func _on_intensity_multiplier() -> void:
	emit_signal("intensity_multiplier_changed")
	_update_light_energy()

func _update_params() -> void:
	_update_light_color()
	_update_light_energy()
	emit_signal(DIRECTION_CHANGED)

func _update_light_color() -> void:
	if is_instance_valid(lighting_gradient):
		light_color = lighting_gradient.sample(
			USkyUtil.interpolate_by_above(direction.y)
		)
	else:
		light_color = lighting_color

func _update_light_energy() -> void:
	light_energy = _get_light_energy() * intensity_multiplier

func _get_light_energy() -> float:
	if lighting_energy_curve != null:
		return lighting_energy_curve.sample(USkyUtil.interpolate_by_above(direction.y))
	return lerp(0.0, lighting_energy, clamp(direction.y, 0.0, 1.0))

#region Light gradient
func _connect_light_gradient_changed() -> void:
	if not is_instance_valid(lighting_gradient):
		return
	if !lighting_gradient.changed.is_connected(_on_light_gradient_changed):
		lighting_gradient.changed.connect(_on_light_gradient_changed)

func _disconnect_light_gradient_changed() -> void:
	if not is_instance_valid(lighting_gradient):
		return
	if lighting_gradient.changed.is_connected(_on_light_gradient_changed):
		lighting_gradient.changed.disconnect(_on_light_gradient_changed)

func _on_light_gradient_changed() -> void:
	_update_light_color()
#endregion

#region Light Curve
func _connect_light_curve_changed() -> void:
	if not is_instance_valid(lighting_energy_curve):
		return
	if !lighting_energy_curve.changed.is_connected(_on_light_curve_changed):
		lighting_energy_curve.changed.connect(_on_light_curve_changed)

func _disconnect_light_curve_changed() -> void:
	if not is_instance_valid(lighting_energy_curve):
		return
	if lighting_energy_curve.changed.is_connected(_on_light_curve_changed):
		lighting_energy_curve.changed.disconnect(_on_light_curve_changed)

func _on_light_curve_changed() -> void:
	_update_light_energy()
#endregion
