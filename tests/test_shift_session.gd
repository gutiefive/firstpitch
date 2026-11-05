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
	var session := ShiftSession.new()
	root.add_child(session)
	var events := [0]
	session.finished.connect(func(_result: Dictionary): events[0] += 1)
	session.advance(100)
	check(
		session.phase == ShiftSession.Phase.PRACTICE and session.elapsed_seconds == 0,
		"free practice has no running timer"
	)
	check(
		not session.start("unknown") and session.phase == ShiftSession.Phase.PRACTICE,
		"unknown shift cannot start"
	)
	check(
		session.start("training") and session.remaining_seconds == 900, "training starts with fifteen minutes"
	)
	check(session.goals() == [25.0, 50.0, 50.0, 50.0, 100.0], "training has explicit smaller quotas")
	check(
		not session.start("full") and session.profile_id == "training",
		"active shift cannot be silently replaced"
	)
	check(not session.set_progress([0], [false]), "malformed task lists are rejected")
	check(
		not session.set_progress([NAN, 0, 0, 0, 0], [false, false, false, false, false]),
		"non-finite progress cannot corrupt score"
	)
	session.set_progress([12.5, 0, 0, 0, 0], [false, false, false, false, false])
	check(
		session.score() == 10 and session.jobs_completed() == 0, "half of one training quota earns ten points"
	)
	session.set_progress([12.5, 0, 0, 0, 0], [false, false, false, false, false])
	check(session.score() == 10, "repeated progress updates do not add points")
	session.advance(-1)
	session.advance(NAN)
	check(session.elapsed_seconds == 0, "invalid elapsed time is ignored")
	session.set_progress([25, 50, 50, 50, 100], [false, false, false, false, true])
	session.advance(1)
	check(
		session.phase == ShiftSession.Phase.FINISHED and session.jobs_completed() == 5,
		"all training quotas complete the shift"
	)
	var result := session.get_result()
	check(
		result["reason"] == "completed" and result["score"] == 100,
		"training completion earns a complete work score"
	)
	result["values"][0] = 0
	check(session.get_result()["values"][0] == 25, "result copies cannot mutate stored outcome")
	session.set_progress([0, 0, 0, 0, 0], [false, false, false, false, false])
	session.advance(100)
	check(
		session.get_result()["score"] == 100 and session.get_result()["elapsed_seconds"] == 1,
		"later practice cannot rewrite frozen result or clock"
	)
	check(
		session.start("full") and session.remaining_seconds == 1800 and session.get_result().is_empty(),
		"fresh full shift clears prior result and grants thirty minutes"
	)
	session.set_progress([100, 100, 100, 100, 100], [false, false, false, false, false])
	session.advance(1)
	check(
		session.phase == ShiftSession.Phase.ACTIVE and session.jobs_completed() == 0,
		"rounded percentages cannot replace exact full-task flags"
	)
	check(session.score() == 99.9, "incomplete full work cannot display a perfect score")
	session.set_progress([99.999, 100, 100, 100, 100], [true, true, true, true, true])
	session.advance(0)
	check(
		session.phase == ShiftSession.Phase.ACTIVE, "completion flags also require full measured percentages"
	)
	session.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
	session.advance(session.remaining_seconds)
	check(
		session.get_result()["reason"] == "completed" and session.remaining_seconds == 0,
		"completion on the deadline frame wins over timeout"
	)
	check(not session.end_early() and events[0] == 2, "finished shifts cannot publish duplicate results")
	session.start("training")
	session.set_progress([25, 0, 0, 0, 0], [false, false, false, false, false])
	session.advance(1000)
	result = session.get_result()
	check(
		result["reason"] == "time_up" and result["score"] == 20 and result["jobs_completed"] == 1,
		"timeout preserves honest partial work"
	)
	check(
		result["elapsed_seconds"] == 900 and result["remaining_seconds"] == 0,
		"deadline clamps elapsed and remaining time"
	)
	session.start("full")
	session.set_progress([10, 20, 30, 40, 50], [false, false, false, false, false])
	session.advance(10)
	check(session.end_early(), "active shift can be ended explicitly")
	result = session.get_result()
	check(
		result["reason"] == "ended_early" and result["score"] == 30 and result["remaining_seconds"] == 1790,
		"early finish snapshots work and time correctly"
	)
	check(
		(
			ShiftSession.clock_text(0) == "00:00"
			and ShiftSession.clock_text(61) == "01:01"
			and ShiftSession.clock_text(59.1) == "01:00"
		),
		"countdown text handles minute boundaries"
	)
	print("Shift session failures: ", failures)
	quit(1 if failures else 0)
