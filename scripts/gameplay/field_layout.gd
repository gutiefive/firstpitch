class_name FieldLayout
extends Resource
const FOOT := 0.3048
const INCH := 0.0254
@export_group("Diamond")
@export var plate_position := Vector2.ZERO
@export var basepath_length := 27.432
@export var diamond_side := 31.0
@export var island_side := 22.0
@export var diamond_height := 0.0375
@export var diamond_thickness := 0.025
@export var island_height := 0.0825
@export var island_thickness := 0.035
@export var home_radius := 6.0
@export var home_height := 0.13
@export var home_thickness := 0.12
@export var plate_exclusion_radius := 2.8
@export var base_width := 0.5
@export var base_height := 0.18
@export var base_thickness := 0.16
@export var base_surface_radius := 0.38
@export var base_exclusion_radius := 0.95
@export_group("Mound")
@export var mound_position := Vector2(0, -18.44)
@export var mound_top_radius := 2.2
@export var mound_base_radius := 2.8
@export var mound_exclusion_radius := 3.1
@export var mound_height := 0.36
@export var mound_patch_radius := 0.42
@export var mound_patches := PackedVector2Array(
	[
		Vector2(-0.75, 0.25),
		Vector2(0, 1.25),
		Vector2(0.8, 0.7),
		Vector2(-1.35, -0.55),
		Vector2(1.25, -0.6),
		Vector2(0.25, -1.4)
	]
)
@export_group("Outfield and masks")
@export var outfield_radius := 99.0
@export var fence_radius := 104.0
@export var grass_height := 0.055
@export var track_height := 0.06
@export var grass_origin := Vector2(-75, -110)
@export var grass_size := Vector2(150, 110)
@export var grass_resolution := Vector2i(450, 330)
@export var dirt_origin := Vector2(-25, -45)
@export var dirt_size := Vector2(50, 53)
@export var dirt_resolution := Vector2i(250, 265)
@export_group("Chalk and reference markings")
@export var line_start := 0.8
@export var line_end := 103.0
@export var chalk_plate_exclusion := 0.7
@export var chalk_base_exclusion := 0.55
@export var plate_width := 17 * INCH
@export var batter_width := 4 * FOOT
@export var batter_length := 6 * FOOT
@export var batter_plate_gap := 6 * INCH
@export var coach_width := 5 * FOOT
@export var coach_length := 20 * FOOT
@export var coach_line_clearance := 15 * FOOT
@export var on_deck_radius := 2.5 * FOOT
@export var on_deck_distance := 37 * FOOT
@export var on_deck_back_offset := 2.5
@export var on_deck_clay_radius := 1.12
@export var marking_width := 0.05
@export_group("Equipment and neighborhood")
@export var workshop_pad := Rect2(26.5, -23.5, 13, 9)
@export var workshop_pad_height := 0.05
@export var workshop_pad_thickness := 0.04
@export var concourse := Rect2(-31.5, 18, 63, 8)
@export var concourse_center_height := 0.018
@export var concourse_thickness := 0.035
@export var workshop_position := Vector3(38, 0, -11)
@export var player_spawn := Vector3(29, 0.1, -11)
@export var mower_spawn := Vector3(30, 0.1, -19)
@export var mower_yaw := PI / 4
@export var chalk_marker_spawn := Vector3(38, 0.05, -21)
@export var chalk_marker_sign := Vector3(38, 1.8, -22)
@export var tool_bay_position := Vector3(35, 0, -23)
@export var water_station_position := Vector3(33, 0, -3.8)
@export var tamper_rack_position := Vector3(39.5, 0, -5.8)
@export var noticeboard_position := Vector3(29, 1.65, -3.4)
@export var sideline_start := Vector2(8, 6)
@export var sideline_corner := Vector2(82, -73.5)
@export var dugout_distance := 20.0
@export var dugout_half_width := 5.5
@export var dugout_front_depth := 2.2
@export var equipment_gate_z := Vector2(-14.5, -27.5)
@export var foul_pole_axis := 73.5
@export var ground_center := Vector3(0, -0.3, -40)
@export var ground_size := Vector3(400, 0.6, 400)

var diamond_center: Vector2:
	get:
		return plate_position + Vector2(0, -base_axis())
var outer_edge: float:
	get:
		return diamond_side / sqrt(2)
var inner_edge: float:
	get:
		return island_side / sqrt(2)


func base_axis() -> float:
	# A 90 ft baseline at 45 degrees projects to 27.432 / sqrt(2) on X and Z.
	return basepath_length / sqrt(2)


func base_positions() -> PackedVector2Array:
	var axis := base_axis()
	return PackedVector2Array(
		[
			plate_position + Vector2(axis, -axis),
			plate_position + Vector2(0, -axis * 2),
			plate_position + Vector2(-axis, -axis)
		]
	)


func point3(point: Vector2, height: float = 0) -> Vector3:
	return Vector3(point.x, height, point.y)


func diamond_distance(p: Vector2) -> float:
	return absf(p.x - diamond_center.x) + absf(p.y - diamond_center.y)


func is_fair(p: Vector2) -> bool:
	var local := p - plate_position
	return local.y < 0 and absf(local.x) <= -local.y and local.length() <= fence_radius


func is_on_basepath(p: Vector2) -> bool:
	var distance := diamond_distance(p)
	return distance <= outer_edge and distance >= inner_edge


func is_grass(p: Vector2) -> bool:
	var local := p - plate_position
	return (
		is_fair(p)
		and absf(local.x) < -local.y
		and local.length() <= outfield_radius
		and diamond_distance(p) > outer_edge
		and local.length() > home_radius
	)


func is_workable(p: Vector2) -> bool:
	var home_distance := p.distance_to(plate_position)
	if not (is_on_basepath(p) or (home_distance <= home_radius and home_distance > plate_exclusion_radius)):
		return false
	if p.distance_to(mound_position) < mound_exclusion_radius or home_distance < plate_exclusion_radius:
		return false
	for base in base_positions():
		if p.distance_to(base) < base_exclusion_radius:
			return false
	return true


func is_chalk_protected(p: Vector2) -> bool:
	if p.distance_to(plate_position) < chalk_plate_exclusion:
		return true
	var bases := base_positions()
	for base in [bases[0], bases[2]]:
		if p.distance_to(base) < chalk_base_exclusion:
			return true
	return false


func contains(rect: Rect2, p: Vector2) -> bool:
	return p.x >= rect.position.x and p.y >= rect.position.y and p.x <= rect.end.x and p.y <= rect.end.y


func ground_height(p: Vector2) -> float:
	var mound_distance := p.distance_to(mound_position)
	if mound_distance <= mound_top_radius:
		return mound_height
	if mound_distance < mound_base_radius:
		return mound_height * (mound_base_radius - mound_distance) / (mound_base_radius - mound_top_radius)
	for base in base_positions():
		if p.distance_to(base) < base_surface_radius:
			return base_height
	if p.distance_to(plate_position) < home_radius:
		return home_height
	var diamond := diamond_distance(p)
	if diamond <= inner_edge:
		return island_height
	if diamond <= outer_edge:
		return diamond_height
	if is_fair(p):
		return grass_height if p.distance_to(plate_position) <= outfield_radius else track_height
	if contains(workshop_pad, p):
		return workshop_pad_height
	if contains(concourse, p):
		return concourse_center_height + concourse_thickness * 0.5
	return 0


func boundary_start(side: int) -> Vector3:
	return point3(Vector2(side * sideline_start.x, sideline_start.y))


func boundary_corner(side: int) -> Vector3:
	return point3(Vector2(side * sideline_corner.x, sideline_corner.y))
