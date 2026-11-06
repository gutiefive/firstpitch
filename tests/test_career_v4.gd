extends SceneTree
var checks := 0
var failures := 0


class NoReplayCareer:
	extends CareerProfile
	var legacy_calls := 0

	func legacy_validate(value: Variant) -> bool:
		legacy_calls += 1
		return super.legacy_validate(value)

	func legacy_rebuild() -> void:
		legacy_calls += 1
		super.legacy_rebuild()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func normalized(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func run() -> void:
	var expected: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/career_legacy_expected.json")
	)
	var last_path := ""
	for version in [1, 2, 3]:
		var path := "user://migration-%d.dat" % version
		var fixture := "res://tests/fixtures/career_v%d.dat" % version
		var original := FileAccess.get_file_as_bytes(fixture)
		DirAccess.copy_absolute(fixture, path)
		var c := NoReplayCareer.new()
		c.path = path
		check(c.load_profile() and c.data.version == 4, "legacy v%d migrates once to v4" % version)
		check(
			FileAccess.get_file_as_bytes(path.get_basename() + ".v3.bak") == original,
			"original legacy bytes are retained independently of rolling backups"
		)
		check(c.legacy_calls == 1, "migration validates/replays the legacy stream only once")
		var old: Dictionary = expected[str(version)]
		check(
			c.balance == old.balance and c.earned == old.earned,
			"migrated wallet and lifetime earnings match pre-v4 fixture"
		)
		check(
			c.rank_title() == old.rank and c.completed == old.completed,
			"migrated rank inputs and completed count match"
		)
		check(
			normalized(c.data.upgrades) == old.upgrades and normalized(c.best) == old.best,
			"migrated upgrades and personal bests match"
		)
		check(
			normalized(c.club) == old.club,
			"all migrated club counters, receipts, pending and service state match old replay"
		)
		check(
			normalized(ClubOwnership.review(c)) == old.ownership,
			"frozen season closing state, goal, earnings and review exactly match legacy"
		)
		check(
			normalized(ClubSchedule.report(c)) == old.schedule,
			"season schedule and targets exactly match legacy"
		)
		var copy := NoReplayCareer.new()
		copy.path = path
		check(
			copy.load_profile() and copy.data == c.data and copy.legacy_calls == 0,
			"v4 reload reads state without legacy validation/replay"
		)
		var id: String = c.data.records[0].id
		var before := c.data.duplicate(true)
		check(
			c.claim(id, c.data.records[0].result).status == "recorded" and c.data == before,
			"migrated paid IDs cannot pay again"
		)
		if c.club.games > 0:
			check(
				c.host_game(c.latest_host_id()).status == "recorded" and c.data == before,
				"migrated hosted IDs cannot host again"
			)
		if version == 3:
			check(
				not c.claim_service(c.latest_host_id(), c.data.state.service_inputs[c.latest_host_id()]),
				"migrated service ID cannot claim again"
			)
			last_path = path
		# Model changed historical rules: this stored result no longer matches today's goal metadata.
		var historical := copy.data.duplicate(true)
		historical.records[0].result.goals[CrewJob.MOW] -= 1
		check(
			not CareerProfile.valid_result(historical.records[0].result) and copy.validate(historical),
			"historical result does not need to satisfy today's scoring rules"
		)
		var wallet := copy.balance
		var earnings := copy.earned
		check(
			(
				copy.commit(historical)
				and copy.balance == wallet
				and copy.earned == earnings
				and copy.legacy_calls == 0
			),
			"v4 commit never recomputes past wages or construction prices"
		)
		check(
			copy.load_profile() and copy.balance == wallet and copy.legacy_calls == 0,
			"rule-independent state survives another checked round trip"
		)
		var repriced := copy.data.duplicate(true)
		repriced.records[0].pay += 17
		repriced.state.earned += 17
		repriced.state.balance += 17
		var tool: String = repriced.upgrades[0]
		repriced.state.tool_costs[tool] += 11
		repriced.state.balance -= 11
		check(
			copy.commit(repriced) and copy.load_profile() and copy.balance == wallet + 6,
			"historical paid wages and tool prices can differ from current catalogs without repricing state"
		)
		check(
			copy.claim(id, copy.data.records[0].result).pay == repriced.records[0].pay,
			"duplicate claim reports its frozen historical pay"
		)
		var shift := ShiftSession.new()
		shift.start("mound_callout")
		shift.set_progress(shift.goals(), [true, true, true, true, true])
		shift.advance(0)
		check(
			(
				(
					copy.claim(shift.attempt_id, shift.get_result()).pay
					== CareerProfile.payout(shift.get_result())
				)
				and copy.legacy_calls == 0
			),
			"new work uses current rules while old transactions remain frozen"
		)
		shift.free()
		for key in ["balance", "earned"]:
			var bad := copy.data.duplicate(true)
			bad.state[key] = -1
			check(not copy.validate(bad), "negative authoritative currency is rejected")
		var bad := copy.data.duplicate(true)
		bad.records.append(bad.records[0].duplicate(true))
		check(not copy.validate(bad), "v4 duplicate attempt identities are rejected")
		bad = copy.data.duplicate(true)
		bad.upgrades.append("unknown_tool")
		check(not copy.validate(bad), "v4 unknown upgrade IDs are rejected")
		check(
			FileAccess.get_file_as_bytes(fixture) == original,
			"immutable migration fixture is never rewritten"
		)
	# A valid maximum-length old career must still migrate even if v4 grows beyond 4 MiB.
	var source := FileAccess.open("res://tests/fixtures/career_v3.dat", FileAccess.READ)
	source.seek(40)
	var seed: Dictionary = bytes_to_var(source.get_buffer(source.get_length() - 40))
	source.close()
	var legacy := {
		"version": 3,
		"records": [],
		"upgrades": PackedStringArray(),
		"club": {"record_start": 0, "tool_start": 0, "events": []}
	}
	for i in range(CareerProfile.MAX_RECORDS):
		var id := "%032x" % i
		legacy.records.append({"id": id, "result": seed.records[0].result.duplicate(true)})
		legacy.club.events.append({"type": "game", "id": id, "records": i + 1, "tools": 0})
		legacy.club.events.append(
			{
				"type": "service",
				"id": id,
				"records": i + 1,
				"tools": 0,
				"input":
				{
					"seconds": 60,
					"queue": 0,
					"completed":
					LegacyParkSatisfaction.opportunities({"games": i + 1, "buildings": PackedStringArray()}),
					"buildings": PackedStringArray()
				}
			}
		)
	var bytes := var_to_bytes(legacy)
	check(bytes.size() + 40 < 4 * 1024 * 1024, "maximum-length legacy fixture fits its original file limit")
	var file := FileAccess.open("user://maximum-career.dat", FileAccess.WRITE)
	file.store_buffer("FPCREW01".to_ascii_buffer())
	file.store_buffer(SaveRecovery.digest(bytes))
	file.store_buffer(bytes)
	file.close()
	var maximum := NoReplayCareer.new()
	maximum.path = "user://maximum-career.dat"
	check(
		(
			maximum.load_profile()
			and maximum.data.version == 4
			and maximum.data.records.size() == CareerProfile.MAX_RECORDS
			and maximum.legacy_calls == 1
		),
		"all 2,000 legacy attempts migrate in one replay without truncation"
	)
	check(
		var_to_bytes(maximum.data).size() > 4 * 1024 * 1024,
		"expanded v4 state exercises the increased non-gameplay file-size limit"
	)
	var maximum_wallet := maximum.balance
	check(
		maximum.load_profile() and maximum.balance == maximum_wallet and maximum.legacy_calls == 1,
		"large v4 state reloads without replay or changed credits"
	)
	print("MAXIMUM_CAREER_BYTES=", var_to_bytes(maximum.data).size())
	# Resume a paid frozen attempt using the real autosave restore/claim path.
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = last_path
	g.settings_save_path = "user://migration-resume-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	root.add_child(g)
	await process_frame
	var record: Dictionary = g.shift.career.data.records[-1]
	var session: ShiftSession = g.shift.session
	session.start(record.result.profile_id)
	session.attempt_id = record.id
	session.set_progress(record.result.values, record.result.met)
	session.elapsed_seconds = record.result.elapsed_seconds
	session.finish(record.result.reason)
	var captured: Dictionary = g.autosave.store.capture(g, session)
	g.autosave.candidate = captured.duplicate(true)
	var before: Dictionary = g.shift.career.data.duplicate(true)
	check(g.autosave.paid(record.id), "autosave recognizes migrated paid IDs")
	check(
		g.autosave.resume() and g.shift.career.data == before,
		"autosave resume cannot repay a migrated attempt"
	)
	g.autosave.candidate = captured.duplicate(true)
	check(
		g.autosave.resume() and g.shift.career.data == before,
		"repeated autosave resume retains once-only payouts"
	)
	paused = false
	g.queue_free()
	await process_frame
	print("Career v4: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
