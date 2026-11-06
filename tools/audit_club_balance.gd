extends SceneTree
# Deterministic progression audit, not a human playthrough. No files are written.
const ROUTES := {
	"tools_first":
	[
		"hose_nozzle",
		"wide_deck",
		"bleachers",
		"snack_shack",
		"grandstand",
		"wide_drag",
		"guide_wheel",
		"grill_stand",
		"scoreboard",
		"video_board"
	],
	"seats_first":
	[
		"bleachers",
		"snack_shack",
		"hose_nozzle",
		"wide_deck",
		"grandstand",
		"wide_drag",
		"guide_wheel",
		"grill_stand",
		"scoreboard",
		"video_board"
	],
	"nozzle_then_seats":
	[
		"hose_nozzle",
		"bleachers",
		"snack_shack",
		"wide_deck",
		"grandstand",
		"wide_drag",
		"guide_wheel",
		"grill_stand",
		"scoreboard",
		"video_board"
	]
}


class AuditCareer:
	extends CareerProfile

	# Exercise real v4 transactions without disk I/O; history remains an audit log.
	func commit(candidate: Dictionary) -> bool:
		assert(CareerState.validate(candidate))
		data = candidate.duplicate(true)
		rebuild()
		return true


func _initialize() -> void:
	for finish_quality in [1.0, 0.75]:
		for strategy in ROUTES:
			var career := AuditCareer.new()
			assert(career.start_club())
			print("ROUTE ", strategy, " finish quality ", finish_quality)
			for day in range(1, 19):
				var profile := GameDay.profile(day - 1)
				var shift := ShiftSession.new()
				shift.start(profile)
				shift.set_progress(shift.goals(), [true, true, true, true, true])
				shift.set_quality([1.0, finish_quality, finish_quality, finish_quality, 1.0])
				shift.advance(minf(1000, float(ShiftSession.PROFILES[profile].duration) - 1))
				var result := shift.get_result()
				assert(career.claim(shift.attempt_id, result).status == "awarded")
				assert(career.host_game(shift.attempt_id).status == "hosted")
				shift.free()
				for id in ROUTES[strategy]:
					if CareerProfile.UPGRADES.has(id):
						if career.owns(id):
							continue
						if career.purchase(id):
							print("  Date %d: %s, %d cr left" % [day, id, career.balance])
						break
					if id in career.club.buildings:
						continue
					if career.purchase_stadium(id):
						print("  Date %d: %s, %d cr left" % [day, id, career.balance])
					break
	quit()
