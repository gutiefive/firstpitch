extends SceneTree
var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func award(c: CareerProfile, profile: String) -> String:
	var s := ShiftSession.new()
	s.start(profile)
	s.set_progress(s.goals(), [true, true, true, true, true])
	s.advance(0)
	var id := s.attempt_id
	c.claim(id, s.get_result())
	s.free()
	return id


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-expansion-career.dat"
	g.settings_save_path = "user://test-expansion-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	await process_frame
	var c: CareerProfile = g.shift.career
	g.club.join()
	check(not c.purchase_stadium("scoreboard"), "scoreboard requires fans and funds")
	check(
		not c.purchase_stadium("grill_stand") and not c.purchase_stadium("video_board"),
		"later amenities require prerequisites"
	)
	for i in range(15):
		award(c, "full")
	for i in range(15):
		c.host_game(award(c, "home_game"))
	var old_income: int = c.club.income
	var old_receipt: Dictionary = c.club.last.duplicate(true)
	var before := c.balance
	var original_path := c.path
	c.path = "user://missing-expansion-folder/career.dat"
	check(
		not c.purchase_stadium("scoreboard") and c.balance == before and "scoreboard" not in c.club.buildings,
		"failed construction save leaves money and buildings unchanged"
	)
	c.path = original_path
	check(
		g.club.build("scoreboard") and c.balance == before - 1100, "electronic scoreboard charges exact price"
	)
	check(
		c.club.income == old_income and c.club.last == old_receipt, "construction never reprices old receipts"
	)
	check(
		(
			g.club.world.structures.has_node("OwlsElectronicScoreboard")
			and not g.stadium.get_node("Scoreboard").visible
		),
		"new scoreboard replaces stock board"
	)
	check(not c.purchase_stadium("scoreboard"), "scoreboard cannot be charged twice")
	var preview := ClubProgress.forecast(c.club, {"score": 100})
	check(preview.ticket_income == preview.attendance * 5, "electronic board adds one credit per ticket")
	check(g.club.build("snack_shack") and g.club.build("grill_stand"), "snack shack unlocks grill concession")
	check(g.club.world.structures.has_node("OwlsGrillStand"), "grill is a physical concourse building")
	preview = ClubProgress.forecast(c.club, {"score": 100})
	check(preview.food_income == preview.attendance * 2, "two concessions stack food profit")
	check(
		g.club.build("bleachers") and g.club.build("grandstand") and g.club.build("video_board"),
		"covered seating and electronic board unlock video upgrade"
	)
	check(
		(
			g.club.world.structures.has_node("OwlsVideoBoard")
			and not g.club.world.structures.has_node("OwlsElectronicScoreboard")
		),
		"video upgrade replaces electronic display"
	)
	preview = ClubProgress.forecast(c.club, {"score": 100})
	check(
		preview.ticket_income == preview.attendance * 7 and preview.fans_gained == 39,
		"all expansion benefits stack with original stadium benefits"
	)
	check(
		c.club.capacity == 480 and g.club.world.seat_count == 480, "amenity upgrades preserve real seat count"
	)
	var restored := CareerProfile.new()
	restored.path = c.path
	restored.load_profile()
	check(
		restored.club == c.club and restored.balance == c.balance,
		"reload preserves all six buildings and exact budget"
	)
	check(g.shift.overlay.club_panel.projects.size() == 6, "clubhouse exposes all six stadium projects")
	if DisplayServer.get_name() != "headless":
		g.shift.open_board()
		g.shift.overlay.club_button.pressed.emit()
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/firstpitch-expansion-menu.png")
		g.shift.close_board()
		g.hud.visible = false
		g.shift.overlay.visible = false
		var camera := Camera3D.new()
		g.add_child(camera)
		camera.current = true
		camera.position = Vector3(-48, 30, 45)
		camera.look_at(Vector3(-5, 0, 12))
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/firstpitch-expansion-concourse.png")
		camera.position = Vector3(26, 15, -55)
		camera.look_at(g.club.world.structures.get_node("OwlsVideoBoard").position + Vector3(0, 9, 0))
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/firstpitch-expansion-scoreboard.png")
	DirAccess.remove_absolute(c.path)
	g.queue_free()
	await process_frame
	print("Stadium expansion: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
