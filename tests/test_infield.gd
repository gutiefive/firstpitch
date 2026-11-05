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
	check(dirt.world_to_grid(Vector3(-25, 0, -45)) == Vector2i.ZERO, "dirt grid origin maps correctly")
	check(dirt.total > 1000, "dirt has a nonempty scored area")
	check(dirt.is_workable(Vector2(10, -10)), "basepath is workable")
	check(not dirt.is_workable(Vector2(0, -25)), "infield lawn is excluded")
	check(not dirt.is_workable(dirt.layout.mound_position), "mound is excluded")
	check(not dirt.is_workable(dirt.layout.base_positions()[0]), "base pad is excluded")
	check(not dirt.is_workable(Vector2(0, 0)), "plate and batter area are excluded")
	check(not dirt.is_workable(Vector2(0, -102)), "warning track is excluded")
	var direction := Vector3(1, 0, -1).normalized()
	dirt.paint(Vector3(10, 0, -10), direction, 2.8, 1.2)
	check(dirt.prepared_count > 40, "oriented drag footprint prepares dirt")
	check(
		dirt.image.get_pixelv(dirt.world_to_grid(Vector3(10.7, 0, -9.3))).r > 0.5,
		"drag covers its full working width"
	)
	check(
		dirt.image.get_pixelv(dirt.world_to_grid(Vector3(11.2, 0, -8.8))).r < 0.5,
		"beyond the working width stays rough"
	)
	check(
		dirt.image.get_pixelv(dirt.world_to_grid(Vector3(11, 0, -11))).r < 0.5,
		"beyond the working depth stays rough"
	)
	dirt.drag_segment(Vector3(6, 0, -6), Vector3(15, 0, -15), direction, 2.8, 1.2)
	var count := dirt.prepared_count
	check(count > 500, "diagonal swept drag leaves a continuous broad path")
	dirt.drag_segment(Vector3(6, 0, -6), Vector3(15, 0, -15), direction, 2.8, 1.2)
	check(count == dirt.prepared_count, "overlapping drag passes count once")
	dirt.paint(Vector3(0, 0, -102), Vector3.FORWARD, 2.8, 1.2)
	dirt.paint(Vector3(0, 0, -25), Vector3.FORWARD, 2.8, 1.2)
	check(count == dirt.prepared_count, "non-dirt preparation cannot inflate progress")
	check(
		is_equal_approx(dirt.percentage(), 100.0 * count / dirt.total),
		"dirt percentage uses unique valid cells"
	)
	print("Infield failures: ", failures)
	quit(1 if failures else 0)
