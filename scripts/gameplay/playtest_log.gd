class_name PlaytestLog
extends RefCounted
const HEADER := [
	"timestamp_utc",
	"profile_id",
	"end_reason",
	"elapsed_seconds",
	"mow_goal_seconds",
	"drag_goal_seconds",
	"chalk_goal_seconds",
	"water_goal_seconds",
	"mound_goal_seconds",
	"final_score",
	"payout",
	"attempt_id"
]
var enabled := "--playtest-log" in OS.get_cmdline_user_args()
var path := "user://playtest-log.csv"
var error := ""
var attempt_id := ""
var goal_times := PackedFloat64Array([-1, -1, -1, -1, -1])
var unknown := {}
var written := {}
var loaded_path := ""


func observe(session: ShiftSession) -> void:
	if not enabled or session.phase == ShiftSession.Phase.PRACTICE or session.attempt_id.is_empty():
		return
	if attempt_id != session.attempt_id:
		attempt_id = session.attempt_id
		goal_times = PackedFloat64Array([-1, -1, -1, -1, -1])
		unknown.clear()
		# Do not invent times for goals already met when logging starts or an attempt resumes.
		if session.elapsed_seconds > 0:
			for job in CrewJob.ALL:
				if session.goal_met(job):
					unknown[job] = true
	for job in CrewJob.ALL:
		if (
			session.goals()[job] > 0
			and session.goal_met(job)
			and goal_times[job] < 0
			and not unknown.has(job)
		):
			goal_times[job] = session.elapsed_seconds


func load_written() -> bool:
	if loaded_path == path:
		return true
	written.clear()
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			error = "Playtest log could not be read."
			return false
		if Array(file.get_csv_line()) != HEADER:
			file.close()
			error = "Playtest log columns differ. Existing file kept."
			return false
		while not file.eof_reached():
			var row := file.get_csv_line()
			if row.size() == HEADER.size() and CareerProfile.valid_id(row[-1]):
				written[row[-1]] = true
		file.close()
	loaded_path = path
	return true


func record(session: ShiftSession, payout: int) -> bool:
	if not enabled:
		return true
	error = ""
	if session.phase != ShiftSession.Phase.FINISHED:
		return false
	observe(session)
	if not load_written():
		return false
	if written.has(session.attempt_id):
		return true
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		error = "Playtest log could not be appended."
		return false
	if exists:
		file.seek_end()
	else:
		file.store_csv_line(PackedStringArray(HEADER))
	var result := session.get_result()
	var row := PackedStringArray(
		[
			Time.get_datetime_string_from_system(true) + "Z",
			session.profile_id,
			result.reason,
			str(result.elapsed_seconds)
		]
	)
	for job in CrewJob.ALL:
		row.append(str(goal_times[job]) if goal_times[job] >= 0 else "")
	row.append(str(result.score))
	row.append(str(payout))
	row.append(session.attempt_id)
	file.store_csv_line(row)
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if ok:
		written[session.attempt_id] = true
	else:
		error = "Playtest log write failed."
	return ok
