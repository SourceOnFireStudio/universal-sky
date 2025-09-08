@tool
extends Node
class_name Planetary

enum CalculationsMode{
	SIMPLE = 0,
	REALISTIC
}

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

# Realistic cualculations private vars
var _sun_distance: float
var _true_sun_longitude: float 
var _mean_sun_longitude: float
var _sideral_time: float
var _local_sideral_time: float

var sky_handler_is_valid: bool:
	get: return is_instance_valid(_sky_handler)

var date_time_is_valid: bool:
	get: return is_instance_valid(_date_time)

var sun_is_valid: bool:
	get: return is_instance_valid(_sun)

var moon_is_valid: bool:
	get: return is_instance_valid(_moon)

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

var latitude_rad: float:
	get: return deg_to_rad(latitude)

var longitude_rad: float:
	get: return deg_to_rad(longitude)

@export_tool_button("Test Sun Coordinates", "Callable")
var test_sun_cordinates = _test_sun_coords

func _test_sun_coords():
	_compute_realistic_sun_coords()

@export
var calculations_mode:= CalculationsMode.REALISTIC:
	get: return calculations_mode
	set(value):
		calculations_mode = value
		_update_celestial_coords()

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
		if sky_handler_is_valid:
			_connect_sky_handler_child_tree_signals()
	
	# Date Time
	if p_node is PlanetaryDateTime:
		_date_time = p_node as PlanetaryDateTime
		if date_time_is_valid:
			_connect_date_time_signals()

func _on_child_exiting_tree(p_node: Node) -> void:
	if sky_handler_is_valid:
		if p_node is SkyHandler and p_node.get_instance_id() == _sky_handler.get_instance_id():
			_disconnect_sky_handler_child_tree_signals()
			_sky_handler = null
	
	if date_time_is_valid:
		if p_node is PlanetaryDateTime and p_node.get_instance_id() == _date_time.get_instance_id():
			_disconnect_date_time_signals()
			_date_time = null

func _on_sky_handler_child_entered_tree(p_node: Node) -> void:
	if p_node is Sun3D:
		if _sky_handler.sun_is_valid:
			_sun = _sky_handler.sun
	if p_node is Moon3D:
		if _sky_handler.moon_is_valid:
			_moon = _sky_handler.moon

func _on_sky_handler_child_exiting_tree(p_node: Node) -> void:
	if not sky_handler_is_valid:
		return
	if p_node is Sun3D:
		if not _sky_handler.sun_is_valid:
			_sun = null
	if p_node is Moon3D:
		if not _sky_handler.moon_is_valid:
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
	var sunQuat: Quaternion
	var moonQuat: Quaternion
	match calculations_mode:
		CalculationsMode.SIMPLE:
			_compute_simple_sun_coords()
			sunQuat = Quaternion.from_euler(
				Vector3(sun_altitude_rad - deg_to_rad(90.0), sun_azimuth_rad, 0.0)
			)
			_compute_simple_moon_coords()
			moonQuat = Quaternion.from_euler(
				Vector3(moon_altitude_rad - deg_to_rad(90.0), moon_azimuth_rad, 0.0)
			)
		
		# Need more testing(Azimuth)
		CalculationsMode.REALISTIC:
			_compute_realistic_sun_coords()
			sunQuat = Quaternion.from_euler(
				Vector3(-sun_altitude_rad, sun_azimuth_rad, 0.0)
			)
		
	if sun_is_valid:
		_sun.basis = sunQuat
	if moon_is_valid:
		_moon.basis = moonQuat

# Simple coords
func _compute_simple_sun_coords() -> void:
	var lonRad: float = deg_to_rad(longitude)
	_sun_altitude = 180.0 - ((timeline_utc + lonRad) * 15) # (360/24)
	_sun_azimuth = 90.0 - latitude

func _compute_simple_moon_coords() -> void:
	_moon_altitude = (180.0 - _sun_altitude) + moon_coords_offset.y
	_moon_azimuth = (180.0 + _sun_azimuth) + moon_coords_offset.x


# Realistic Coords
# See:
# http://www.stjarnhimlen.se/comp/ppcomp.html
# http://stjarnhimlen.se/comp/tutorial.html
## Input Test: Latitude: 60.0, Longitude: 15.0, Utc: 0.0, 19-Abr-1990

## Reduce value to between 0 and 360 degrees.
func rev(p_value: float) -> float:
	return p_value - floori(p_value / 360.0) * 360.0

## See: 
## https://www.stjarnhimlen.se/comp/tutorial.html#4
## https://stjarnhimlen.se/comp/ppcomp.html#3
## Output Test = -3543.0
func _get_time_scale() -> float:
	var y = _year
	var m = _month
	var D = _day
	#var d: float = 367 * y - (7 * (y + ((m + 9) / 12))) / 4 + (275 * m) / 9 + D - 730530
	var d: int = 367 * y - 7 * (y + (m + 9) / 12) / 4 - 3 * \
		((y + (m * 9) / 7) / 100 + 1) / 4 + 275 * m / 9 + D - 730515
	
	return d + (_timeline / 24.0)

## See: https://www.stjarnhimlen.se/comp/tutorial.html#5
## Input Test: Latitude: 60.0, Longitude: 15.0, Utc: 0.0, 19-Abr-1990
## Output Test = 23.4406 deg
func _get_oblecl() -> float:
	return 23.4393 - 3.563e-7 * _get_time_scale()

func _compute_realistic_sun_coords() -> void:
	var timeScale: float = _get_time_scale()
	var oblectRad: float = deg_to_rad(_get_oblecl())
	
	#region Orbital Elements
	var N: float = 0.0
	var i: float = 0.0
	var w: float = 282.9404 + 4.70935e-5 * timeScale
	var a: float = 0.0
	var e: float = 0.016709 - 1.151e-9 * timeScale
	var M: float = 356.0470 + 0.9856002585 * timeScale
	M = rev(M) # Solve M.
	var MRad: float = deg_to_rad(M) # Mean anomaly in radians.
	#endregion
	
	#region Eccentric Anomaly
	# Output = 104.9904 deg
	var E: float = M + rad_to_deg(e) * sin(MRad) * (1 + e * cos(MRad))
	var ERad: float = deg_to_rad(E)
	#endregion
	
	#region  Rectangular Coordinates.
	# Output = -0.27537012629078
	var xv: float = cos(ERad) - e
	# Output = 0.96583429859032
	var yv: float = sin(ERad) * sqrt(1 - e * e)
	#endregion
	
	#region Distance and True Anomaly
	# Output = 1.00432295542164 rad
	var r: float = sqrt(xv * xv + yv * yv)
	# Output = 105.913441697029 deg
	var v: float = rad_to_deg(atan2(yv, xv))
	_sun_distance = r
	#endregion
	
	#region Sun Longitude
	# Output: 28.6869 deg
	var lon: float = rev(v + w)
	var lonRad: float = deg_to_rad(lon)
	_true_sun_longitude = lonRad
	#endregion
	
	#region Ecliptic and ecuatorial coords.
	# Output: 0.881048
	var xs: float = r * cos(lonRad)
	# Output: 0.482098
	var ys: float = r * sin(lonRad) 
	var zs: float = 0.0
	
	var obleclCos: float = cos(oblectRad)
	var oblectSin: float = sin(oblectRad)
	
	# Output: 0.881048
	var xequat: float = xs
	# Output: 0.442312
	var yequat: float = ys * obleclCos - 0.0 * oblectSin
	# Output: 0.191778
	var zequat: float = ys * oblectSin + 0.0 * obleclCos
	#endregion

	#region  Ascencion and declination.
	# Output: 1.00432295542164 = r
	var re: float = sqrt(xequat * xequat + yequat * yequat + zequat * zequat)
	
	# Output: 26.6580776793343 deg/15
	var RA: float = rad_to_deg(atan2(yequat, xequat)) / 15

	# Output: 11.0083747350256 deg
	var Decl: float = rad_to_deg(atan2(zequat, sqrt(xequat * xequat + yequat * yequat)))
	var DeclRad: float = deg_to_rad(Decl)
	#endregion
	
	#region Sideral time and hour angle.
	# Mean Longitude
	var L: float = rev(w + M)
	_mean_sun_longitude = L
	
	# GMST0
	# Output: 13.7892554576 hours
	var GMST0: float = L/15 + 12 #(L + 180) / 15
	
	# Sideral Time
	# Output: 14.7892554576 hours
	_sideral_time = GMST0 + timeline_utc + (longitude/15)
	
	# Hour Angle
	# Output: 13.01205 hours * 15 = 195.18075 degrees
	var HA: float = (_sideral_time - RA) * 15
	var HARad: float = deg_to_rad(HA) 

	# Hour Angle to rectangular
	# Output: -0.94734589519279
	var x: float = cos(HARad) * cos(DeclRad)
	
	# Output: -0.25704650810098
	var y: float = sin(HARad) * cos(DeclRad)
	
	# Output: 0.19095247454395
	var z: float = sin(DeclRad)
	
	# Output: -0.91590184867985
	var xhor = x * sin(latitude_rad) - z * cos(latitude_rad)
	
	# Output: -0.25704650810098
	var yhor = y
	
	# Output: -0.30830325372583
	var zhor = x * cos(latitude_rad) + z * sin(latitude_rad) 
	
	# Output: 15.676697321318
	var azimuth = rad_to_deg(atan2(yhor, xhor)) + 180.0
	
	# Output: -0.31340888543438
	var altitude = rad_to_deg(asin(zhor)) # atan2(zhor, sqrt(xhor * xhor + yhor * yhor))
	
	_sun_altitude = altitude
	_sun_azimuth = azimuth
	#endregion

#endregion
