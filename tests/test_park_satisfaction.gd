extends "res://tests/test_live_matchday.gd"


func finish_basic_jobs(g: Node) -> void:
	var live: LiveMatchday = g.club.live
	g.player.velocity = Vector3.ZERO
	g.player.position = live.jobs[0].point
	Input.action_press("interact")
	live.advance_jobs(2.1)
	Input.action_release("interact")
	g.player.position = live.jobs[1].point
	live.interact_job()
	g.player.position = live.jobs[1].point
	for i in range(160):
		live.advance_jobs(0.05)
	for job in live.jobs:
		if job.id == "lost":
			g.player.position = job.point
			live.interact_job()


func run() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://park-satisfaction-career.dat"
	g.settings_save_path = "user://park-satisfaction-settings.cfg"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	await idle(12)
	var c: CareerProfile = g.shift.career
	var live: LiveMatchday = g.club.live
	var park: MatchdayPark = g.club.matchday
	var show: OpeningGates = g.club.opening
	var atmosphere: MatchdayAtmosphere = g.club.atmosphere
	live.set_process(false)
	park.set_process(false)
	show.set_process(false)
	check(not c.claim_service("", {}), "unhosted careers cannot claim satisfaction income")
	g.club.join()
	prep(g)
	show.finish()
	var first_id := c.latest_host_id()
	var old_receipt: Dictionary = c.club.last.duplicate(true)
	var old_balance := c.balance
	var old_fans: int = c.club.fans
	var before_crowd: int = ClubProgress.forecast(c.club, c.data.records[0].result).attendance
	live.start()
	live._process(31)
	check(
		live.on_foot_time >= 30 and not live.event_spawned,
		"on-foot time accrues without spawning events early"
	)
	live.visit_time = 131
	live._process(0)
	check(
		live.event_spawned and live.jobs[-1].id == "lost",
		"starter fixture introduces a visiting-family event"
	)
	var count := live.jobs.size()
	live._process(0)
	check(live.jobs.size() == count, "event appears only once per visit")
	finish_basic_jobs(g)
	check(live.completed_jobs().size() == 3, "cleanup, escort and visiting-family help can all complete")
	var clean := {
		"seconds": 31,
		"queue": 0,
		"completed": live.completed_jobs(),
		"buildings": c.club.buildings.duplicate()
	}
	var report := ParkSatisfaction.evaluate(c.club, clean)
	var delayed := clean.duplicate(true)
	delayed.queue = 31
	check(
		ParkSatisfaction.evaluate(c.club, delayed).rating < report.rating,
		"queue pressure visibly lowers fan satisfaction"
	)
	var partial := clean.duplicate(true)
	partial.completed = PackedStringArray()
	check(
		ParkSatisfaction.evaluate(c.club, partial).rating < report.rating,
		"completed service work improves rating"
	)
	var worn: Dictionary = c.club.duplicate(true)
	worn.last.score = 50.0
	check(
		ParkSatisfaction.evaluate(worn, clean).rating < report.rating,
		"frozen prep quality affects park rating"
	)
	live.visit_time = LiveMatchday.FINAL + 1
	live._process(0)
	live.show_broadcast()
	await pad(JOY_BUTTON_A)
	check(
		c.data.version == 2, "ordinary hosting retains legacy career format until service reward is claimed"
	)
	check(
		not live.service_report().is_empty() and c.balance == old_balance,
		"eligible visit offers a review without automatically paying it"
	)
	check(
		(
			not g.shift.overlay.club_panel.claim_button.disabled
			and g.shift.overlay.club_panel.claim_button.has_focus()
		),
		"park review provides focused explicit claim action"
	)
	await idle(6)
	check(
		g.shift.overlay.club_screen.get_global_rect().has_point(
			g.shift.overlay.club_panel.claim_button.get_global_rect().get_center()
		),
		"reward action scrolls into view after the results layout settles"
	)
	await capture("satisfaction-preview")
	var expected: Dictionary = live.service_report().duplicate(true)
	await click(g.shift.overlay.club_panel.claim_button)
	check(
		c.balance == old_balance + int(expected.bonus) and c.club.fans == old_fans + int(expected.fans),
		"claim pays exactly the displayed modest credits and supporters"
	)
	check(
		c.club.last == old_receipt and c.data.records.size() == 1,
		"service reward never rewrites gate receipt or prep wages"
	)
	check(c.data.version == 3, "first service claim explicitly migrates career to version three")
	check(
		c.club.services.has(first_id) and g.shift.overlay.club_panel.claim_button.disabled,
		"claimed reward is recorded and disabled"
	)
	check(
		not c.claim_service(first_id, clean) and not live.claim_bonus(),
		"replays and repeated claims cannot pay the date again"
	)
	check(
		ClubProgress.forecast(c.club, c.data.records[0].result).attendance > before_crowd,
		"repeat supporters increase future attendance demand"
	)
	var saved_report: Dictionary = c.club.services[first_id].duplicate(true)
	var reload := CareerProfile.new()
	reload.path = c.path
	check(
		reload.load_profile() and reload.balance == c.balance and reload.club.services == c.club.services,
		"reload reproduces exact satisfaction rewards and budget"
	)
	var old_version: Dictionary = c.data.duplicate(true)
	old_version.version = 2
	check(not c.validate(old_version), "service events cannot be disguised as legacy version-two data")
	var bad: Dictionary = c.data.duplicate(true)
	bad.club.events.append(bad.club.events[-1].duplicate(true))
	check(not c.validate(bad), "duplicate service ledger events are rejected")
	bad = c.data.duplicate(true)
	bad.club.events[-1].input.completed.append("made_up_job")
	check(not c.validate(bad), "unknown completion IDs are rejected")
	bad = c.data.duplicate(true)
	bad.club.events[-1].input.buildings.append("video_board")
	check(not c.validate(bad), "review cannot claim facilities not owned during its ledger history")
	bad = c.data.duplicate(true)
	bad.club.events[-1].input.seconds = 29
	check(not c.validate(bad), "insufficient on-foot service time is rejected")
	bad = c.data.duplicate(true)
	bad.club.events[-1].input.queue = -1
	check(not c.validate(bad), "negative queue metrics are rejected")
	bad = c.data.duplicate(true)
	bad.club.events[-1].input.bonus = 99999
	check(not c.validate(bad), "stored input cannot inject arbitrary bonus amounts")
	prep(g)
	show.finish()
	live.start()
	live._process(31)
	live.visit_time = LiveMatchday.FINAL + 1
	live._process(0)
	live.end_visit()
	var before_facilities: Dictionary = live.service_report().duplicate(true)
	check(g.club.build("snack_shack"), "service income remains compatible with real stadium purchases")
	check(
		live.service_report() == before_facilities,
		"buying facilities after a visit cannot rewrite its pending review"
	)
	check(
		c.club.services[first_id] == saved_report,
		"later facilities cannot rewrite an earlier satisfaction report"
	)
	prep(g)
	check(
		c.club.games == 3 and atmosphere.evening and atmosphere.lights.visible,
		"rivalry-night fixture activates evening sky and floodlights"
	)
	var original_env: Environment = atmosphere.original.env
	show.elapsed = 13
	show.update_view(13.0 / 47)
	check(atmosphere.caption.contains("First pitch"), "PA announces game start with a caption")
	show.elapsed = 25
	show.update_view(25.0 / 47)
	check(atmosphere.caption.contains("Owls score"), "PA reacts to a home scoring play")
	check(atmosphere.pa.bus == "GroundsAmbience", "PA respects the existing ambience volume bus")
	await capture("satisfaction-evening")
	show.walk_park()
	live._process(0)
	check(live.jobs[-1].id == "litter", "third home date rotates into litter event")
	var litter: Dictionary = live.jobs[-1]
	g.player.position = litter.point
	g.player.velocity = Vector3.ZERO
	Input.action_press("interact")
	live.advance_jobs(3.1)
	Input.action_release("interact")
	check(litter.state == "done", "litter buildup has real held cleanup work")
	for i in range(1200):
		park.advance_routines(0.1)
	var close_camera := Camera3D.new()
	g.add_child(close_camera)
	close_camera.position = Vector3(-14, 2.8, 6)
	close_camera.look_at(Vector3(-7, 1.1, 10))
	close_camera.current = true
	live.hud.visible = false
	await capture("satisfaction-fans")
	close_camera.queue_free()
	g.camera.current = true
	live.hud.visible = true
	live.end_visit()
	check(
		(
			not atmosphere.active
			and not atmosphere.lights.visible
			and atmosphere.world.environment == original_env
		),
		"ending night visit restores the original environment"
	)
	prep(g)
	show.finish()
	live.start()
	live._process(131)
	check(live.jobs[-1].id == "rush", "built concession enables a rotating rush event")
	var rush: Dictionary = live.jobs[-1]
	g.player.position = rush.point
	g.player.velocity = Vector3.ZERO
	Input.action_press("interact")
	live.advance_jobs(3.1)
	Input.action_release("interact")
	var customer := {}
	for fan in park.agents:
		if fan.route.size() > 8:
			customer = fan
			break
	var relieved_wait := 1.0
	var normal_wait := 0.0
	if not customer.is_empty():
		customer.state = "concourse"
		customer.target = int(customer.node.get_meta("service_stop"))
		customer.wait = 0
		customer.node.position = customer.route[int(customer.node.get_meta("service_stop"))]
		park.advance_routines(0.1)
		relieved_wait = customer.wait
		rush.state = "available"
		customer.state = "concourse"
		customer.target = int(customer.node.get_meta("service_stop"))
		customer.wait = 0
		park.advance_routines(0.1)
		normal_wait = customer.wait
		rush.state = "done"
	check(
		rush.state == "done" and live.queue_relief() and relieved_wait < normal_wait,
		"serving the rush actually shortens customer service waits"
	)
	live.refresh_hud()
	await capture("satisfaction-rush")
	live.end_visit()
	var fund := ShiftSession.new()
	fund.start("full")
	fund.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
	fund.advance(1)
	c.claim(fund.attempt_id, fund.get_result())
	fund.free()
	check(
		g.club.build("scoreboard"), "later park improvements remain affordable with ledger-funded side work"
	)
	g.club.world.signature = ""
	g.club.sync()
	await idle(4)
	park.set_time(25)
	check(
		park.scoreboards.size() == 1 and park.scoreboards[0].text.contains("INNING 5"),
		"stadium rebuilds refresh live scoreboard references"
	)
	var failed := CareerProfile.new()
	failed.data = c.data.duplicate(true)
	failed.data.club.events = failed.data.club.events.filter(func(event): return event.type != "service")
	failed.data.version = 2
	failed.rebuild()
	failed.path = "user://missing-service-directory/career.dat"
	var before := failed.data.duplicate(true)
	var budget := failed.balance
	var input := {
		"seconds": 60,
		"queue": 0,
		"completed": PackedStringArray(["rush"]),
		"buildings": failed.club.buildings.duplicate()
	}
	var wrong_context := input.duplicate(true)
	wrong_context.buildings = PackedStringArray()
	check(
		ParkSatisfaction.evaluate(failed.club, wrong_context).is_empty(),
		"review cannot omit facilities already open when the game was hosted"
	)
	check(
		(
			not failed.claim_service(failed.latest_host_id(), input)
			and failed.data == before
			and failed.balance == budget
		),
		"failed service save rolls back reward and version migration"
	)
	failed.path = "user://service-retry-career.dat"
	check(failed.claim_service(failed.latest_host_id(), input), "failed save can retry the original reward")
	check(not failed.claim_service(failed.latest_host_id(), input), "successful retry remains once-only")
	check(
		(
			ParkSatisfaction.event_for(1, PackedStringArray(["snack_shack"])) == "rush"
			and ParkSatisfaction.event_for(2, PackedStringArray()) == "lost"
			and ParkSatisfaction.event_for(3, PackedStringArray()) == "litter"
		),
		"event rotation is stable across reloads and park configurations"
	)
	g.queue_free()
	await idle(4)
	for path in [
		"user://park-satisfaction-career.dat",
		"user://park-satisfaction-settings.cfg",
		"user://service-retry-career.dat"
	]:
		DirAccess.remove_absolute(path)
	print("Park satisfaction: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
