# Universal Sky
# Description:
# - Dynamic skydome.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool
class_name USkyDome3D extends Node3D

#region Drawer
const DEFAULT_SKY_SHADER:= preload(
	"res://addons/universal-sky/src/sky/shaders/sky/default_skydome.gdshader"
)
var _dome_drawer:= USkyDomeDrawer.new()
var _dome_mesh:= SphereMesh.new()
var _dome_material: ShaderMaterial = null
#endregion

@export_group("Dome Settings")
@export
var dome_visible: bool = true:
	get: return dome_visible
	set(value):
		dome_visible = value
		_dome_drawer.set_visible(dome_visible)

@export_enum("Low", "Medium", "High")
var dome_mesh_quality: int = 0:
	get: return dome_mesh_quality
	set(value):
		dome_mesh_quality = value
		_change_dome_mesh_quality(dome_mesh_quality)

@export_flags_3d_render
var dome_layers: int = 4:
	get:
		return dome_layers
	set(value):
		dome_layers = value
		_dome_drawer.set_layers(dome_layers)

@export_color_no_alpha
var default_dome_color:= Color(0.166, 0.245, 0.379):
	get: return default_dome_color
	set(value):
		default_dome_color = value
		RenderingServer.material_set_param(
			_dome_material.get_rid(), &"background_color", default_dome_color
		)

@export_group("Resources")
@export
var material: USkyMaterialBase = null:
	get: return material
	set(value):
		material = value
		if not is_instance_valid(value):
			_dome_material = null
			_initialize_default_material()
			_dome_drawer.set_material(_dome_material)
		else:
			if not material.material_is_valid():
				push_warning(
					"this {material} is abstract resource class, please add valid material"
					.format({"material": material.get_class()})
				)
				material = null
			else:
				_dome_material = material.material
				_set_sky_material_to_dome(material.material)
				_update_celestials_data()

#region Celestials
@export_group("Celestials")
@export
var sun: USkySun3D = null:
	get: return sun
	set(value):
		if is_instance_valid(value):
			sun = value
			_connect_sun_signals()
		else:
			_disconnect_sun_signals()
			if is_instance_valid(material):
				material.set_default_sun_values()
			sun = value
		_update_celestials_data()

@export
var moon: USkyMoon3D = null:
	get: return moon
	set(value):
		if is_instance_valid(value):
			moon = value
			_connect_moon_signals()
		else:
			_disconnect_moon_signals()
			if is_instance_valid(material):
				material.set_default_moon_values()
			moon = value
		_update_celestials_data()
#endregion

#region Setup
func _init() -> void:
	_change_dome_mesh_quality(dome_mesh_quality)
	_initialize_default_material()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_dome_drawer.draw(get_world_3d(), _dome_mesh, _dome_material)
			_initialize_dome_params()
		NOTIFICATION_EXIT_TREE:
			_dome_drawer.clear()
		NOTIFICATION_PREDELETE:
			_dome_drawer.clear()

func _initialize_dome_params() -> void:
	dome_visible = dome_visible
	dome_layers = dome_layers

func _initialize_default_material() -> void:
	_dome_material = ShaderMaterial.new()
	_dome_material.shader = DEFAULT_SKY_SHADER
	_dome_material.render_priority = -128
	default_dome_color = default_dome_color

func _change_dome_mesh_quality(p_quality: int) -> void:
	if not is_instance_valid(_dome_mesh):
		return
	match p_quality:
			0: 
				_dome_mesh.radial_segments = 16
				_dome_mesh.rings = 8
			1: 
				_dome_mesh.radial_segments = 32
				_dome_mesh.rings = 32
			2: 
				_dome_mesh.radial_segments = 64
				_dome_mesh.rings = 90

func _set_sky_material_to_dome(p_material: ShaderMaterial) -> void:
	_dome_drawer.set_material(p_material)

func _check_material_ready() -> bool: 
	if not is_instance_valid(material):
		return false
	if not material.material_is_valid():
		return false
	return true

func _update_celestials_data() -> void:
	_update_sun_data()
	_update_moon_data()

func _update_sun_data() -> void:
	_on_sun_direction_changed()
	for i in range(0, 3):
		_on_sun_value_changed(i)
		_on_sun_mie_value_changed(i)

func _update_moon_data() -> void:
	_on_moon_direction_changed()
	for i in range(0, 3):
		_on_moon_mie_value_changed(i)
	for i in range(0, 4):
		_on_moon_value_changed(i)
#endregion

#region Celestials Signal Connection
func _connect_sun_signals() -> void:
	# Direction
	if not sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.connect(_on_sun_direction_changed)
	
	# Body
	if not sun.value_changed.is_connected(_on_sun_value_changed):
		sun.value_changed.connect(_on_sun_value_changed)
	
	# Mie
	if not sun.mie_value_changed.is_connected(_on_sun_mie_value_changed):
		sun.mie_value_changed.connect(_on_sun_mie_value_changed)

func _disconnect_sun_signals() -> void:
	# Direction
	if sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.disconnect(_on_sun_direction_changed)
	
	# Body
	if sun.value_changed.is_connected(_on_sun_value_changed):
		sun.value_changed.disconnect(_on_sun_value_changed)
	
	# Mie
	if sun.mie_value_changed.is_connected(_on_sun_mie_value_changed):
		sun.mie_value_changed.disconnect(_on_sun_mie_value_changed)

func _connect_moon_signals() -> void:
	# Direction
	if not moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.connect(_on_moon_direction_changed)
	
	# Body
	if not moon.value_changed.is_connected(_on_moon_value_changed):
		moon.value_changed.connect(_on_moon_value_changed)
	
	# Mie
	if not moon.mie_value_changed.is_connected(_on_moon_mie_value_changed):
		moon.mie_value_changed.connect(_on_moon_mie_value_changed)

func _disconnect_moon_signals() -> void:
	# Direction
	if moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.disconnect(_on_moon_direction_changed)
	
	# Body
	if moon.value_changed.is_connected(_on_moon_value_changed):
		moon.value_changed.disconnect(_on_moon_value_changed)
	
	# Mie
	if moon.mie_value_changed.is_connected(_on_moon_mie_value_changed):
		moon.mie_value_changed.disconnect(_on_moon_mie_value_changed)
#endregion

#region Sun Direction
func _on_sun_direction_changed() -> void:
	if not _check_material_ready() || not is_instance_valid(sun):
		return
	
	if is_instance_valid(moon):
		print("MOON")
		_on_moon_direction_changed()
		_update_moon_mie_intensity()
	material.sun_direction = sun.direction
#endregion

#region Sun Values
func _on_sun_value_changed(p_type: int) -> void:
	if not _check_material_ready() || not is_instance_valid(sun):
		return
	
	match(p_type):
		USkyCelestialBody3D.BodyValueType.COLOR:
			_update_sun_color()
		USkyCelestialBody3D.BodyValueType.INTENSITY:
			_update_sun_intensity()
		USkyCelestialBody3D.BodyValueType.SIZE:
			_update_sun_size()

func _update_sun_color() -> void:
	material.sun_color = sun.body_color

func _update_sun_intensity() -> void:
	material.sun_intensity = sun.body_intensity

func _update_sun_size() -> void:
	material.sun_size = sun.body_size
#endregion

#region Sun Mie Values
func _on_sun_mie_value_changed(p_type: int) -> void:
	if not _check_material_ready() || not is_instance_valid(sun):
		return
	
	match(p_type):
		USkyCelestialBody3D.MieValueType.COLOR:
			_update_sun_mie_color()
		USkyCelestialBody3D.MieValueType.INTENSITY:
			_update_sun_mie_intensity()
		USkyCelestialBody3D.MieValueType.ANISOTROPY:
			_update_sun_mie_anisotropy()

func _update_sun_mie_color() -> void:
	material.sun_mie_color = sun.mie_color

func _update_sun_mie_intensity() -> void:
	material.sun_mie_intensity = sun.mie_intensity

func _update_sun_mie_anisotropy() -> void:
	material.sun_mie_anisotropy = sun.mie_anisotropy
#endregion

#region Moon Direction
func _on_moon_direction_changed() -> void:
	if not _check_material_ready() || not is_instance_valid(moon):
		return
	print("UPDATE_MOON_DIRECTION")
	material.moon_direction = moon.direction
	material.moon_phases_mul = moon.phases_mul
	material.moon_matrix = moon.clamped_matrix
	_update_moon_mie_intensity()
#endregion

#region Moon Values
func _on_moon_value_changed(p_type: int) -> void:
	if not _check_material_ready() || not is_instance_valid(moon):
		return
	match(p_type):
		USkyMoon3D.BodyValueType.COLOR:
			_update_moon_color()
		USkyMoon3D.BodyValueType.INTENSITY:
			_update_moon_intensity()
		USkyMoon3D.BodyValueType.SIZE:
			_update_moon_size()
		USkyMoon3D.BodyValueType.TEXTURE:
			_update_moon_texture()

func _update_moon_color() -> void:
	material.moon_color = moon.body_color

func _update_moon_intensity() -> void:
	material.moon_instensity = moon.body_intensity

func _update_moon_size() -> void:
	material.moon_size = moon.body_size

func _update_moon_texture() -> void:
	material.moon_texture = moon.texture
#endregion

#region Mie Value
func _on_moon_mie_value_changed(p_type: int) -> void:
	if not _check_material_ready() || not is_instance_valid(moon):
		return
	match(p_type):
		USkyMoon3D.MieValueType.COLOR:
			_update_moon_mie_color()
		USkyMoon3D.MieValueType.INTENSITY:
			_update_moon_mie_intensity()
		USkyMoon3D.MieValueType.ANISOTROPY:
			_update_moon_mie_anisotropy()

func _update_moon_mie_color() -> void:
	material.moon_mie_color = moon.mie_color

func _update_moon_mie_intensity() -> void:
	if moon.enable_mie_phases:
		material.moon_mie_intensity = moon.mie_intensity * moon.phases_mul
	else:
		material.moon_mie_intensity = moon.mie_intensity

func _update_moon_mie_anisotropy() -> void:
	material.moon_mie_anisotropy = moon.mie_anisotropy
#endregion
