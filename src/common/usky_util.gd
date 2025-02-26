# Universal Sky
# Description:
# - Utility.
# License:
# - J. Cuéllar 2025 MIT License
# - See: LICENSE File.
class_name USkyUtil

static func interpolate_full(p_dir: float) -> float:
	return (1.0 - p_dir) * 0.5

static func interpolate_by_above(p_dir: float) -> float:
	return 1.0 - p_dir

static func interpolate_by_below(p_dir: float) -> float:
	return 1.0 + p_dir
