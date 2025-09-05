# Universal Sky
# Description:
# - Base for sky material.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
extends Resource
class_name SkyMaterialBase

#region Shader Param Names
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
const MOON_TEXTURE_YAW_OFFSET_PARAM:= &"moon_texture_yaw_offset"
const MOON_MIE_COLOR_PARAM:= &"atm_moon_mie_color"
const MOON_MIE_INTENSITY_PARAM:= &"atm_moon_mie_intensity"
const MOON_MIE_ANISOTROPY_PARAM:= &"atm_moon_mie_anisotropy"
#endregion

var _material:= ShaderMaterial.new()
var material: ShaderMaterial:
	get: return _material

var _compatibility: bool = false
var is_compatibility: bool:
	get: return _compatibility

func _init() -> void: # Tree
	_on_init()

func _on_init() -> void: # POO
	initialize_params()

func initialize_params() -> void:
	_initialize_params()

func _initialize_params() -> void:
	_initialize_default_celestial_values()

func material_is_valid() -> bool:
	return _material_is_valid()

func _material_is_valid() -> bool:
	return false

func set_compatibility(value: bool) -> void:
	_compatibility = value
	_compatibility_changed()

func _compatibility_changed() -> void:
	_update_sun_color(sun_color)
	_update_sun_mie_color(sun_mie_color)
	_update_moon_color(moon_color)
	_update_moon_mie_color(moon_mie_color)

func _initialize_default_celestial_values() -> void:
	_set_default_sun_values()
	_set_default_moon_values()

func _set_default_sun_values() -> void:
	sun_intensity_multiplier = 1.0
	_update_sun_direction(Vector3.ZERO)
	_update_sun_color(Color.BLANCHED_ALMOND)
	_update_sun_intensity(2.0)
	_update_sun_size(0.5)
	_update_sun_mie_color(Color.WHITE)
	_update_sun_mie_intensity(1.0)
	_update_sun_mie_anisotropy(0.8)

func _set_default_moon_values() -> void:
	moon_intensity_multiplier = 1.0
	_update_moon_direction(Vector3.ZERO)
	_update_moon_texture(null)
	_update_moon_texture_yaw_offset(-0.3)
	_update_moon_color(Color.WHITE)
	_update_moon_intensity(0.5)
	_update_moon_size(1.0)
	
	_update_moon_mie_color(Color.WHITE)
	_update_moon_mie_intensity(1.0)
	_update_moon_mie_anisotropy(0.8)

#region Sun
var sun_direction:= Vector3.ZERO:
	get: return sun_direction
	set(value):
		sun_direction = value
		_update_sun_direction(sun_direction)

var sun_color:= Color.BLANCHED_ALMOND:
	get: return sun_color
	set(value):
		sun_color = value
		_update_sun_color(sun_color)

var sun_intensity: float = 2.0:
	get: return sun_intensity
	set(value):
		sun_intensity = value
		_update_sun_intensity(sun_intensity)

var sun_intensity_multiplier: float = 1.0:
	get: return sun_intensity_multiplier
	set(value):
		sun_intensity_multiplier = value
		_update_sun_intensity_multiplier(sun_intensity_multiplier)

var sun_size: float = 0.5:
	get: return sun_size
	set(value):
		sun_size = value
		_update_sun_size(sun_size)

var sun_mie_color:= Color.WHITE:
	get: return sun_mie_color
	set(value):
		sun_mie_color = value
		_update_sun_mie_color(sun_mie_color)

var sun_mie_intensity: float = 1.0:
	get: return sun_mie_intensity
	set(value):
		sun_mie_intensity = value
		_update_sun_mie_intensity(sun_mie_intensity)

var sun_mie_anisotropy: float = 0.8:
	get: return sun_mie_anisotropy
	set(value):
		sun_mie_anisotropy = value
		_update_sun_mie_anisotropy(sun_mie_anisotropy)

var sun_eclipse_intensity: float = 1.0:
	get: return sun_eclipse_intensity
	set(value):
		sun_eclipse_intensity = value
		_update_sun_eclipse_intensity(sun_eclipse_intensity)

func _update_sun_intensity_multiplier(p_multiplier: float) -> void:
	_update_sun_intensity(sun_intensity)
	_update_sun_mie_intensity(sun_mie_intensity)
	emit_changed()

func _update_sun_direction(p_direction: Vector3) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_DIRECTION_PARAM, p_direction
	)
	emit_changed()

func _update_sun_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_COLOR_PARAM, p_color.srgb_to_linear() if _compatibility else p_color
	)
	emit_changed()

func _update_sun_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_INTENSITY_PARAM, p_intensity * sun_intensity_multiplier
	)
	emit_changed()

func _update_sun_size(p_size: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_SIZE_PARAM, p_size
	)
	emit_changed()

func _update_sun_mie_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_MIE_COLOR_PARAM, p_color.srgb_to_linear() if _compatibility else p_color
	)
	emit_changed()

func _update_sun_mie_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_MIE_INTENSITY_PARAM, p_intensity * sun_intensity_multiplier
	)
	emit_changed()

func _update_sun_mie_anisotropy(p_anisotropy: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_MIE_ANISOTROPY_PARAM, p_anisotropy
	)
	emit_changed()

func _update_sun_eclipse_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), &"sun_eclipse_intensity", p_intensity
	)
	emit_changed()
#endregion

#region Moon
var moon_direction:= Vector3.ZERO:
	get: return moon_direction
	set(value):
		moon_direction = value
		_update_moon_direction(moon_direction)

var moon_matrix: Basis:
	get: return moon_matrix
	set(value):
		moon_matrix = value
		_update_moon_matrix(moon_matrix)

var moon_texture: Texture2D = null:
	get: return moon_texture
	set(value):
		moon_texture = value
		_update_moon_texture(moon_texture)

var moon_texture_yaw_offset: float = -0.3:
	get: return moon_texture_yaw_offset
	set(value):
		moon_texture_yaw_offset = value
		_update_moon_texture_yaw_offset(moon_texture_yaw_offset)

var moon_color:= Color.WHITE:
	get: return moon_color
	set(value):
		moon_color = value
		_update_moon_color(moon_color)

var moon_intensity: float = 0.5:
	get: return moon_intensity
	set(value):
		moon_intensity = value
		_update_moon_intensity(moon_intensity)

var moon_intensity_multiplier: float = 1.0:
	get: return moon_intensity_multiplier
	set(value):
		moon_intensity_multiplier = value
		_update_moon_intensity_multiplier(moon_intensity_multiplier)

var moon_size: float = 1.0:
	get: return moon_size
	set(value):
		moon_size = value
		_update_moon_size(moon_size)

var moon_mie_color:= Color.WHITE:
	get: return moon_mie_color
	set(value):
		moon_mie_color = value
		_update_moon_mie_color(moon_mie_color)

var moon_mie_intensity: float = 1.0:
	get: return moon_mie_intensity
	set(value):
		moon_mie_intensity = value
		_update_moon_mie_intensity(moon_mie_intensity)

var moon_mie_anisotropy: float = 0.8:
	get: return moon_mie_anisotropy
	set(value):
		moon_mie_anisotropy = value
		_update_moon_mie_anisotropy(moon_mie_anisotropy)

var moon_phases_mul: float = 1.0:
	get: return moon_phases_mul
	set(value):
		moon_phases_mul = value
		emit_changed()

func _update_moon_intensity_multiplier(p_multiplier: float) -> void:
	_update_moon_intensity(moon_intensity)
	_update_moon_mie_intensity(moon_mie_intensity)
	emit_changed()

func _update_moon_direction(p_direction: Vector3) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_DIRECTION_PARAM, p_direction
	)
	emit_changed()

func _update_moon_matrix(p_matrix: Basis) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MATRIX_PARAM, p_matrix
	)
	emit_changed()

func _update_moon_texture_yaw_offset(p_offset: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_TEXTURE_YAW_OFFSET_PARAM, p_offset
	)
	emit_changed()

func _update_moon_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_COLOR_PARAM, p_color.srgb_to_linear() if _compatibility else p_color
	)
	emit_changed()

func _update_moon_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_INTENSITY_PARAM, p_intensity * moon_intensity_multiplier
	)
	emit_changed()

func _update_moon_size(p_size: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(),MOON_SIZE_PARAM, p_size
	)
	emit_changed()

func _update_moon_texture(p_texture: Texture2D) -> void:
	material.set_shader_parameter(MOON_TEXTURE_PARAM, p_texture)
	emit_changed()

func _update_moon_mie_color(p_color: Color) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MIE_COLOR_PARAM, p_color.srgb_to_linear() if _compatibility else p_color
	)
	emit_changed()

func _update_moon_mie_intensity(p_intensity: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MIE_INTENSITY_PARAM, p_intensity * moon_intensity_multiplier
	)
	emit_changed()

func _update_moon_mie_anisotropy(p_anisotropy: float) -> void:
	RenderingServer.material_set_param(
		material.get_rid(), MOON_MIE_ANISOTROPY_PARAM, p_anisotropy
	)
	emit_changed()
#endregion
