# Universal Sky
# Description:
# - Direct dome drawer using rendering server.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
extends RefCounted
class_name USkyDomeDrawer

var RS = RenderingServer

var instance: RID:
	get: return instance

var check_instance: bool:
	get:
		if instance.is_valid():
			return true
		return false

var get_direction: Vector3:
	get: return -(_transform.basis * Vector3.FORWARD)

var _transform := Transform3D()
var _world: World3D = null
var _mesh: Mesh = null

#const MAX_EXTRA_VISIBILITY_MARGIN:= 16384.0
const CUSTOM_AABB := AABB(Vector3(-1e31, -1e31, -1e31), Vector3(2e31, 2e31, 2e31))

func clear() -> void:
	RS.free_rid(instance)
	_world = null
	instance = RID()

#region Rendering
func draw(p_world: World3D, p_mesh: Mesh, p_material: Material) -> void:
	instance = RS.instance_create()
	if not check_instance:
		printerr("Instance create fail")
		return
	
	#set_visible(true)
	RS.instance_set_scenario(instance, p_world.scenario)
	RS.instance_set_base(instance, p_mesh.get_rid())
	RS.instance_set_transform(instance, _transform)
	RS.instance_geometry_set_material_override(instance, 
		p_material.get_rid() if is_instance_valid(p_material) else RID())
	
	#RS.instance_set_extra_visibility_margin(instance, MAX_EXTRA_VISIBILITY_MARGIN)
	RS.instance_set_custom_aabb(instance, CUSTOM_AABB)
	RS.instance_geometry_set_cast_shadows_setting(instance, RS.SHADOW_CASTING_SETTING_OFF)

func set_material(p_material: Material) -> void:
	if not instance.is_valid():
		return
	RS.instance_geometry_set_material_override(instance, 
		p_material.get_rid() if is_instance_valid(p_material) else RID())

func set_visible(p_value: bool) -> void:
	RS.instance_set_visible(instance, p_value)

func set_layers(p_layers: int) -> void:
	if check_instance:
		RS.instance_set_layer_mask(instance, p_layers)
#endregion

#region Transform
func set_origin(p_value: Vector3) -> void:
	if check_instance:
		_transform.origin = p_value
		RS.instance_set_transform(instance, _transform)

func set_origin_offset(p_value: Vector3) -> void:
	if check_instance:
		_transform.origin += p_value
		RS.instance_set_transform(instance, _transform)

func set_rotated(p_axis: Vector3, p_pi: float) -> void:
	if check_instance:
		_transform.basis = _transform.basis.rotated(p_axis, p_pi)
		RS.instance_set_transform(instance, _transform)
#endregion
