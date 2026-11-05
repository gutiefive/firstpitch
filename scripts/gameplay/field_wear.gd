class_name FieldWear
extends RefCounted
var dirt_indices := PackedInt32Array()
var dirt_heavy := PackedByteArray()
var chalk_heavy := PackedByteArray()
var surface: InfieldSurface
var last_ms := 0.0


func prepare(g: Node) -> void:
	surface = g.infield
	dirt_indices = surface.work_indices()
	dirt_heavy.resize(dirt_indices.size())
	var layout: FieldLayout = g.layout
	var rules := ShiftSession.wear_rules()
	var bases := layout.base_positions()
	var corners := PackedVector2Array([layout.plate_position, bases[0], bases[1], bases[2]])
	var holes := [
		(
			layout.diamond_center
			+ Vector2(
				-layout.base_axis() * float(rules.hole_axis_x), layout.base_axis() * float(rules.hole_axis_y)
			)
		),
		(
			layout.diamond_center
			+ Vector2(
				layout.base_axis() * float(rules.hole_axis_x), layout.base_axis() * float(rules.hole_axis_y)
			)
		)
	]
	for n in range(dirt_indices.size()):
		var index := dirt_indices[n]
		var p := surface.cell_world(index % surface.resolution.x, index / surface.resolution.x)
		var heavy := p.distance_to(layout.plate_position) < float(rules.batter_radius)
		for base in bases:
			heavy = heavy or p.distance_to(base) < float(rules.base_radius)
		for i in range(4):
			heavy = (
				heavy
				or (
					p.distance_to(
						Geometry2D.get_closest_point_to_segment(p, corners[i], corners[(i + 1) % 4])
					)
					< float(rules.lane_width)
				)
			)
		for hole in holes:
			heavy = heavy or p.distance_to(hole) < float(rules.hole_radius)
		dirt_heavy[n] = int(heavy)
	var valid: PackedByteArray = g.chalk.valid_sections()
	chalk_heavy.resize(valid.size())
	for i in range(valid.size()):
		var p: Vector2 = g.chalk.section_center(i / g.chalk.sections_per_line, i % g.chalk.sections_per_line)
		chalk_heavy[i] = int(
			(
				p.distance_to(layout.plate_position) < float(rules.chalk_home_radius)
				or p.distance_to(bases[0]) < float(rules.chalk_base_radius)
				or p.distance_to(bases[2]) < float(rules.chalk_base_radius)
			)
		)


func is_blank(g: Node) -> bool:
	return (
		g.grass.cut_count == 0
		and g.infield.prepared_count == 0
		and g.chalk.snapshot_strokes().is_empty()
		and not g.moisture.has_exposure()
		and g.mound.work_done == 0
	)


func bootstrap(g: Node, profile: String) -> void:
	# A first game day needs a host park; subsequent games wear the actual current field.
	g.infield.prepare_all()
	g.moisture.fill_valid(ShiftSession.wear_rules(profile).ready_moisture)
	g.chalk.prepare_all()
	g.mound.prepare_all()


func apply(g: Node, wear_seed_value: int, intensity: float, profile: String = "full") -> float:
	var start := Time.get_ticks_usec()
	if not is_finite(intensity) or intensity <= 0:
		last_ms = 0
		return last_ms
	if surface != g.infield:
		prepare(g)
	intensity = clampf(intensity, 0, 1)
	var rules := ShiftSession.wear_rules(profile)
	var rng := RandomNumberGenerator.new()
	rng.seed = wear_seed_value
	var dirt: PackedByteArray = g.infield.snapshot_cells()
	for n in range(dirt_indices.size()):
		var chance: float = rules.heavy_chance if dirt_heavy[n] == 1 else rules.light_chance
		if rng.randf() < chance * intensity:
			dirt[dirt_indices[n]] = 0
	g.infield.replace_cells(dirt)
	var water: PackedFloat32Array = g.moisture.snapshot_moisture()
	for index in dirt_indices:
		water[index] *= 1 - float(rules.dry_fraction) * intensity
	g.moisture.replace_moisture(water)
	var clear: PackedByteArray = g.chalk.valid_sections()
	for i in range(clear.size()):
		var chance: float = rules.heavy_chance if chalk_heavy[i] == 1 else rules.light_chance
		clear[i] = int(clear[i] == 1 and rng.randf() < chance * intensity)
	g.chalk.scuff_sections(clear)
	var hits: PackedInt32Array = g.mound.snapshot_hits()
	for i in range(hits.size()):
		var weight := 1.0 if g.layout.mound_patches[i].y > 0 else float(rules.rear_mound_weight)
		var lost := ceili(
			g.mound.hits_required * intensity * weight * rng.randf_range(float(rules.mound_min_fraction), 1)
		)
		hits[i] = maxi(0, hits[i] - lost)
	g.mound.replace_hits(hits)
	g.grass.reset_state()
	last_ms = (Time.get_ticks_usec() - start) / 1000.0
	return last_ms
