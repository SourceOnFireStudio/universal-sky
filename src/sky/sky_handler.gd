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

const RENDERING_METHOD_PATH:= &"rendering/renderer/rendering_method"
const COMPATIBILITY_RENDER_METHOD_NAME:= &"gl_compatibility"

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
				_update_celestials_data()
				_initialize_material()
				_set_sky_material_to_enviro()
				_connect_enviro_changed()
#region Enviro

@export_group("Enviroment")
@export
var enviro_container: NodePath:
	get: return enviro_container
	set(value):
		enviro_container = value
		if enviro_container.is_empty():
			_disconnect_enviro_changed()
			if is_instance_valid(_enviro) and is_instance_valid(_enviro.sky):
				_enviro.sky.sky_material = null
			_enviro = null
		else:
			var container = get_node_or_null(value)
			if is_instance_of(container, Camera3D) or \
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

func _initialize_material() -> void:
	# Prevent black sky when saving a script
	if Engine.is_editor_hint():
		material.initialize_params()
		if _get_rendering_method() == COMPATIBILITY_RENDER_METHOD_NAME:
			material.set_compatibility(true)
		else:
			material.set_compatibility(false)

func _get_rendering_method() -> String:
	return str(ProjectSettings.get_setting_with_override(RENDERING_METHOD_PATH))

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
	if not sun.param_changed.is_connected(_on_sun_value_changed):
		sun.param_changed.connect(_on_sun_value_changed)

func _disconnect_sun_signals() -> void:
	# Direction
	if sun.direction_changed.is_connected(_on_sun_direction_changed):
		sun.direction_changed.disconnect(_on_sun_direction_changed)
	
	# Values
	if sun.param_changed.is_connected(_on_sun_value_changed):
		sun.param_changed.disconnect(_on_sun_value_changed)

func _connect_moon_signals() -> void:
	# Direction
	if not moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.connect(_on_moon_direction_changed)
	
	# Values
	if not moon.param_changed.is_connected(_on_moon_value_changed):
		moon.param_changed.connect(_on_moon_value_changed)
	
	if not moon.yaw_offset_changed.is_connected(_on_moon_yaw_offset_changed):
		moon.yaw_offset_changed.connect(_on_moon_yaw_offset_changed)

func _disconnect_moon_signals() -> void:
	# Direction
	if moon.direction_changed.is_connected(_on_moon_direction_changed):
		moon.direction_changed.disconnect(_on_moon_direction_changed)
	
	# Values
	if moon.param_changed.is_connected(_on_moon_value_changed):
		moon.param_changed.disconnect(_on_moon_value_changed)
	
	if moon.yaw_offset_changed.is_connected(_on_moon_yaw_offset_changed):
		moon.yaw_offset_changed.disconnect(_on_moon_yaw_offset_changed)

#endregion

#region Setup

func _on_child_entered_tree(p_node: Node) -> void:
	if p_node is Sun3D and not is_instance_valid(sun):
		sun = p_node
		if is_instance_valid(sun):
			_connect_sun_signals()
			
			if is_instance_valid(moon):
				sun.set_moon(moon)
				moon.set_sun(sun)
		
		_update_celestials_data()

	if p_node is Moon3D and not is_instance_valid(moon):
		moon = p_node
		
		if is_instance_valid(moon):
			_connect_moon_signals()
			
			if is_instance_valid(sun):
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
	
	if p_node is Moon3D and p_node.get_instance_id() == moon.get_instance_id():
		_disconnect_moon_signals()
		if is_instance_valid(material):
			material.set_default_moon_values()
		
		if is_instance_valid(sun):
			sun.set_moon(null)
		moon = null
		
	_update_celestials_data()

func _on_enviro_changed() -> void:
	pass

func _update_celestials_data() -> void:
	_update_sun_data()
	_update_moon_data()

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
	if not _check_material_ready() or not is_instance_valid(sun):
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
	if not _check_material_ready() or not is_instance_valid(sun):
		return
	
	match(p_type):
		CelestialBody3D.CelestialParam.COLOR:
			material.sun_color = sun.body_color
		CelestialBody3D.CelestialParam.INTENSITY:
			material.sun_intensity = sun.body_intensity
		CelestialBody3D.CelestialParam.INTENSITY_MULTIPLIER:
			material.sun_intensity_multiplier = sun.intensity_multiplier
		CelestialBody3D.CelestialParam.SIZE:
			material.sun_size = sun.body_size
		CelestialBody3D.CelestialParam.MIE_COLOR:
			material.sun_mie_color = sun.mie_color
		CelestialBody3D.CelestialParam.MIE_INTENSITY:
			material.sun_mie_intensity = sun.mie_intensity
		CelestialBody3D.CelestialParam.MIE_ANISOTROPY:
			material.sun_mie_anisotropy = sun.mie_anisotropy

#endregion

#region Moon Direction

func _on_moon_direction_changed() -> void:
	if not _check_material_ready() or not is_instance_valid(moon):
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
	if not _check_material_ready() or not is_instance_valid(moon):
		return
	match(p_type):
		Moon3D.CelestialParam.COLOR:
			material.moon_color = moon.body_color
		Moon3D.CelestialParam.INTENSITY:
			material.moon_intensity = moon.body_intensity
		Moon3D.CelestialParam.INTENSITY_MULTIPLIER:
			material.moon_intensity_multiplier = moon.intensity_multiplier
		Moon3D.CelestialParam.SIZE:
			material.moon_size = moon.body_size
		Moon3D.CelestialParam.TEXTURE:
			material.moon_texture = moon.texture
		Moon3D.CelestialParam.MIE_COLOR:
			material.moon_mie_color = moon.mie_color
		Moon3D.CelestialParam.MIE_INTENSITY:
			_update_moon_mie_intensity()
		Moon3D.CelestialParam.MIE_ANISOTROPY:
			material.moon_mie_anisotropy = moon.mie_anisotropy

func _on_moon_yaw_offset_changed() -> void:
	if not _check_material_ready() or not is_instance_valid(moon):
		return
	material.moon_texture_yaw_offset = moon.yaw_offset

func _update_moon_mie_intensity() -> void:
	material.moon_mie_intensity = moon.get_final_moon_mie_intensity()

#endregion
