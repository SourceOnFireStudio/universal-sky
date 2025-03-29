@tool
extends Node
class_name UniversalSky

@export_group("Resources")
@export
var material: USkyMaterialBase = null:
	get: return material
	set(value):
		material = value
		if is_instance_valid(material):
			if not material.material_is_valid():
				push_warning(
					"this {material} is abstract resource class, please add valid material"
					.format({"material": material.get_class()})
				)
				material = null
			else:
				_set_sky_material_to_enviro()
				_connect_enviro_changed()
				_update_celestials_data()

#region Enviro
@export_group("Enviroment")
@export
var enviro_container: NodePath:
	get: return enviro_container
	set(value):
		enviro_container = value
		if enviro_container.is_empty():
			_disconnect_enviro_changed()
			if _enviro != null && _enviro.sky != null:
				_enviro.sky.sky_material = null
			_enviro = null
		else:
			var container = get_node_or_null(value)
			if is_instance_of(container, Camera3D) || \
				is_instance_of(container, WorldEnvironment):
					if container.environment == null:
						push_warning("enviroment resource not found")
						enviro_container = NodePath()
						return
					_enviro = container.environment
			_connect_enviro_changed()
			_set_sky_material_to_enviro()

@export_enum("Automatic", "High Quality", "Incremental", "Realtime")
var sky_process_mode: int = 2:
	get: return sky_process_mode
	set(value):
		sky_process_mode = value
		if is_instance_valid(_enviro) and is_instance_valid(_enviro.sky):
			_enviro.sky.process_mode = sky_process_mode

@export_enum("32", "64", "128", "256", "512", "1024", "2048")
var sky_radiance_size: int = 1:
	get: return sky_radiance_size
	set(value):
		sky_radiance_size = value
		if is_instance_valid(_enviro) and is_instance_valid(_enviro.sky):
			_enviro.sky.radiance_size = sky_radiance_size

var _enviro: Environment = null
var enviro: Environment:
	get: return _enviro
#endregion

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
#endregions

#region Setup

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			material = material
			enviro_container = enviro_container
		NOTIFICATION_EXIT_TREE:
			if is_instance_valid(_enviro):
				_enviro.sky.sky_material = null
				_disconnect_enviro_changed()

func _check_material_ready() -> bool: 
	if not is_instance_valid(material):
		return false
	if not material.material_is_valid():
		return false
	return true

func _set_sky_material_to_enviro() -> void:
	if not is_instance_valid(_enviro):
		_disconnect_enviro_changed()
		return
		
	_enviro.background_mode = Environment.BG_SKY
	if not is_instance_valid(_enviro.sky):
		_enviro.sky = Sky.new()
		_enviro.sky.process_mode = sky_process_mode
		_enviro.sky.radiance_size = sky_radiance_size
	
	if is_instance_valid(material):
		_enviro.sky.sky_material = material.material
		_on_enviro_changed()
	else:
		_enviro.sky.sky_material = null


func _on_enviro_changed() -> void:
	pass

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

#region Sun Direction
func _on_sun_direction_changed() -> void:
	if not _check_material_ready() || not is_instance_valid(sun):
		return
	
	if is_instance_valid(moon):
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

#region Connections
func _connect_enviro_changed() -> void:
	#if not is_instance_valid(_enviro):
		#return
#
	#if !enviro.property_list_changed.is_connected(_on_enviro_changed):
		#enviro.property_list_changed.connect(_on_enviro_changed)
	pass

func _disconnect_enviro_changed() -> void:
	#if is_instance_valid(_enviro):
		#return
	#if enviro.property_list_changed.is_connected(_on_enviro_changed):
		#enviro.property_list_changed.disconnect(_on_enviro_changed)
	pass

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


func _get_configuration_warnings() -> PackedStringArray:
	if not is_instance_valid(sun):
		return ["Sun unassigned"]
	if not is_instance_valid(moon):
		return ["Moon unassigned"]
	if not is_instance_valid(material):
		return ["Material unassigned"]
	
	return []
