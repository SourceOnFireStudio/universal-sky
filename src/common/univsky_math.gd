class_name UnivSkyMath

#TODO: Remove unnecessary constants and functions.

const RAD_TO_DEG:= 57.29577951308232
const DEG_TO_RAD:= 0.01745329251994
const EPSILON:= 1.1920928955078125e-7
const EPSILON_DBL:= 2.22044604925031308085e-16

# NOTE: There are some corner cases where it is more convenient to use these clamp functions.
static func clamp_f(p_value: float, p_min: float, p_max: float) -> float:
	return p_min if p_value < p_min else p_max if p_value > p_max else p_value

static func clamp_i(p_value: int, p_min: int, p_max: int) -> int:
	return p_min if p_value < p_min else p_max if p_value > p_max else p_value

static func clamp_vec2(p_value: Vector2, p_min: Vector2, p_max: Vector2) -> Vector2:
	p_value.x = p_min.x if p_value.x < p_min.x else p_max.x if p_value.x > p_max.x else p_value.x
	p_value.y = p_min.y if p_value.y < p_min.y else p_max.y if p_value.y > p_max.y else p_value.y
	
	return p_value

static func clamp_vec3(p_value: Vector3, p_min: Vector3, p_max: Vector3) -> Vector3:
	p_value.x = p_min.x if p_value.x < p_min.x else p_max.x if p_value.x > p_max.x else p_value.x
	p_value.y = p_min.y if p_value.y < p_min.y else p_max.y if p_value.y > p_max.y else p_value.y
	p_value.z = p_min.z if p_value.z < p_min.z else p_max.z if p_value.z > p_max.z else p_value.z
	
	return p_value

static func clampO1(p_value: Variant) -> Variant:
	if p_value is float:
		return clamp(p_value, 0.0, 1.0)
	elif p_value is Vector3:
		return clamp(p_value, Vector3.ZERO, Vector3.ONE)
	return clamp(p_value, Vector2.ZERO, Vector2.ONE)

static func clamp01f(p_value: float) -> float:
	return clamp(p_value, 0.0, 1.0)

static func clamp01v2(p_value: Vector2) -> Vector2:
	return clamp(p_value, Vector2.ZERO, Vector2.ONE)

static func clamp01v3(p_value: Vector3) -> Vector3:
	return clamp(p_value, Vector3.ZERO, Vector3.ONE)

# TODO: Moved to time of day
static func rev(p_value: float) -> float:
	return p_value - floori(p_value / 360.0) * 360.0

static func to_orbit(p_theta: float, p_pi: float, p_radius: float = 1.0) -> Vector3:
	var sinTheta: float = sin(p_theta)
	var cosTheta: float = cos(p_theta)
	var sinPI:    float = sin(p_pi)
	var cosPI:    float = cos(p_pi)
	return Vector3((sinTheta * sinPI) * p_radius,
		cosTheta  * p_radius, (sinTheta * cosPI) * p_radius)

static func celestials_coords_to_dir(p_altitude: float, p_azimuth: float) -> Vector3:
	var x: float = cos(p_altitude) * sin(p_azimuth)
	var y: float = sin(p_altitude)
	var z: float = cos(p_altitude) * cos(p_azimuth)
	return Vector3(x, y, z)

static func angular_intensity_sig(a: Vector3, b: Vector3, threshold: float = 0.03, slope: float = 100.0) -> float:
	var separation: float = acos(a.dot(b))
	# sigmoide curve
	var factor: float = 1.0 / (1.0 + exp(-slope * (separation - threshold)))
	return lerp(0.0, 1.0, factor)
