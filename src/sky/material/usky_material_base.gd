# Universal Sky
# Description:
# - Sky material base.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
extends Resource
class_name USkyMaterialBase

#region Shader Param names
const SUN_DIRECTION_PARAM:= &"sun_direction"
const SUN_COLOR_PARAM:= &"sun_color"
const SUN_INTENSITY_PARAM:= &"sun_intensity"
const SUN_SIZE_PARAM:= &"sun_size"
const MOON_MATRIX_PARAM:= &"moon_matrix"
const SUN_MIE_COLOR_PARAM:= &"atm_sun_mie_color"
const SUN_MIE_INTENSITY_PARAM:= &"atm_sun_mie_intensity"
const SUN_MIE_ANISOTROPY_PARAM:= &"atm_sun_mie_anisotropy"

const MOON_DIRECTION_PARAM:= &"moon_direction"
const MOON_COLOR_PARAM:= &"moon_color"
const MOON_INTENSITY_PARAM:= &"moon_intensity"
const MOON_SIZE_PARAM:= &"moon_size"
const MOON_TEXTURE_PARAM:=&"moon_texture"
const MOON_MIE_COLOR_PARAM:= &"atm_moon_mie_color"
const MOON_MIE_INTENSITY_PARAM:= &"atm_moon_mie_intensity"
const MOON_MIE_ANISOTROPY_PARAM:= &"atm_moon_mie_anisotropy"
#endregion

var _material:= ShaderMaterial.new()
var material: ShaderMaterial:
	get: return _material

func _init() -> void:
	_on_init()

func _on_init() -> void:
	#sky_material = ShaderMaterial.new()
	#_material.render_priority = -128
	_initialize_default_celestial_values()

# Avoid black sky when creating new material without celestial bodies.
func _initialize_default_celestial_values():
	set_default_sun_values()
	set_default_moon_values()

func set_default_sun_values() -> void:
	sun_intensity_multiplier = 1.0
	_update_sun_direction(Vector3.ZERO)
	_update_sun_size(0.5)
	_update_sun_intensity(2.0)
	_update_sun_color(Color.BLANCHED_ALMOND)
	_update_sun_mie_color(Color.WHITE)
	_update_sun_mie_intensity(1.0)
	_update_sun_mie_anisotropy(0.8)

func set_default_moon_values() -> void:
	moon_intensity_multiplier = 1.0
	_update_moon_direction(Vector3.ZERO)
	_update_moon_size(1.0)
	_update_moon_intensity(0.5)
	_update_moon_color(Color.WHITE)
	_update_moon_texture(null)
	_update_moon_mie_color(Color.WHITE)
	_update_moon_mie_intensity(1.0)
	_update_moon_mie_anisotropy(0.8)

func material_is_valid() -> bool:
	return false

#region Sun
var sun_intensity_multiplier: float:
	get: return sun_intensity_multiplier
	set(value):
		sun_intensity_multiplier = value
		_update_sun_intensity_multiplier(sun_intensity_multiplier)

func _update_sun_intensity_multiplier(p_multiplier: float) -> void:
	_update_sun_intensity(sun_intensity)
	_update_sun_mie_intensity(sun_mie_intensity)
	emit_changed()

var sun_direction: Vector3:
	get: return sun_direction
	set(value):
		sun_direction = value
		_update_sun_direction(sun_direction)

func _update_sun_direction(p_direction: Vector3) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_DIRECTION_PARAM, p_direction
	)
	emit_changed()

var sun_color: Color:
	get: return sun_color
	set(value):
		sun_color = value
		_update_sun_color(sun_color)

func _update_sun_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_COLOR_PARAM, p_color
	)
	emit_changed()

var sun_intensity: float:
	get: return sun_intensity
	set(value):
		sun_intensity = value
		_update_sun_intensity(sun_intensity)

func _update_sun_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_INTENSITY_PARAM, p_intensity * sun_intensity_multiplier
	)
	emit_changed()

var sun_size: float:
	get: return sun_size
	set(value):
		sun_size = value
		_update_sun_size(sun_size)

func _update_sun_size(p_size: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_SIZE_PARAM, p_size
	)
	emit_changed()

var sun_mie_color: Color:
	get: return sun_mie_color
	set(value):
		sun_mie_color = value
		_update_sun_mie_color(sun_mie_color)

func _update_sun_mie_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_MIE_COLOR_PARAM, p_color
	)
	emit_changed()

var sun_mie_intensity: float:
	get: return sun_mie_intensity
	set(value):
		sun_mie_intensity = value
		_update_sun_mie_intensity(sun_mie_intensity)

func _update_sun_mie_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_MIE_INTENSITY_PARAM, p_intensity * sun_intensity_multiplier
	)
	emit_changed()

var sun_mie_anisotropy: float:
	get: return sun_mie_anisotropy
	set(value):
		sun_mie_anisotropy = value
		_update_sun_mie_anisotropy(sun_mie_anisotropy)

func _update_sun_mie_anisotropy(p_anisotropy: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_MIE_ANISOTROPY_PARAM, p_anisotropy
	)
	emit_changed()

var sun_eclipse_intensity: float:
	get: return sun_eclipse_intensity
	set(value):
		sun_eclipse_intensity = value
		_update_sun_eclipse_intensity(sun_eclipse_intensity)

func _update_sun_eclipse_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), &"sun_eclipse_intensity", p_intensity
	)
	emit_changed()
#endregion

#region Moon
var moon_intensity_multiplier: float:
	get: return moon_intensity_multiplier
	set(value):
		moon_intensity_multiplier = value
		_update_moon_intensity_multiplier(moon_intensity_multiplier)

func _update_moon_intensity_multiplier(p_multiplier: float) -> void:
	_update_moon_intensity(moon_intensity)
	_update_moon_mie_intensity(moon_mie_intensity)
	emit_changed()

var moon_direction: Vector3:
	get: return moon_direction
	set(value):
		moon_direction = value
		_update_moon_direction(moon_direction)

func _update_moon_direction(p_direction: Vector3) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_DIRECTION_PARAM, p_direction
	)
	emit_changed()

var moon_matrix: Basis:
	get: return moon_matrix
	set(value):
		moon_matrix = value
		_update_moon_matrix(moon_matrix)

func _update_moon_matrix(p_matrix: Basis) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MATRIX_PARAM, p_matrix
	)
	emit_changed()

var moon_color: Color:
	get: return moon_color
	set(value):
		moon_color = value
		_update_moon_color(moon_color)

func _update_moon_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_COLOR_PARAM, p_color
	)
	emit_changed()

var moon_intensity: float:
	get: return moon_intensity
	set(value):
		moon_intensity = value
		_update_moon_intensity(moon_intensity)

func _update_moon_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_INTENSITY_PARAM, p_intensity * moon_intensity_multiplier
	)
	emit_changed()

var moon_size: float:
	get: return moon_size
	set(value):
		moon_size = value
		_update_moon_size(moon_size)

func _update_moon_size(p_size: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(),MOON_SIZE_PARAM, p_size
	)
	emit_changed()

var moon_texture: Texture2D:
	get: return moon_texture
	set(value):
		moon_texture = value
		_update_moon_texture(moon_texture)

func _update_moon_texture(p_texture: Texture2D) -> void:
	material.set_shader_parameter(MOON_TEXTURE_PARAM, p_texture)
	emit_changed()

var moon_mie_color: Color:
	get: return moon_mie_color
	set(value):
		moon_mie_color = value
		_update_moon_mie_color(moon_mie_color)

func _update_moon_mie_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MIE_COLOR_PARAM, p_color
	)
	emit_changed()

var moon_mie_intensity: float:
	get: return moon_mie_intensity
	set(value):
		moon_mie_intensity = value
		_update_moon_mie_intensity(moon_mie_intensity)

func _update_moon_mie_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MIE_INTENSITY_PARAM, p_intensity * moon_intensity_multiplier
	)
	emit_changed()

var moon_mie_anisotropy: float:
	get: return moon_mie_anisotropy
	set(value):
		moon_mie_anisotropy = value
		_update_moon_mie_anisotropy(moon_mie_anisotropy)

func _update_moon_mie_anisotropy(p_anisotropy: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MIE_ANISOTROPY_PARAM, p_anisotropy
	)
	emit_changed()

var moon_phases_mul: float:
	get: return moon_phases_mul
	set(value):
		moon_phases_mul = value
		emit_changed()
#endregion
