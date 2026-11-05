extends SceneTree
var failures := 0


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error(message)
		failures += 1


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var dirt := InfieldSurface.new()
	root.add_child(dirt)
	var water := DirtMoisture.new()
	root.add_child(water)
	water.bind_surface(dirt)
	var point := Vector3(10, 0, -10)
	check(
		water.total == dirt.total and water.percentage() == 0,
		"watering uses the valid dirt area and starts dry"
	)
	water.spray_at(point, 0)
	check(water.moisture_at(point) == 0, "zero exposure adds no water")
	water.spray_at(point, 0.1)
	check(
		water.moisture_at(point) > 0 and water.wet_count == 0,
		"a brief pass dampens dirt without completing it"
	)
	water.spray_at(point, 0.9)
	check(water.wet_count > 0, "sustained exposure reaches target moisture")
	var other := DirtMoisture.new()
	root.add_child(other)
	other.bind_surface(dirt)
	for i in range(10):
		other.spray_at(point, 0.1)
	check(
		absf(water.moisture_at(point) - other.moisture_at(point)) < 0.00001,
		"equal exposure is stable across timestep sizes"
	)
	check(water.wet_count == other.wet_count, "timestep sizes preserve qualified-cell counts")
	check(water.moisture_at(Vector3(10.8, 0, -9.2)) > 0, "spray has a broad circular footprint")
	check(water.moisture_at(Vector3(13, 0, -13)) == 0, "outside spray footprint remains dry")
	var count := water.wet_count
	water.spray_at(Vector3(0, 0, -60), 5)
	water.spray_at(Vector3(0, 0, -25), 5)
	water.spray_at(dirt.layout.point3(dirt.layout.mound_position), 5)
	water.spray_at(Vector3.ZERO, 5)
	water.spray_at(Vector3(500, 0, -500), 5)
	check(water.wet_count == count, "grass, lawn, mound, plate and outside bounds earn no water credit")
	water.spray_at(dirt.layout.point3(dirt.layout.base_positions()[0]), 5)
	check(
		water.moisture_at(dirt.layout.point3(dirt.layout.base_positions()[0])) == 0,
		"base pad stays protected when spray overlaps nearby dirt"
	)
	for i in range(8):
		water.spray_at(point, 1)
	count = water.wet_count
	water.spray_at(point, 5)
	check(water.wet_count == count, "repeated soaking cannot inflate completion")
	check(water.moisture_at(point) == 1, "moisture saturates at one")
	check(
		is_equal_approx(water.percentage(), 100.0 * water.wet_count / water.total),
		"watering percentage uses unique sufficiently wet cells"
	)
	check(dirt.prepared_count == 0, "watering does not prepare dirt for dragging")
	var before := water.moisture_at(point)
	dirt.paint(point, Vector3.FORWARD, 2.8, 1.2)
	check(water.moisture_at(point) == before, "dragging preserves independent moisture state")
	var events := [0]
	water.completion_changed.connect(func(_percent: float): events[0] += 1)
	water._process(0.2)
	check(events[0] == 1, "dirty moisture batches publish progress")
	water._process(0.2)
	check(events[0] == 1, "idle moisture does not repeatedly publish unchanged data")
	print("Moisture failures: ", failures)
	quit(1 if failures else 0)
