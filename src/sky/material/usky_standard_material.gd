@tool
extends USkyMaterialBase
class_name USkyStandardMaterial

const SHADER:= preload(
	"res://addons/universal-sky/src/sky/shaders/sky/standard-sky/usky_standard_sky.gdshader"
)

#region Shader params
const TONEMAP_LEVEL_PARAM:= &"tonemap_level"
const EXPOSURE_PARAM:= &"exposure"
const HORIZON_LEVEL_PARAM:= &"horizon_level"

const ATM_CONTRAST_PARAM:= &"atm_contrast"
const ATM_SUN_E_PARAM:= &"atm_sunE"
const ATM_RAYLEIGH_LEVEL_PARAM:= &"atm_rayleigh_level"
const ATM_THICKNESS_PARAM:= &"atm_thickness"

const ATM_BETA_RAY_PARAM:= &"atm_beta_ray"
const ATM_BETA_MIE_PARAM:= &"atm_beta_mie"
const ATM_GROUND_COLOR_PARAM:= &"atm_ground_color"

const SUN_UMUS_PARAM:= &"sun_uMuS"
const SUN_PARTIAL_MIE_PHASE_PARAM:= &"atm_sun_partial_mie_phase"
const MOON_PARTIAL_MIE_PHASE_PARAM:= &"atm_moon_partial_mie_phase"

const DAY_TINT_PARAM:= &"atm_day_tint"
const NIGHT_TINT_PARAM:= &"atm_night_tint"
#endregion

#region Atmospheric scattering const
# Index of the air refraction.
const n: float = 1.0003

# Index of the air refraction ˆ 2.
const n2: float = 1.00060009

# Molecular Density.
const N: float = 2.545e25

# Depolatization factor for standard air.
const pn: float = 0.035
#endregion

#region General Settings
@export_group("General Settings")
@export
var tonemap_level: float = 0.0:
	get: return tonemap_level
	set(value):
		tonemap_level = value
		RenderingServer.material_set_param(
			material.get_rid(), TONEMAP_LEVEL_PARAM, tonemap_level
		)
		emit_changed()

@export
var exposure: float = 1.0:
	get: return exposure
	set(value):
		exposure = value
		RenderingServer.material_set_param(
			material.get_rid(), EXPOSURE_PARAM, exposure
		)
		emit_changed()

@export_range(-1.0, 1.0)
var horizon_level: float = 0.0:
	get: return horizon_level
	set(value):
		horizon_level = value
		RenderingServer.material_set_param(
			material.get_rid(), HORIZON_LEVEL_PARAM, horizon_level
		)
		emit_changed()
#endregion

#region Atmosphere
@export_group("Atmosphere", "atm_")
@export_range(0.0, 1.0)
var atm_contrast: float = 0.1:
	get: return atm_contrast
	set(value):
		atm_contrast = value
		RenderingServer.material_set_param(
			material.get_rid(), ATM_CONTRAST_PARAM, atm_contrast
		)
		emit_changed()

@export_subgroup("Rayleigh", "atm_")
@export
var atm_wavelenghts:= Vector3(680.0, 550.0, 440.0):
	get: return atm_wavelenghts
	set(value):
		atm_wavelenghts = value
		_set_beta_ray()

@export
var atm_rayleigh_level: float = 1.0:
	get: return atm_rayleigh_level
	set(value):
		atm_rayleigh_level = value
		RenderingServer.material_set_param(
			material.get_rid(), ATM_RAYLEIGH_LEVEL_PARAM, atm_rayleigh_level
		)
		emit_changed()

@export
var atm_thickness: float = 1.0:
	get: return atm_thickness
	set(value):
		atm_thickness = value
		RenderingServer.material_set_param(
			material.get_rid(), ATM_THICKNESS_PARAM, atm_thickness
		)
		emit_changed()

@export_subgroup("Mie", "atm_")
@export
var atm_mie: float = 0.07:
	get: return atm_mie
	set(value):
		atm_mie = value
		_set_beta_mie()
		emit_changed()

@export
var atm_turbidity: float = 0.001:
	get: return atm_turbidity
	set(value):
		atm_turbidity = value
		_set_beta_mie()
		emit_changed()

@export_subgroup("Day", "atm_")
@export
var atm_sun_intensity: float = 15.0:
	get: return atm_sun_intensity
	set(value):
		atm_sun_intensity = value
		RenderingServer.material_set_param(
			material.get_rid(), ATM_SUN_E_PARAM, atm_sun_intensity
		)
		emit_changed()

@export
var atm_day_gradient: Gradient:
	get: return atm_day_gradient
	set(value):
		atm_day_gradient = value
		if is_instance_valid(value):
			_disconnect_changed_atm_day_gradient()
			_connect_changed_atm_day_gradient()
		
		_set_atm_day_tint()
		emit_changed()

@export_subgroup("Night", "atm_")
@export
var atm_night_intensity: float = 1.0:
	get: return atm_night_intensity
	set(value):
		atm_night_intensity = value
		_set_atm_night_tint()
		emit_changed()

@export
var atm_enable_night_scattering: bool = false:
	get: return atm_enable_night_scattering
	set(value):
		atm_enable_night_scattering = value
		_update_sun_direction(sun_direction)
		_update_moon_direction(moon_direction)
		emit_changed()

@export
var atm_night_tint:= Color(0.254902, 0.337255, 0.447059):
	get: return atm_night_tint
	set(value):
		atm_night_tint = value
		_set_atm_night_tint()
		emit_changed()

@export_subgroup("Ground", "atm_")
@export
var atm_ground_color:= Color(0.543, 0.543, 0.543): # Color(0.204, 0.345, 0.467):
	get: return atm_ground_color
	set(value):
		atm_ground_color = value
		RenderingServer.material_set_param(
			material.get_rid(), ATM_GROUND_COLOR_PARAM, atm_ground_color * 5.0
		)
		emit_changed()
#endregion

#region Setup
func material_is_valid() -> bool:
	return true

func _on_init() -> void:
	super()
	material.shader = SHADER
	
	tonemap_level = tonemap_level
	exposure = exposure
	horizon_level = horizon_level
	
	atm_contrast = atm_contrast
	atm_wavelenghts = atm_wavelenghts
	atm_rayleigh_level = atm_rayleigh_level
	atm_thickness = atm_thickness
	
	atm_mie = atm_mie
	atm_turbidity = atm_turbidity
	
	atm_sun_intensity = atm_sun_intensity
	atm_day_gradient = atm_day_gradient
	
	atm_night_intensity = atm_night_intensity
	atm_enable_night_scattering = atm_enable_night_scattering
	atm_night_tint = atm_night_tint
	
	atm_ground_color = atm_ground_color

func _connect_changed_atm_day_gradient() -> void:
	if !atm_day_gradient.changed.is_connected(_set_atm_day_tint):
		atm_day_gradient.changed.connect(_set_atm_day_tint)

func _disconnect_changed_atm_day_gradient() -> void:
	if atm_day_gradient.changed.is_connected(_set_atm_day_tint):
		atm_day_gradient.changed.disconnect(_set_atm_day_tint)

#endregion



func _update_sun_direction(p_direction: Vector3) -> void:
	super(p_direction)
	_set_sun_uMuS()
	_set_atm_day_tint()
	_set_atm_night_tint()

func _update_moon_direction(p_direction: Vector3) -> void:
	super(p_direction)
	_set_sun_uMuS()
	_set_atm_night_tint()

#region Atmospheric Scattering
func get_celestial_uMus(dir: Vector3) -> float:
	return 0.015 + (atan(max(dir.y, - 0.1975) * tan(1.386))
		* 0.9090 + 0.74) * 0.5 * (0.96875);

func compute_wavelenghts_lambda(value: Vector3) -> Vector3:
	return value * 1e-9

func compute_wavelenghts(value: Vector3, computeLambda: bool = false) -> Vector3:
	var k: float = 4.0
	var ret: Vector3 = value
	if computeLambda:
		ret = compute_wavelenghts_lambda(ret)
	
	ret.x = pow(ret.x, k)
	ret.y = pow(ret.y, k)
	ret.z = pow(ret.z, k)
	return ret

func compute_beta_ray(wavelenghts: Vector3) -> Vector3:
	var kr: float =  (8.0 * pow(PI, 3.0) * pow(n2 - 1.0, 2.0) * (6.0 + 3.0 * pn))
	var ret: Vector3 = 3.0 * N * wavelenghts * (6.0 - 7.0 * pn)
	ret.x = kr / ret.x
	ret.y = kr / ret.y
	ret.z = kr / ret.z
	return ret

func compute_beta_mie(mie: float, turbidity: float) -> Vector3:
	var k: float = 434e-6
	return Vector3.ONE * mie * turbidity * k

func get_partial_mie_phase(g: float) -> Vector3:
	var g2 = g * g
	var ret: Vector3
	ret.x = ((1.0 - g2) / (2.0 + g2))
	ret.y = 1.0 + g2
	ret.z = 2.0 * g
	return ret

func _set_sun_uMuS() -> void:
	RenderingServer.material_set_param(
		material.get_rid(), SUN_UMUS_PARAM, get_celestial_uMus(sun_direction)
	)
	emit_changed()

func _update_sun_mie_anisotropy(p_anisotropy: float) -> void:
	p_anisotropy = clamp(p_anisotropy, 0.0, 0.999)
	var partial:= get_partial_mie_phase(p_anisotropy)
	RenderingServer.material_set_param(
		material.get_rid(), SUN_PARTIAL_MIE_PHASE_PARAM, partial
	)
	emit_changed()

func _update_moon_mie_anisotropy(p_anisotropy: float) -> void:
	p_anisotropy = clamp(p_anisotropy, 0.0, 0.999)
	var partial:= get_partial_mie_phase(p_anisotropy)
	RenderingServer.material_set_param(
		material.get_rid(), MOON_PARTIAL_MIE_PHASE_PARAM, partial
	)
	emit_changed()

func _set_beta_ray() -> void:
	var wls:= compute_wavelenghts(atm_wavelenghts, true)
	var br:= compute_beta_ray(wls)
	RenderingServer.material_set_param(
		material.get_rid(), ATM_BETA_RAY_PARAM, br
	)
	emit_changed()

func _set_beta_mie() -> void:
	var bm:= compute_beta_mie(atm_mie, atm_turbidity)
	RenderingServer.material_set_param(
		material.get_rid(), ATM_BETA_MIE_PARAM, bm
	)
	emit_changed()

func _set_atm_day_tint() -> void:
	RenderingServer.material_set_param(
		material.get_rid(), DAY_TINT_PARAM,
		atm_day_gradient.sample(USkyUtil.interpolate_by_above(sun_direction.y))
		if is_instance_valid(atm_day_gradient) else Color.WHITE
	)
	emit_changed()

func get_atm_night_intensity() -> float:
	var ret = 0.0
	if not atm_enable_night_scattering:
		ret = clamp(-sun_direction.y + 0.50, 0.0, 1.0)
	else:
		ret = get_celestial_uMus(moon_direction)
	
	return ret * atm_night_intensity * get_atm_moon_phases_mul()

func get_atm_moon_phases_mul() -> float:
	if atm_enable_night_scattering:
		return moon_phases_mul
	return 1.0

func _set_atm_night_tint() -> void:
	var tint:= atm_night_tint * get_atm_night_intensity()
	RenderingServer.material_set_param(
		material.get_rid(), NIGHT_TINT_PARAM, tint
	)
	_update_moon_mie_intensity(moon_mie_intensity)
	emit_changed()
#endregion
