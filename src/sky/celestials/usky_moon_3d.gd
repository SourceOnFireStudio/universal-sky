@tool
extends USkyCelestialBody3D
class_name USkyMoon3D

#region Resources
const _DEFAULT_MOON_MAP_TEXTURE:= preload(
	"res://addons/universal-sky/assets/textures/moon/MoonMap.png"
)
#endregion

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
		emit_signal(VALUE_CHANGED, BodyValueType.TEXTURE)

@export_group("Light Source")
@export
var sun: USkySun3D:
	get: return sun
	set(value):
		if is_instance_valid(value):
			sun = value
			_connect_sun_signals()
		else:
			_disconnect_sun_signals()
			sun = value

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

var phases_mul: float:
	get: 
		if is_instance_valid(sun):
			return clamp(-sun.direction.dot(direction) + 0.50, 0.0, 1.0)
		return 1.0

var clamped_matrix: Basis:
	get: return Basis(
		-(basis * Vector3.FORWARD),
		-(basis * Vector3.UP),
		-(basis * Vector3.RIGHT)
	).transposed()

var sun_moon_light_curve: Curve = Curve.new()

func _on_init() -> void:
	super()
	sun_moon_light_curve.add_point(Vector2(0, 0), 0.0, 0.0, 0, 0)
	sun_moon_light_curve.add_point(Vector2(0.617886, 0), 0.0, 0.0467088, 1, 0)
	sun_moon_light_curve.add_point(Vector2(0.69899, 1), 0.0, 0.0, 0, 0)
	sun_moon_light_curve.add_point(Vector2(1, 1), 0.0, 0.0, 0, 0)
	sun_moon_light_curve.bake()
	
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

func _validate_property(property: Dictionary) -> void:
	if not use_custom_texture && property.name == "texture":
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _get_light_energy() -> float:
	var energy = super()
	if enable_light_moon_phases:
		energy *= phases_mul
	if is_instance_valid(sun) && is_instance_valid(sun_moon_light_curve):
		var fade: float = (1.0 - sun.direction.y) - 0.5
		return energy * sun_moon_light_curve.sample_baked(fade)
	
	return energy

func _connect_sun_signals() -> void:
	if not sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.connect(_on_sun_direction_changed)

func _disconnect_sun_signals() -> void:
	if sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.disconnect(_on_sun_direction_changed)

func _on_sun_direction_changed() -> void:
	_update_light_energy()
