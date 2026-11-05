extends "res://tests/test_stadium_expansion.gd"


func capture_growth(g: Node, name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var camera := Camera3D.new()
	g.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 180
	camera.position = Vector3(95, 125, 95)
	camera.look_at(Vector3(0, 0, -22))
	if name == "concessions":
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.position = g.club.world.concession_point("snack_shack", Vector3(-8, 4, -7.5))
		camera.look_at(g.club.world.concession_point("snack_shack", Vector3(0, 1.4, -1.8)))
	camera.current = true
	g.hud.visible = false
	g.shift.overlay.visible = false
	for i in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/firstpitch-growth-" + name + ".png")
	camera.queue_free()
	g.camera.current = true


func clear_route(g: Node, route: PackedVector3Array) -> bool:
	# Sample entire segments, not just endpoints: the workshop and concessions are solid.
	for i in range(1, route.size()):
		var length := route[i - 1].distance_to(route[i])
		for step in range(ceili(length * 2) + 1):
			var point := route[i - 1].lerp(route[i], minf(1, float(step) / maxf(1, ceili(length * 2))))
			var shop: Vector3 = point - g.layout.workshop_position
			if absf(shop.x) < 4.5 and absf(shop.z) < 4:
				return false
			if absf(point.x) < 2.9 and point.z > 27 and point.z < 31:
				return false
			for id in ["snack_shack", "grill_stand"]:
				var local: Vector3 = g.club.world.concession_transform(id).affine_inverse() * point
				if id in g.shift.career.club.buildings and absf(local.x) < 3.3 and absf(local.z) < 2:
					return false
	return true


func walk_public(g: Node, route: PackedVector3Array) -> bool:
	g.player.position = route[0] + Vector3.UP * 0.1
	g.player.velocity = Vector3.ZERO
	Input.action_press("forward")
	Input.action_press("sprint")
	var steps := 0
	var reached := true
	for goal in route.slice(1):
		while Vector2(g.player.position.x - goal.x, g.player.position.z - goal.z).length() > 0.9:
			var direction: Vector3 = goal - g.player.position
			g.yaw = atan2(-direction.x, -direction.z)
			g.player.yaw = g.yaw
			await physics_frame
			g.club.live._process(0)
			steps += 1
			if steps > 1800:
				reached = false
				print("Walk blocked at ", g.player.position, " toward ", goal)
				break
		if not reached:
			break
	Input.action_release("forward")
	Input.action_release("sprint")
	g.player.velocity = Vector3.ZERO
	return reached


func run() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://ballpark-growth-career.dat"
	g.settings_save_path = "user://ballpark-growth-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	await process_frame
	var c: CareerProfile = g.shift.career
	var world: ClubStadium = g.club.world
	var park: MatchdayPark = g.club.matchday
	var live: LiveMatchday = g.club.live
	g.club.opening.set_process(false)
	park.set_process(false)
	live.set_process(false)
	g.club.join()
	check(
		world.seat_count == 120 and world.section_roots.size() == 2,
		"starter park keeps its two home-plate sections"
	)
	await capture_growth(g, "starter")
	# Earn the construction budget and fan requirements through the real ledger.
	for i in range(15):
		award(c, "full")
	for i in range(15):
		c.host_game(award(c, "home_game"))
	check(g.club.build("bleachers"), "earned funds buy the line expansion")
	check(
		world.seat_count == 240 and world.section_roots.size() == 4,
		"bleachers add 60 seats on each foul line"
	)
	var mirrored := {-1: 0, 1: 0}
	for section in world.section_roots:
		var side: int = section.get_meta("wing")
		if side != 0:
			mirrored[side] += 1
			check(
				section.position.z < 0 and section.basis.z.dot(world.wing_outward(side)) > 0.99,
				"line sections face into the diamond"
			)
	check(mirrored[-1] == 1 and mirrored[1] == 1, "both lines gain a section instead of another rear row")
	await capture_growth(g, "bleachers")
	check(
		g.club.build("snack_shack") and g.club.build("grill_stand") and g.club.build("grandstand"),
		"concessions and covered sections build through existing progression"
	)
	check(
		world.seat_count == 480 and world.section_roots.size() == 8,
		"covered upgrade extends both wings to eight total sections"
	)
	var clear := true
	var seats := {}
	for seat in world.seat_positions:
		seats[seat] = true
		var access: Dictionary = world.seat_access[seat]
		clear = clear and clear_route(g, access.route)
	check(
		seats.size() == 480 and world.seat_access.size() == 480,
		"all transformed seats have unique matching access routes"
	)
	check(clear, "every section approach clears the workshop, ticket booth and concession walls")
	for id in ["snack_shack", "grill_stand"]:
		var side := 1 if id == "snack_shack" else -1
		var building: Node3D = world.structures.get_node("OwlsSnackShack" if side > 0 else "OwlsGrillStand")
		check(
			building.position.z < 0 and building.basis.z.dot(world.wing_outward(side)) > 0.99,
			"concession faces its foul-line promenade"
		)
	g.shift.enter_practice()
	g.club.sync()
	g.shift.close_board()
	check(live.start(), "expanded park opens as a live visit")
	var routes_clear := true
	for a in park.agents:
		routes_clear = routes_clear and clear_route(g, a.route) and clear_route(g, a.seat_route)
	check(routes_clear, "moving fan routes clear all relocated buildings")
	var queues_face_counters := true
	var queued := 0
	for a in park.agents:
		if a.state == "queue":
			queued += 1
			var side := -1 if a.node.position.x < 0 else 1
			queues_face_counters = (
				queues_face_counters and (-a.node.basis.z).normalized().dot(world.wing_outward(side)) > 0.99
			)
	check(
		queued > 0 and queues_face_counters, "customers face the serving windows on both rotated concessions"
	)
	var supply: Dictionary = live.jobs[2]
	g.player.position = supply.point
	live.interact_job()
	check(
		supply.point.distance_to(world.service_point()) < 0.01 and supply.point.z < 0,
		"supply delivery follows the relocated serving counter"
	)
	var destination: Vector3 = supply.point
	live._process(0)
	check(
		g.player.position.distance_to(Vector3(4, 0.05, 24)) < 0.2,
		"pickup remains on the public home concourse"
	)
	g.player.position = destination
	live._process(0)
	check(
		g.player.position.distance_to(destination) < 0.01, "live boundary permits the new concession approach"
	)
	live.interact_job()
	check(supply.state == "done", "delivery completes at the new line-side concession")
	Engine.time_scale = 8
	for side in [-1, 1]:
		var route := world.wing_route(side, 61 if side > 0 else 43)
		route.append(world.concession_point("snack_shack" if side > 0 else "grill_stand"))
		check(
			await walk_public(g, route),
			(
				"real player controller walks from home concourse to line-side counter without "
				+ "collisions or boundary clamps"
			)
		)
	Engine.time_scale = 1
	for side in [-1, 1]:
		var public: Vector3 = world.wing_point(side, 60, 14) + Vector3.UP * 0.1
		g.player.position = public
		live._process(0)
		check(
			g.player.position.distance_to(public) < 0.01,
			"live boundary keeps public wing walkways accessible"
		)
		g.player.position = world.wing_point(side, 60, -3) + Vector3.UP * 0.1
		live._process(0)
		check(live.public_wing(g.player.position), "live boundary excludes the field along each foul line")
	g.club.life._process(1)
	check(
		(
			g.club.life.loops.snacks.position.distance_to(
				world.concession_point("snack_shack", Vector3(0, 1.4, -3))
			)
			< 0.01
		),
		"localized concession sound follows its building"
	)
	g.club.opening.update_view(9.0 / 47)
	check(
		g.club.opening.camera.position.distance_to(world.service_point()) < 20,
		"concourse presentation follows relocated concessions"
	)
	# Exercise every section, including the new outer banks, rather than only near-home seats.
	for i in range(park.agents.size()):
		var index := i % 8 + (int(i / 8) * 17 % 60) * 8
		var seat: Vector3 = world.seat_positions[index]
		var access: Dictionary = world.seat_access[seat]
		var a: Dictionary = park.agents[i]
		a.seat = seat - Vector3(0, 0.79, 0)
		a.seat_route = access.route
		a.seat_yaw = access.yaw
		a.node.position = a.seat_route[0]
		a.state = "find_seat"
		a.step = 0
		a.wait = 0
	live.visit_time = 150
	park.set_time(20)
	var arrived := {}
	for i in range(2400):
		park.advance_routines(0.1)
		for a in park.agents:
			if a.state == "seated":
				arrived[a.index] = true
	check(
		arrived.size() == park.agents.size(),
		"fans reach seats in all eight sections using transformed access routes"
	)
	var facing := true
	for a in park.agents:
		if a.state == "seated":
			facing = facing and absf(angle_difference(a.node.rotation.y, a.seat_yaw)) < 0.01
	check(facing, "seated moving fans face the same direction as their section")
	live.visit_time = LiveMatchday.FINAL + 1
	for i in range(3600):
		park.advance_routines(0.1)
	var departed := 0
	for a in park.agents:
		departed += int(a.state == "departed")
	check(departed == park.agents.size(), "fans return from both line wings and exit after the final")
	live.end_visit(false)
	await capture_growth(g, "covered")
	await capture_growth(g, "concessions")
	var saved := CareerProfile.new()
	saved.path = c.path
	saved.load_profile()
	check(
		saved.club == c.club and saved.balance == c.balance,
		"new arrangement preserves existing purchases and career ledger"
	)
	paused = false
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute("user://ballpark-growth-career.dat")
	DirAccess.remove_absolute("user://ballpark-growth-settings.cfg")
	print("Ballpark growth: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
