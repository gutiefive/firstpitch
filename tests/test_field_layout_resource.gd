extends SceneTree
const PRE_REFACTOR_HASH := "4b93508a852f996a404526525630f7fcb6b2271cd10d8adedd4c9f2364fd70b5"
# Recorded on main before this refactor, not generated from the new layout.
const PRE_REFACTOR_TOTALS := [61444, 12618, 808, 18]
var failures := 0
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		push_error(message)
		failures += 1


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var layout: FieldLayout = load("res://resources/layouts/cedar_grove.tres")
	var bases := layout.base_positions()
	check(
		is_equal_approx(bases[0].distance_to(layout.plate_position), layout.basepath_length),
		"first base derives from the 90-foot baseline"
	)
	check(
		(
			is_equal_approx(bases[0].distance_to(bases[1]), layout.basepath_length)
			and is_equal_approx(bases[1].distance_to(bases[2]), layout.basepath_length)
		),
		"all basepaths share the derived length"
	)
	check(
		(
			is_equal_approx(layout.diamond_distance(layout.diamond_center), 0)
			and is_equal_approx(layout.diamond_distance(bases[0]), layout.base_axis())
		),
		"diamond distance uses the shared center"
	)
	check(
		(
			is_equal_approx(layout.outer_edge, layout.diamond_side / sqrt(2))
			and is_equal_approx(layout.inner_edge, layout.island_side / sqrt(2))
		),
		"basepath boundaries match the drawn rotated squares"
	)
	check(
		layout.is_on_basepath(bases[0]) and not layout.is_on_basepath(layout.diamond_center),
		"basepath helper separates the lawn from the dirt band"
	)
	check(
		(
			layout.is_fair(Vector2(0, -60))
			and layout.is_fair(Vector2(20, -20))
			and not layout.is_fair(Vector2(21, -20))
			and not layout.is_fair(Vector2(0, 10))
			and not layout.is_fair(Vector2(0, -120))
		),
		"fair territory respects the wedge and fence radius"
	)
	check(
		is_equal_approx(layout.ground_height(layout.mound_position), layout.mound_height),
		"height query reaches mound top"
	)
	var slope := (layout.mound_top_radius + layout.mound_base_radius) * 0.5
	check(
		is_equal_approx(
			layout.ground_height(layout.mound_position + Vector2(slope, 0)), layout.mound_height * 0.5
		),
		"height query follows the mound slope"
	)
	check(
		is_equal_approx(layout.ground_height(bases[0]), layout.base_height), "height query reaches base top"
	)
	check(
		is_equal_approx(layout.ground_height(layout.plate_position), layout.home_height),
		"height query reaches plate-area dirt"
	)
	check(
		is_equal_approx(layout.ground_height(Vector2(10, -10)), layout.diamond_height),
		"height query reaches the drawn basepath"
	)
	check(
		is_equal_approx(layout.ground_height(Vector2(0, -60)), layout.grass_height),
		"height query reaches the outfield"
	)
	check(
		is_equal_approx(
			layout.ground_height(Vector2(0, -(layout.outfield_radius + layout.fence_radius) * 0.5)),
			layout.track_height
		),
		"height query reaches the warning track"
	)
	check(
		is_equal_approx(layout.ground_height(layout.workshop_pad.get_center()), layout.workshop_pad_height),
		"height query reaches the workshop pad"
	)
	check(
		is_equal_approx(
			layout.ground_height(layout.concourse.get_center()),
			layout.concourse_center_height + layout.concourse_thickness * 0.5
		),
		"height query reaches the drawn concourse"
	)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-field-layout-resource-career.dat"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	check(
		(
			g.layout == g.grass.layout
			and g.layout == g.infield.layout
			and g.layout == g.chalk.layout
			and g.layout == g.mound.layout
			and g.layout == g.get_child(0).layout
		),
		"game shares one resource before surface construction"
	)
	check(
		g.grass.total == PRE_REFACTOR_TOTALS[0] + 124 and g.infield.total == PRE_REFACTOR_TOTALS[1] + 138,
		"corrected drawn edges add the documented boundary cells"
	)
	check(
		(
			g.moisture.total == g.infield.total
			and g.chalk.valid_count == PRE_REFACTOR_TOTALS[2]
			and g.mound.total_work == PRE_REFACTOR_TOTALS[3]
		),
		"moisture shares dirt and chalk/mound totals remain unchanged"
	)
	var reference := preload("res://resources/layouts/cedar_grove_v1_masks.res")
	var grass_old: PackedByteArray = reference.get_meta("grass")
	var dirt_old: PackedByteArray = reference.get_meta("dirt")
	var removed := 0
	for i in range(grass_old.size()):
		removed += 1 if grass_old[i] == 1 and g.grass.valid[i] == 0 else 0
	for i in range(dirt_old.size()):
		removed += 1 if dirt_old[i] == 1 and g.infield.valid[i] == 0 else 0
	check(removed == 0, "geometry correction removes no previously valid cells")
	var store := FieldSave.new()
	check(
		store.layout(g) != PRE_REFACTOR_HASH and store.layout(g) == FieldSave.V2_CEDAR_HASH,
		"changed validity requires the explicitly versioned Cedar Grove signature"
	)
	var packed := FileAccess.get_file_as_bytes("res://tests/fixtures/cedar_grove_v1.dat.gz")
	var bytes := packed.decompress_dynamic(FieldSave.MAX_BYTES, FileAccess.COMPRESSION_GZIP)
	var old: Dictionary = bytes_to_var(bytes.slice(40))
	check(
		(
			old.version == 1
			and old.layout == PRE_REFACTOR_HASH
			and bytes.slice(8, 40) == store.digest(bytes.slice(40))
		),
		"real pre-refactor fixture has the hard-coded v1 signature and valid checksum"
	)
	store.path = "user://test-field-layout-v1.dat"
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()
	g.shift.open_board()
	var migrated := store.read(g)
	check(
		not migrated.is_empty() and migrated.version == 3 and old.version == 1,
		"v1 disk file migrates without modifying the source snapshot"
	)
	check(store.restore(g, g.shift, migrated), "pre-refactor save restores into the corrected field")
	check(
		(
			[
				g.grass.cut_count,
				g.infield.prepared_count,
				g.moisture.wet_count,
				g.chalk.covered_count,
				g.mound.work_done
			]
			== [284, 84, 256, 13, 1]
		),
		"migration preserves every recorded work count"
	)
	check(
		(
			g.shift.session.attempt_id == old.session.attempt_id
			and is_equal_approx(g.shift.session.elapsed_seconds, old.session.elapsed)
			and paused
		),
		"migration preserves attempt identity and paused clock"
	)
	var preserved := true
	var fresh := true
	var extra_grass := -1
	var extra_dirt := -1
	for pair in [
		[grass_old, g.grass.valid, old.grass, migrated.grass],
		[dirt_old, g.infield.valid, old.dirt, migrated.dirt]
	]:
		for i in range(pair[0].size()):
			if pair[0][i] == 1:
				for channel in range(4):
					preserved = preserved and pair[2][i * 4 + channel] == pair[3][i * 4 + channel]
			elif pair[1][i] == 1:
				fresh = fresh and pair[3][i * 4] == 0 and pair[3][i * 4 + 3] == 255
				if pair[0] == grass_old:
					extra_grass = i
				else:
					extra_dirt = i
	check(preserved, "migration preserves old pixels including stripe and drag directions")
	check(
		fresh and extra_grass >= 0 and extra_dirt >= 0 and g.moisture.moisture[extra_dirt] == 0,
		"new boundary cells begin visible, unworked and dry"
	)
	var bad := old.duplicate(true)
	bad.grass[extra_grass * 4] = 255
	check(store.migrate(bad, g).is_empty(), "migration rejects work that was invalid in the original v1 mask")
	bad = old.duplicate(true)
	bad.moisture[extra_dirt] = 0.5
	check(store.migrate(bad, g).is_empty(), "migration rejects water on originally invalid v1 dirt")
	bad = old.duplicate(true)
	bad.layout = "unrecognized-v1-park"
	check(store.migrate(bad, g).is_empty(), "migration does not accept unrelated legacy layouts")
	var ancient := old.duplicate(true)
	ancient.session.erase("attempt_id")
	var legacy_id := "legacy-" + store.digest(var_to_bytes(ancient)).hex_encode()
	check(
		store.migrate(ancient, g).session.attempt_id == legacy_id,
		"pre-career v1 saves retain their original fallback payout identity"
	)
	check(
		store.write(g, g.shift.session) and store.read(g).version == 3,
		"migrated field can be written back as a v3 slot"
	)
	g.shift.close_board()
	g.queue_free()
	await create_timer(0.15).timeout
	var alternate: FieldLayout = layout.duplicate()
	alternate.mound_position = Vector2(0, -17)
	alternate.mound_height = 0.42
	alternate.grass_resolution = Vector2i(90, 66)
	alternate.dirt_resolution = Vector2i(100, 106)
	alternate.line_end = 97
	alternate.player_spawn = Vector3(28, 0.1, -10)
	g = load("res://scenes/main/main.tscn").instantiate()
	g.layout = alternate
	g.career_save_path = "user://test-field-layout-alternate-career.dat"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	check(
		(
			g.grass.resolution == alternate.grass_resolution
			and g.infield.resolution == alternate.dirt_resolution
			and g.chalk.line_end == alternate.line_end
		),
		"alternate layout reaches masks before their ready methods"
	)
	check(
		(
			g.mound.position == alternate.point3(alternate.mound_position)
			and g.mound.top_height == alternate.mound_height
			and g.player.position == alternate.player_spawn
		),
		"alternate layout reaches mound and actor placements"
	)
	check(
		(
			g.watering.surface_height.get_object() == alternate
			and g.mower.drag.layout == alternate
			and g.tool_bay.parked_drag.layout == alternate
		),
		"hose and both drag appearances use the shared layout"
	)
	check(store.migrate(old, g).is_empty(), "legacy Cedar Grove cannot migrate into a different park")
	check(
		(
			layout.mound_height != alternate.mound_height
			and layout.grass_resolution != alternate.grass_resolution
		),
		"editing an alternate resource does not mutate Cedar Grove"
	)
	g.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(store.path)
	print("Field layout resource: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
