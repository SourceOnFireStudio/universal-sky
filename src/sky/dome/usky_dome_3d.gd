# Universal Sky
# Description:
# - Dynamic skydome.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
@tool @icon("res://addons/universal-sky/assets/icons/Sky.svg")
class_name USkyDome3D extends Node3D

#region Drawer
const DEFAULT_SKY_SHADER:= preload(
	"res://addons/universal-sky/src/sky/shaders/sky/default_skydome.gdshader"
)
var _dome_drawer:= USkyDomeDrawer.new()
var _dome_mesh:= SphereMesh.new()
var _dome_material:= ShaderMaterial.new()
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

#region Setup
func _init() -> void:
	_change_dome_mesh_quality(dome_mesh_quality)
	_dome_material.shader = DEFAULT_SKY_SHADER
	_dome_material.render_priority = -128
	default_dome_color = default_dome_color

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
#endregion
