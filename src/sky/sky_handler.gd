# Universal Sky
# Description:
# - Sky Manager.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool 
@icon("res://addons/universal-sky/assets/icons/Sky.svg")
extends Node
class_name SkyHandler 

var _tree: SceneTree
var _enviro: Environment = null

var sun: Sun3D:
	get: return sun

var moon: Moon3D:
	get: return moon

var enviro: Environment:
	get: return _enviro

@export_group("Resources")
@export
var material: SkyMaterialBase:
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
			#if _enviro != null && _enviro.sky != null:
				#_enviro.sky.sky_material = null
			if is_instance_valid(_enviro) && is_instance_valid(_enviro.sky):
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

#endregion

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			SkyInstances.set_instance(self)
			_tree = get_tree()
			_connect_child_tree_signals()
			material = material
			enviro_container = enviro_container
			sky_process_mode = sky_process_mode
			sky_radiance_size = sky_radiance_size
		NOTIFICATION_EXIT_TREE:
			_disconnect_child_tree_signals()
			SkyInstances.remove_instance(self)
			_tree = null
			if is_instance_valid(_enviro):
				_enviro.sky.sky_material = null
				_disconnect_enviro_changed()

func _get_configuration_warnings() -> PackedStringArray:
	if not is_instance_valid(sun):
		return ["Sun unassigned"]
	if not is_instance_valid(moon):
		return ["Moon unassigned"]
	if not is_instance_valid(material):
		return ["Material unassigned"]
	return []

#region Connections

func _connect_child_tree_signals() -> void:
	if not child_entered_tree.is_connected(_on_child_entered_tree):
		child_entered_tree.connect(_on_child_entered_tree)
		
	if not child_exiting_tree.is_connected(_on_child_exiting_tree):
		child_exiting_tree.connect(_on_child_exiting_tree)

func _disconnect_child_tree_signals() -> void:
	if child_entered_tree.is_connected(_on_child_entered_tree):
		child_entered_tree.disconnect(_on_child_entered_tree)
			
	if child_exiting_tree.is_connected(_on_child_exiting_tree):
		child_exiting_tree.disconnect(_on_child_exiting_tree)

func _connect_enviro_changed() -> void:
	pass

func _disconnect_enviro_changed() -> void:
	pass

func _connect_sun_signals() -> void:
	# Direction
	if not sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.connect(_on_sun_direction_changed)
	
	# Values
	if not sun.value_changed.is_connected(_on_sun_value_changed):
		sun.value_changed.connect(_on_sun_value_changed)

func _disconnect_sun_signals() -> void:
	# Direction
	if sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.disconnect(_on_sun_direction_changed)
	
	# Values
	if sun.value_changed.is_connected(_on_sun_value_changed):
		sun.value_changed.disconnect(_on_sun_value_changed)

func _connect_moon_signals() -> void:
	# Direction
	if not moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.connect(_on_moon_direction_changed)
	
	# Values
	if not moon.value_changed.is_connected(_on_moon_value_changed):
		moon.value_changed.connect(_on_moon_value_changed)
	
	if not moon.yaw_offset_changed.is_connected(_on_moon_yaw_offset_changed):
		moon.yaw_offset_changed.connect(_on_moon_yaw_offset_changed)

func _disconnect_moon_signals() -> void:
	# Direction
	if moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.disconnect(_on_moon_direction_changed)
	
	# Values
	if moon.value_changed.is_connected(_on_moon_value_changed):
		moon.value_changed.disconnect(_on_moon_value_changed)
	
	if moon.yaw_offset_changed.is_connected(_on_moon_yaw_offset_changed):
		moon.yaw_offset_changed.disconnect(_on_moon_yaw_offset_changed)

#endregion

#region Setup

func _on_child_entered_tree(p_node: Node) -> void:
	if p_node is Sun3D and not is_instance_valid(sun):
		sun = p_node
		if is_instance_valid(sun):
			_connect_sun_signals()
		
		if  is_instance_valid(sun) && is_instance_valid(moon):
			sun.set_moon(moon)
			moon.set_sun(sun)
		
		_update_celestials_data()

	if p_node is Moon3D and not is_instance_valid(moon):
		moon = p_node
		
		if is_instance_valid(moon):
			_connect_moon_signals()
		
		if is_instance_valid(sun)  && is_instance_valid(moon):
			moon.set_sun(sun)
			sun.set_moon(moon)
		
		_update_celestials_data()

func _on_child_exiting_tree(p_node: Node) -> void:
	if p_node is Sun3D and p_node.get_instance_id() == sun.get_instance_id():
		_disconnect_sun_signals()
		if is_instance_valid(material):
			material.set_default_sun_values()
		
		if is_instance_valid(moon):
			moon.set_sun(null)
		sun = null
		
		_update_celestials_data()

	if p_node is Moon3D and p_node.get_instance_id() == moon.get_instance_id():
		_disconnect_moon_signals()
		if is_instance_valid(material):
			material.set_default_moon_values()
		
		if is_instance_valid(sun):
			sun.set_moon(null)
		moon = null
		
		_update_celestials_data()

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
	print("UPDATED_CELESTIALS")

func _update_sun_data() -> void:
	_on_sun_direction_changed()
	for i in range(0, 7):
		_on_sun_value_changed(i)

func _update_moon_data() -> void:
	_on_moon_direction_changed()
	_on_moon_yaw_offset_changed()
	for i in range(0, 8):
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
	_update_sun_eclipse()

func _update_sun_eclipse() -> void:
	material.sun_eclipse_intensity = sun.eclipse_multiplier

#endregion

#region Sun Values

func _on_sun_value_changed(p_type: int) -> void:
	if not _check_material_ready() || not is_instance_valid(sun):
		return
	
	match(p_type):
		CelestialBody3D.CelestialValueType.COLOR:
			_update_sun_color()
		CelestialBody3D.CelestialValueType.INTENSITY:
			_update_sun_intensity()
		CelestialBody3D.CelestialValueType.INTENSITY_MULTIPLIER:
			_update_sun_instensity_multiplier()
		CelestialBody3D.CelestialValueType.SIZE:
			_update_sun_size()
		CelestialBody3D.CelestialValueType.MIE_COLOR:
			_update_sun_mie_color()
		CelestialBody3D.CelestialValueType.MIE_INTENSITY:
			_update_sun_mie_intensity()
		CelestialBody3D.CelestialValueType.MIE_ANISOTROPY:
			_update_sun_mie_anisotropy()

func _update_sun_color() -> void:
	material.sun_color = sun.body_color

func _update_sun_intensity() -> void:
	material.sun_intensity = sun.body_intensity

func _update_sun_instensity_multiplier() -> void:
	material.sun_intensity_multiplier = sun.intensity_multiplier

func _update_sun_size() -> void:
	material.sun_size = sun.body_size

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
	if is_instance_valid(sun):
		_update_sun_eclipse()

#endregion

#region Moon Values

func _on_moon_value_changed(p_type: int) -> void:
	if not _check_material_ready() || not is_instance_valid(moon):
		return
	match(p_type):
		Moon3D.CelestialValueType.COLOR:
			_update_moon_color()
		Moon3D.CelestialValueType.INTENSITY:
			_update_moon_intensity()
		Moon3D.CelestialValueType.INTENSITY_MULTIPLIER:
			_update_moon_intensity_multiplier()
		Moon3D.CelestialValueType.SIZE:
			_update_moon_size()
		Moon3D.CelestialValueType.TEXTURE:
			_update_moon_texture()
		Moon3D.CelestialValueType.MIE_COLOR:
			_update_moon_mie_color()
		Moon3D.CelestialValueType.MIE_INTENSITY:
			_update_moon_mie_intensity()
		Moon3D.CelestialValueType.MIE_ANISOTROPY:
			_update_moon_mie_anisotropy()

func _update_moon_color() -> void:
	material.moon_color = moon.body_color

func _update_moon_intensity() -> void:
	material.moon_intensity = moon.body_intensity

func _update_moon_intensity_multiplier() -> void:
	material.moon_intensity_multiplier = moon.intensity_multiplier

func _update_moon_size() -> void:
	material.moon_size = moon.body_size

func _update_moon_texture() -> void:
	material.moon_texture = moon.texture

func _on_moon_yaw_offset_changed() -> void:
	if not _check_material_ready() || not is_instance_valid(moon):
		return
	material.moon_texture_yaw_offset = moon.yaw_offset

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
