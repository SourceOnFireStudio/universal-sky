@tool
extends Node
class_name Planetary

var _sky_handler: SkyHandler = null
var _sun: Sun3D = null
var _moon: Moon3D = null

var _sun_altitude: float
var _sun_azimuth: float

var _moon_altitude: float
var _moon_azimuth: float

var _date_time: PlanetaryDateTime
var _timeline: float = 7.0
var _day: int = 1
var _month: int = 9
var _year: int = 2025

var timeline_utc: float:
	get: return _timeline - utc

var sun_altitude: float:
	get: return _sun_altitude

var sun_azimuth: float:
	get: return _sun_azimuth

var sun_altitude_rad: float:
	get: return deg_to_rad(_sun_altitude)

var sun_azimuth_rad: float:
	get: return deg_to_rad(_sun_azimuth)

var moon_altitude: float:
	get: return _moon_altitude

var moon_azimuth: float:
	get: return _moon_azimuth

var moon_altitude_rad: float:
	get: return deg_to_rad(_moon_altitude)

var moon_azimuth_rad: float:
	get: return deg_to_rad(_moon_azimuth)

@export_range(-12.0, 12.0)
var utc: float = 0.0:
	get: return utc
	set(value):
		utc = value
		_update_celestial_coords()

@export_range(-90.0, 90.0)
var latitude: float = 0.0:
	get: return latitude
	set(value):
		latitude = value
		_update_celestial_coords()

@export_range(-180.0, 180.0)
var longitude: float = 0.0:
	get: return longitude
	set(value):
		longitude = value
		_update_celestial_coords()

@export
var moon_coords_offset: Vector2:
	get: return moon_coords_offset
	set(value):
		moon_coords_offset = value
		_update_celestial_coords()

#region Godot Node Overrides
func _enter_tree() -> void:
	_connect_child_tree_signals()

func _exit_tree() -> void:
	_disconnect_child_tree_signals()
#endregion

#region Connections
# This node child enter and exit tree signals
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

# Sky handler child node  enter and exit signals.
func _connect_sky_handler_child_tree_signals() -> void:
	if not _sky_handler.child_entered_tree.is_connected(_on_sky_handler_child_entered_tree):
		_sky_handler.child_entered_tree.connect(_on_sky_handler_child_entered_tree)
	
	if not _sky_handler.child_exiting_tree.is_connected(_on_sky_handler_child_exiting_tree):
		_sky_handler.child_exiting_tree.connect(_on_sky_handler_child_exiting_tree)

func _disconnect_sky_handler_child_tree_signals() -> void:
	if _sky_handler.child_entered_tree.is_connected(_on_sky_handler_child_entered_tree):
		_sky_handler.child_entered_tree.disconnect(_on_sky_handler_child_entered_tree)
	
	if _sky_handler.child_exiting_tree.is_connected(_on_sky_handler_child_exiting_tree):
		_sky_handler.child_exiting_tree.disconnect(_on_sky_handler_child_exiting_tree)

# Datetime
func _connect_date_time_signals() -> void:
	if not _date_time.time_param_changed.is_connected(_on_date_time_param_changed):
		_date_time.time_param_changed.connect(_on_date_time_param_changed)

func _disconnect_date_time_signals() -> void:
	if _date_time.time_param_changed.is_connected(_on_date_time_param_changed):
		_date_time.time_param_changed.disconnect(_on_date_time_param_changed)
#endregion

#region Signal Events
func _on_child_entered_tree(p_node: Node) -> void:
	# Sky Handler
	if p_node is SkyHandler:
		_sky_handler = p_node as SkyHandler
		if is_instance_valid(_sky_handler):
			_connect_sky_handler_child_tree_signals()
	
	# Date Time
	if p_node is PlanetaryDateTime:
		_date_time = p_node as PlanetaryDateTime
		if is_instance_valid(_date_time):
			_connect_date_time_signals()

func _on_child_exiting_tree(p_node: Node) -> void:
	if is_instance_valid(_sky_handler):
		if p_node is SkyHandler and p_node.get_instance_id() == _sky_handler.get_instance_id():
			_disconnect_sky_handler_child_tree_signals()
			_sky_handler = null
	
	if is_instance_valid(_date_time):
		if p_node is PlanetaryDateTime and p_node.get_instance_id() == _date_time.get_instance_id():
			_disconnect_date_time_signals()
			_date_time = null

func _on_sky_handler_child_entered_tree(p_node: Node) -> void:
	if p_node is Sun3D:
		if is_instance_valid(_sky_handler.sun):
			_sun = _sky_handler.sun
	if p_node is Moon3D:
		if is_instance_valid(_sky_handler.moon):
			_moon = _sky_handler.moon

func _on_sky_handler_child_exiting_tree(p_node: Node) -> void:
	if not is_instance_valid(_sky_handler):
		return
	if p_node is Sun3D:
		if not is_instance_valid(_sky_handler.sun):
			_sun = null
	if p_node is Moon3D:
		if not is_instance_valid(_sky_handler.moon):
			_moon = null

func _on_date_time_param_changed(p_param) -> void:
	match p_param:
		PlanetaryDateTime.DateTimeParam.TIMELINE:
			_timeline = _date_time.timeline
			_update_celestial_coords()
		PlanetaryDateTime.DateTimeParam.DAY:
			_day = _date_time.day
		PlanetaryDateTime.DateTimeParam.MONTH:
			_month = _date_time.month
		PlanetaryDateTime.DateTimeParam.YEAR:
			_year = _date_time.year
#endregion

#region Celestial Coords
func _update_celestial_coords() -> void:
	_compute_simple_sun_coords()
	var sunQuat = Quaternion.from_euler(
		Vector3(sun_altitude_rad - deg_to_rad(90.0), sun_azimuth_rad, 0.0)
	)
	
	_compute_simple_moon_coords()
	var moonQuat = Quaternion.from_euler(
		Vector3(moon_altitude_rad - deg_to_rad(90.0), moon_azimuth_rad, 0.0)
	)
	
	if is_instance_valid(_sun):
		_sun.basis = sunQuat
	if is_instance_valid(_moon):
		_moon.basis = moonQuat

# Simple coords
func _compute_simple_sun_coords() -> void:
	var lonRad: float = deg_to_rad(longitude)
	_sun_altitude = 180.0 - ((timeline_utc + lonRad) * 15) # (360/24)
	_sun_azimuth = 90.0 - latitude

func _compute_simple_moon_coords() -> void:
	_moon_altitude = (180.0 - _sun_altitude) + moon_coords_offset.y
	_moon_azimuth = (180.0 + _sun_azimuth) + moon_coords_offset.x
#endregion
