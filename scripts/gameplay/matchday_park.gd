class_name MatchdayPark
extends Node3D
# Decorative matchday simulation. Settlement remains owned by CareerProfile.
const G = preload("res://scripts/gameplay/geometry.gd")
var game: Node
var agents: Array[Dictionary] = []
var regular: Node3D
var fielders: Array[Dictionary] = []
var actors: Node3D
var ball: MeshInstance3D
var runner: Node3D
var bat: Node3D
var score_sign: Label3D
var identity: Node3D
var signature := ""
var fixture := {}
var receipt := {}
var inning := 0
var home_runs := 0
var away_runs := 0
var stage := "quiet"
var clock := 0.0
var hosted := false
var story_lines := PackedStringArray()
var staff_count := 0
var workers: Array[Node3D] = []
var ambient_time := 0.0
var scoreboards: Array[Label3D] = []
const TEAM_COLORS := {
	"Mill Creek Foxes": Color("ae633c"),
	"Riverbend Otters": Color("436e93"),
	"Pine Ridge Bears": Color("765c80"),
	"Maple Falls Robins": Color("a74f55")
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	identity = Node3D.new()
	add_child(identity)
	actors = Node3D.new()
	actors.name = "MatchdayPlayers"
	add_child(actors)
	for p in [
		Vector3(0, 0.35, -18),
		Vector3(0, 0, -1),
		Vector3(-18, 0, -20),
		Vector3(18, 0, -20),
		Vector3(-10, 0, -30),
		Vector3(10, 0, -30),
		Vector3(-25, 0, -49),
		Vector3(0, 0, -58),
		Vector3(25, 0, -49)
	]:
		var player := person(actors, Color("e0d7bd"), 2)
		player.position = p
		if fielders.is_empty():
			player.rotation.y = PI
		fielders.append({"node": player, "origin": p})
	var batter := actors.get_child(1) as Node3D
	bat = Node3D.new()
	bat.position = Vector3(0.32, 1.05, -0.15)
	batter.add_child(bat)
	G.cylinder(bat, Vector3(0, 0.4, 0), 0.04, 0.8, Color("b89769"))
	runner = person(actors, Color("4e7f80"), 1)
	ball = G.sphere(actors, Vector3(0, 1, -18), Vector3.ONE * 0.15, Color("f5eedc"))
	actors.visible = false
	score_sign = G.label(self, "", Vector3(-14, 3.5, 25), 30)
	score_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	score_sign.pixel_size = 0.009
	score_sign.modulate = Color("f1db9f")
	score_sign.visible = false


func person(parent: Node3D, shirt: Color, index: int) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var skin: Color = [Color("bd9279"), Color("8e6450"), Color("d2aa87")][posmod(index, 3)]
	G.tailored_body(root, Vector3(0, 1.08, 0), shirt)
	var head := G.sphere(root, Vector3(0, 1.62, 0), Vector3(0.30, 0.36, 0.29), skin)
	head.name = "Head"
	var cap := G.sphere(root, Vector3(0, 1.77, 0.02), Vector3(0.34, 0.12, 0.33), Color("244e53"))
	cap.name = "Cap"
	var brim := G.soft_box(root, Vector3(0, 1.77, -0.13), Vector3(0.33, 0.025, 0.21), Color("244e53"))
	brim.name = "Brim"
	for x in [-0.06, 0.06]:
		G.sphere(root, Vector3(x, 1.65, -0.14), Vector3.ONE * 0.023, Color("282f30"))
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.name = "LegLeft" if side == -1 else "LegRight"
		leg.position = Vector3(side * 0.12, 0.79, 0)
		root.add_child(leg)
		G.capsule(leg, Vector3(0, -0.16, 0), 0.085, 0.36, Color("45535b"))
		var knee := Node3D.new()
		knee.name = "Knee"
		knee.position.y = -0.32
		leg.add_child(knee)
		G.capsule(knee, Vector3(0, -0.15, 0), 0.075, 0.33, Color("45535b"))
		G.soft_box(knee, Vector3(0, -0.34, -0.05), Vector3(0.19, 0.12, 0.28), Color("393c39"))
		var arm := G.capsule(root, Vector3(side * 0.27, 0.99, 0), 0.065, 0.50, skin)
		arm.name = "ArmLeft" if side == -1 else "ArmRight"
	return root


func sync(state: Dictionary) -> void:
	var key := str([state.active, state.games, state.buildings, game.club.world.rebuilds])
	if key == signature:
		return
	signature = key
	for a in agents:
		a.node.queue_free()
	agents.clear()
	for node in identity.get_children():
		node.queue_free()
	staff_count = 0
	workers.clear()
	hosted = state.active and not state.last.is_empty()
	visible = state.active
	if not state.active:
		return
	fixture = ClubSchedule.fixture(maxi(0, int(state.games) - 1))
	for i in range(fielders.size()):
		dress(fielders[i].node, "OWLS" if i != 1 else fixture.opponent, i + 1)
	dress(runner, fixture.opponent, 12)
	var count := mini(28, maxi(8, int(state.last.get("attendance", 0)) / 3)) if hosted else 0
	var colors := [Color("c09e69"), Color("6f8580"), Color("9d6e5d"), Color("587186"), Color("b9bbaa")]
	for i in range(count):
		var fan := person(self, colors[i % colors.size()], i)
		fan.name = "MovingSupporter%d" % i
		var cap_color: Color = [Color("28585a"), Color("49596d"), Color("a28a62")][i % 3]
		fan.get_node("Cap").material_override = G.material(cap_color)
		fan.get_node("Brim").material_override = G.material(cap_color)
		if i % 3 == 0:
			for y in [1.0, 1.12, 1.24]:
				G.box(fan, Vector3(0, y, -0.17), Vector3(0.32, 0.025, 0.015), Color("d2c5a1"))
		elif i % 3 == 1:
			for side in [-1, 1]:
				G.soft_box(
					fan, Vector3(side * 0.07, 1.25, -0.18), Vector3(0.07, 0.26, 0.025), Color("28585a")
				)
		else:
			var badge := G.label(fan, "CG", Vector3(0, 1.18, -0.18), 20)
			badge.pixel_size = 0.003
			badge.rotation.y = PI
		fan.scale = Vector3.ONE * (0.80 if i % 7 == 0 else 0.95 + float(i % 3) * 0.04)
		var side := -1.0 if i % 2 == 0 else 1.0
		# Routes pass either side of the solid ticket booth, then behind the stands.
		var lane: float = side * (4.0 + float(i % 3) * 0.55)
		var destination := Vector3(side * (9 + float(i % 5) * 3.8), 0.05, 24 + float(i % 3) * 0.5)
		var route := PackedVector3Array(
			[
				Vector3(lane, 0.05, 39 + float(i % 5) * 1.4),
				Vector3(lane, 0.05, 33),
				Vector3(lane, 0.05, 25.2),
				destination
			]
		)
		var concession := "snack_shack" if side > 0 else "grill_stand"
		if concession in state.buildings:
			var wing: PackedVector3Array = game.club.world.wing_route(int(side), 61 if side > 0 else 43)
			# Queue indices follow the authored approach, including the first-base workshop detour.
			route.resize(3)
			route.append_array(wing)
			var stop := route.size()
			route.append(
				game.club.world.concession_point(concession, Vector3(float(i % 3) * 0.45, 0.05, -4.5))
			)
			fan.set_meta("service_stop", stop)
		# Walk back along the same clear approach rather than cutting through buildings.
		for j in range(route.size() - 2, 1, -1):
			route.append(route[j])
		fan.position = route[0]
		var target := 1
		var wait := float(i) * 0.22
		# Early regulars already at service keep the concourse alive while arrivals enter.
		if route.size() > 8 and i >= 5 and (i % 4 == 1 if side > 0 else i % 4 == 0):
			var stop: int = fan.get_meta("service_stop")
			fan.position = route[stop]
			fan.rotation.y = game.club.world.wing_yaw(int(side)) + PI
			target = stop + 1
			wait = 8 + float(i % 5)
		agents.append(
			{
				"node": fan,
				"route": route,
				"target": target,
				"wait": wait,
				"phase": float(i),
				"speed": 1.1 + float(i % 4) * 0.17
			}
		)
	scoreboards.clear()
	for id in ["OwlsElectronicScoreboard", "OwlsVideoBoard"]:
		var board: Node = game.club.world.structures.get_node_or_null(id)
		if board != null:
			for label in board.find_children("*", "Label3D", true, false):
				scoreboards.append(label)
	build_identity(state)
	story_lines = stories(state)


func build_identity(state: Dictionary) -> void:
	regular = person(identity, Color("6c8b7c"), 1)
	regular.position = Vector3(-7, 0.05, 24)
	regular.rotation.y = PI
	var regular_name := G.label(regular, "ELI · SEASON-TICKET REGULAR", Vector3(0, 2.1, 0), 24)
	regular_name.pixel_size = 0.008
	regular_name.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var items := {
		"bleachers": [Vector3(-15, 0, 24), "THE TOWN'S SECTION"],
		"grandstand": [Vector3(15, 0, 24), "COVERED SEATS · OWLS COUNTRY"],
		"snack_shack": [Vector3(28.5, 0, 16.5), "LENI'S LOCAL FAVORITES"],
		"grill_stand": [Vector3(-29, 0, 15), "HOT OFF THE GRILL"],
		"scoreboard": [Vector3(12, 0, 25), "FOLLOW EVERY INNING"],
		"video_board": [Vector3(-12, 0, 25), "MAKE SOME NOISE, CEDAR GROVE!"]
	}
	for id in state.buildings:
		var p: Vector3 = items[id][0]
		if id in ["snack_shack", "grill_stand"]:
			p = game.club.world.concession_point(id, Vector3(-3, 0, -4.4))
		elif id in ["bleachers", "grandstand"]:
			p = game.club.world.wing_point(
				-1 if id == "bleachers" else 1, 36 if id == "bleachers" else 68, 14
			)
		G.cylinder(identity, p + Vector3(0, 1.1, 0), 0.045, 2.2, Color("536362"))
		var placard := G.label(identity, items[id][1], p + Vector3(0, 2.4, 0), 28)
		placard.pixel_size = 0.009
		placard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		placard.modulate = Color("edcf8b")
		if id in ["snack_shack", "grill_stand"]:
			var worker := person(identity, Color("c1aa81"), staff_count)
			workers.append(worker)
			worker.position = game.club.world.concession_point(id, Vector3(2.4, 0.05, -3))
			worker.rotation.y = game.club.world.wing_yaw(1 if id == "snack_shack" else -1)
			var nameplate := G.label(
				identity,
				"LENI · CONCESSIONS" if id == "snack_shack" else "GRILL CREW",
				worker.position + Vector3(0, 2.2, 0),
				22
			)
			nameplate.pixel_size = 0.008
			nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			staff_count += 1
			var lamp := OmniLight3D.new()
			lamp.position = p + Vector3(0, 2.6, 0)
			lamp.light_color = Color("ffdb97")
			lamp.light_energy = 0.7
			lamp.omni_range = 5
			identity.add_child(lamp)


func stories(state: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append(
		(
			"Mara · Opening Day starts with your prep. Let’s give this town a reason to come back."
			if state.last.is_empty()
			else (
				"Mara · Look at that line at the gates. That field is something to be proud of."
				if float(state.last.score) >= 85
				else (
					"Mara · The field still needs work, but they showed up for us. We keep improving, one "
					+ "home date at a time."
				)
			)
		)
	)
	lines.append(
		(
			"Eli, season-ticket regular · "
			+ (
				"I brought my neighbors. We finally have room to sit together."
				if "bleachers" in state.buildings
				else "Same seat, every summer. Keep this little park ours."
			)
		)
	)
	lines.append(
		(
			"Leni, concessions · "
			+ (
				"The stand is open and the first order is up. A good crowd keeps this place going."
				if "snack_shack" in state.buildings
				else "Someday we'll have our own snack stand. Right now, keep bringing people back."
			)
		)
	)
	if "grandstand" in state.buildings:
		lines.append(
			"Mara · Covered seats, families staying longer. This is becoming a place the town can count on."
		)
	if int(state.games) > 0 and int(state.games) % 6 == 0:
		lines.append("Mara · Six home dates in the books. Your ownership review is waiting in the Clubhouse.")
	else:
		lines.append(
			(
				"Mara · Next comes "
				+ String(ClubSchedule.fixture(state.games).event)
				+ ". Take a breath, then let's get ready."
			)
		)
	if int(state.games) >= 3:
		lines.append(
			"Eli · I recognize more faces every home date. This is turning into our town’s meeting place."
		)
	if int(state.games) >= 6:
		(
			lines
			. append(
				(
					"Leni · A whole season of opening the shutters together. Thanks for always checking on the crew."
					if "snack_shack" in state.buildings
					else (
						"Leni · A whole season together. I’m still saving ideas for our first stand. Thanks for "
						+ "checking on the crew."
					)
				)
			)
		)
	return lines


func begin(value: Dictionary) -> void:
	receipt = value.duplicate(true)
	clock = 0
	set_time(0)


func set_time(seconds: float) -> void:
	clock = seconds
	stage = (
		"arrivals"
		if seconds < 7
		else ("concourse" if seconds < 13 else ("game" if seconds < 40 else "stories"))
	)
	inning = clampi(1 + int((seconds - 13) / 3), 1, 9) if seconds >= 13 else 0
	var score := score_for(int(receipt.get("game", 1)), inning)
	home_runs = score.x
	away_runs = score.y
	score_sign.text = (
		"OWLS %d  ·  %s %d\n%s"
		% [
			home_runs,
			String(fixture.get("opponent", "VISITORS")).to_upper(),
			away_runs,
			(
				"INNING %d / 9" % inning
				if stage == "game"
				else (
					"FINAL · THANK YOU, CEDAR GROVE" if stage == "stories" else "GATES OPEN · FIND YOUR SEAT"
				)
			)
		]
	)
	for display in scoreboards:
		if is_instance_valid(display):
			display.text = "CEDAR GROVE OWLS\n" + score_sign.text
	score_sign.visible = hosted and not game.club.opening.active and stage in ["game", "stories"]
	actors.visible = stage == "game"
	if game.club.atmosphere != null:
		game.club.atmosphere.observe(self)
	if actors.visible:
		var phase := fposmod(seconds - 13, 3.0) / 3.0
		bat.rotation.z = -0.8
		bat.rotation.y = -1.5 + clampf((phase - 0.25) * 8, 0, 3.5)
		if phase < 0.35:
			ball.position = Vector3(0, 1.2, -18).lerp(Vector3(0, 1, 0), phase / 0.35)
		else:
			var t := (phase - 0.35) / 0.65
			ball.position = Vector3(0, 1, 0).lerp(Vector3(20, 0.2, -40), t) + Vector3.UP * sin(t * PI) * 12
		var bases := [
			Vector3(0, 0, 0), Vector3(19, 0, -19), Vector3(0, 0, -38), Vector3(-19, 0, -19), Vector3(0, 0, 0)
		]
		var leg := mini(3, int(phase * 4))
		runner.position = bases[leg].lerp(bases[leg + 1], fposmod(phase * 4, 1))
		runner.look_at(bases[leg + 1])
		runner.get_node("LegLeft").rotation.x = sin(phase * PI * 24) * 0.5
		runner.get_node("LegRight").rotation.x = -sin(phase * PI * 24) * 0.5
		for i in range(2, fielders.size()):
			var fielder: Node3D = fielders[i].node
			var origin: Vector3 = fielders[i].origin
			var target := Vector3(ball.position.x, 0, ball.position.z)
			fielder.position = origin.move_toward(target, maxf(0, sin(phase * PI)) * 1.2)
			if fielder.position.distance_squared_to(target) > 0.1:
				fielder.look_at(target)
			fielder.get_node("LegLeft").rotation.x = sin(phase * PI * 12) * 0.25
			fielder.get_node("LegRight").rotation.x = -sin(phase * PI * 12) * 0.25


func complete() -> void:
	if not receipt.is_empty():
		set_time(40)
	actors.visible = false


func _process(delta: float) -> void:
	var showing: bool = game.club.opening != null and game.club.opening.active
	var allowed: bool = hosted and game.shift.session.phase == ShiftSession.Phase.PRACTICE
	visible = game.shift.career.club.active
	for a in agents:
		a.node.visible = allowed and a.get("state", "") != "departed"
	actors.visible = (
		allowed and (showing or (game.club.live != null and game.club.live.active)) and stage == "game"
	)
	score_sign.visible = allowed and hosted and not showing and stage in ["game", "stories"]
	if not allowed or (get_tree().paused and not showing) or (showing and game.club.opening.playback_paused):
		return
	if game.club.live != null and game.club.live.active:
		advance_routines(minf(delta, 0.1) * (game.club.opening.playback_speed if showing else 1.0))
	else:
		advance(minf(delta, 0.1) * (game.club.opening.playback_speed if showing else 1.0))


func advance(delta: float) -> void:
	ambient_time += delta
	for worker in workers:
		worker.get_node("ArmRight").rotation.x = 0.5 + sin(ambient_time * 2) * 0.2
	for a in agents:
		var fan: Node3D = a.node
		if a.wait > 0:
			a.wait -= delta
			continue
		var goal: Vector3 = a.route[a.target]
		var distance := fan.position.distance_to(goal)
		if distance < 0.08:
			if a.target == int(fan.get_meta("service_stop", -1)):
				fan.rotation.y = game.club.world.wing_yaw(-1 if fan.position.x < 0 else 1) + PI
			a.target = 2 if a.target == a.route.size() - 1 else a.target + 1
			a.wait = 1.5 + float(a.target % 3) * 0.7
		else:
			var direction := (goal - fan.position).normalized()
			fan.position = fan.position.move_toward(goal, a.speed * delta)
			fan.rotation.y = atan2(-direction.x, -direction.z)
			a.phase += delta * 6
			fan.get_node("LegLeft").rotation.x = sin(a.phase) * 0.32
			fan.get_node("LegRight").rotation.x = -sin(a.phase) * 0.32
			fan.get_node("LegLeft/Knee").rotation.x = -maxf(0, sin(a.phase)) * 0.4
			fan.get_node("LegRight/Knee").rotation.x = -maxf(0, -sin(a.phase)) * 0.4
			fan.get_node("ArmLeft").rotation.x = -sin(a.phase) * 0.22
			fan.get_node("ArmRight").rotation.x = sin(a.phase) * 0.22


static func score_for(date: int, innings: int = 9) -> Vector2i:
	var home := 0
	var away := 0
	for n in range(innings):
		home += int(posmod(date * 5 + n * 5, 7) < 2)
		away += int(posmod(date * 3 + n * 4, 9) < 2)
	if innings == 9 and home == away:
		home += int(date % 2 == 0)
		away += int(date % 2 != 0)
	return Vector2i(home, away)


func begin_routines() -> void:
	for i in range(agents.size()):
		var a: Dictionary = agents[i]
		var seat: Vector3 = game.club.world.seat_positions[i]
		var access: Dictionary = game.club.world.seat_access[seat]
		a.index = i
		a.state = "queue" if a.target == int(a.node.get_meta("service_stop", -2)) + 1 else "arriving"
		a.seat = seat - Vector3(0, 0.79, 0)
		a.approach = access.route[-1]
		a.seat_route = access.route
		a.seat_yaw = access.yaw
		a.step = 0
		a.timer = 0.0
		a.last_inning = 0
		a.last_score = 0
		a.cheer = 0.0
		a.direction = Vector3.ZERO
		a.blocked = 0.0


func walk_routine(a: Dictionary, goal: Vector3, delta: float) -> bool:
	var fan: Node3D = a.node
	if fan.position.distance_to(goal) < 0.12:
		return true
	var direction := (goal - fan.position).normalized()
	var blocked := false
	for other in agents:
		if other.index == a.index or other.state in ["seated", "departed"]:
			continue
		var offset: Vector3 = other.node.position - fan.position
		if offset.length() < 0.65 and offset.dot(direction) > 0.05:
			if fan.position.distance_to(goal) < 0.8:
				a.blocked = 0.0
				return true  # Shared aisle waypoint reached without stacking people at its center.
			blocked = true
			a.blocked += delta
			if a.blocked < 1:
				return false
			if a.blocked < 3:
				direction = (
					(direction + Vector3(-direction.z, 0, direction.x) * (0.6 if a.index % 2 == 0 else -0.6))
					. normalized()
				)
			break
	if not blocked:
		a.blocked = 0.0
	a.direction = direction
	fan.position += direction * minf(a.speed * delta, fan.position.distance_to(goal))
	fan.rotation.y = atan2(-direction.x, -direction.z)
	a.phase += delta * 7
	fan.get_node("LegLeft").rotation.x = sin(a.phase) * 0.35
	fan.get_node("LegRight").rotation.x = -sin(a.phase) * 0.35
	fan.get_node("LegLeft/Knee").rotation.x = -maxf(0, sin(a.phase)) * 0.5
	fan.get_node("LegRight/Knee").rotation.x = -maxf(0, -sin(a.phase)) * 0.5
	fan.get_node("ArmLeft").rotation.x = -sin(a.phase) * 0.22
	fan.get_node("ArmRight").rotation.x = sin(a.phase) * 0.22
	return false


func advance_routines(delta: float) -> void:
	ambient_time += delta
	for worker in workers:
		worker.get_node("ArmRight").rotation.x = 0.5 + sin(ambient_time * 2) * 0.2
	var final: bool = game.club.live.visit_time >= LiveMatchday.FINAL
	for a in agents:
		if a.state == "departed":
			continue
		if final and a.state not in ["exit", "exit_aisle", "leave_section", "return_concourse"]:
			a.wait = 0
			if a.state in ["seated", "find_seat"]:
				a.step = (
					a.seat_route.size() - 1 if a.state == "seated" else mini(a.step, a.seat_route.size() - 1)
				)
				a.state = "leave_section"
			elif a.node.position.z < 23 and absf(a.node.position.x) > 26:
				a.state = "return_concourse"
				a.step = mini(a.target, a.route.size() - 1)
			else:
				a.state = "exit" if a.node.position.z >= 25 else "exit_aisle"
		if a.state == "seated":
			a.timer += delta
			if a.last_inning != inning:
				a.last_inning = inning
				a.timer = 0
			if a.last_score != home_runs:
				a.last_score = home_runs
				a.cheer = 2.0
			a.cheer = maxf(0, a.cheer - delta)
			a.node.get_node("ArmLeft").rotation.x = (
				-1.8 + sin(ambient_time * 12) * 0.15 if a.cheer > 0 or a.timer < 1.4 else 0
			)
			a.node.get_node("ArmRight").rotation.x = (
				-1.8 - sin(ambient_time * 12) * 0.15 if a.cheer > 0 or a.timer < 1.4 else 0
			)
			a.node.get_node("Head").rotation.y = sin(ambient_time * 0.6 + a.index) * 0.12
			if a.timer > 18 + float(a.index % 5) * 3 and a.index % 3 == 0:
				a.state = "leave_section"
				a.step = a.seat_route.size() - 1
			continue
		if a.wait > 0:
			a.wait -= delta
			continue
		if a.state in ["arriving", "concourse", "queue"]:
			if walk_routine(a, a.route[a.target], delta):
				if a.target == a.route.size() - 1:
					a.state = "find_seat"
					a.step = 0
				else:
					var served: bool = a.target == int(a.node.get_meta("service_stop", -1))
					a.target += 1
					a.wait = (
						(2 if game.club.live.queue_relief() else 5) + float(a.index % 3) if served else 0.2
					)
					a.state = "queue" if served else "concourse"
					if served:
						a.node.rotation.y = game.club.world.wing_yaw(-1 if a.node.position.x < 0 else 1) + PI
		elif a.state == "find_seat":
			if walk_routine(a, a.seat_route[a.step], delta):
				a.step += 1
				if a.step >= a.seat_route.size():
					a.node.position = a.seat
					a.node.rotation.y = a.seat_yaw
					a.node.get_node("LegLeft").rotation.x = 1.4
					a.node.get_node("LegRight").rotation.x = 1.4
					a.node.get_node("LegLeft/Knee").rotation.x = -1.5
					a.node.get_node("LegRight/Knee").rotation.x = -1.5
					a.state = "seated"
					a.timer = 0
		elif a.state == "leave_section":
			if walk_routine(a, a.seat_route[a.step], delta):
				a.step -= 1
				if a.step < 0:
					a.state = "exit_aisle" if final else "concourse"
					a.target = 2
		elif a.state == "return_concourse":
			if walk_routine(a, a.route[a.step], delta):
				a.step -= 1
				if a.step < 2:
					a.state = "exit_aisle"
		elif a.state == "exit_aisle":
			var lane: float = -4.5 if a.node.position.x < 0 else 4.5
			if walk_routine(a, Vector3(lane, 0.05, 25), delta):
				a.state = "exit"
		elif a.state == "exit":
			var lane: float = -4.5 if a.node.position.x < 0 else 4.5
			if walk_routine(a, Vector3(lane, 0.05, 42), delta):
				a.state = "departed"
				a.node.visible = false


func dress(person_root: Node3D, team: String, number: int) -> void:
	var old := person_root.get_node_or_null("UniformDetails")
	if old != null:
		person_root.remove_child(old)
		old.queue_free()
	var details := Node3D.new()
	details.name = "UniformDetails"
	person_root.add_child(details)
	var home := team == "OWLS"
	var color: Color = Color("28585a") if home else TEAM_COLORS.get(team, Color("526873"))
	person_root.set_meta("team", team)
	(person_root.get_child(0) as MeshInstance3D).material_override = G.material(
		Color("e6ddc5") if home else color
	)
	person_root.get_node("Cap").material_override = G.material(color)
	person_root.get_node("Brim").material_override = G.material(color)
	var nameplate := G.label(
		details, "OWLS" if home else team.split(" ")[-1].to_upper(), Vector3(0, 1.18, -0.18), 24
	)
	nameplate.rotation.y = PI
	nameplate.pixel_size = 0.0028
	nameplate.modulate = color if home else Color("f2e5c9")
	var jersey := G.label(details, str(number), Vector3(0, 1.10, 0.18), 32)
	jersey.pixel_size = 0.005
	jersey.modulate = color if home else Color("f2e5c9")
	for side in [-1, 1]:
		G.box(
			details,
			Vector3(side * 0.18, 1.08, -0.15),
			Vector3(0.018, 0.43, 0.025),
			color if home else Color("d9cfbb")
		)
