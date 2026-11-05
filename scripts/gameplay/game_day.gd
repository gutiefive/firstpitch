class_name GameDay
extends RefCounted
const TYPES := {
	"home_hot":
	{
		"title": "Hot afternoon",
		"brief":
		"Dry infield: water 90% of the missing moisture work. Keep the nozzle moving to avoid puddles.",
		"request": "Controlled watering",
		"job": 3,
		"quality": 0.95,
		"score": 85,
		"seconds": 1080,
		"bonus": 35
	},
	"home_rain":
	{
		"title": "Rain recovery",
		"brief":
		(
			"Standing water drains in about 12 game seconds. Let it drain before dragging; no "
			+ "watering is required."
		),
		"request": "Smooth rain recovery",
		"job": 1,
		"quality": 0.95,
		"score": 85,
		"seconds": 1080,
		"bonus": 40
	},
	"home_double":
	{
		"title": "Doubleheader turnaround",
		"brief":
		"Heavy wear and a 15-minute window. Repair the mound, restore chalk and turn the infield around.",
		"request": "Ready for the next first pitch",
		"job": 4,
		"quality": 1.0,
		"score": 90,
		"seconds": 720,
		"bonus": 50
	}
}


static func profile(index: int) -> String:
	if index == 0:
		return "home_game"
	return ["home_hot", "home_rain", "home_double"][posmod(index - 1, 3)]


static func info(profile_id: String) -> Dictionary:
	return TYPES.get(
		profile_id,
		{
			"title": "Mild game day",
			"brief": "Standard priority prep before the gates open.",
			"request": "Opening-day checklist",
			"bonus": 0
		}
	)


static func priority_met(result: Dictionary) -> bool:
	if not TYPES.has(result.get("profile_id")) or result.get("reason") != "completed":
		return false
	var rule: Dictionary = TYPES[result.profile_id]
	var qualities: Array = result.get("job_quality", [])
	return (
		qualities.size() == 5
		and float(qualities[rule.job]) >= rule.quality
		and float(result.score) >= rule.score
		and float(result.elapsed_seconds) <= rule.seconds
	)


static func bonus(result: Dictionary) -> int:
	return int(TYPES[result.profile_id].bonus) if priority_met(result) else 0


static func request_text(profile_id: String) -> String:
	if not TYPES.has(profile_id):
		return "Complete the standard checklist; manager bonuses begin with the next date."
	var rule: Dictionary = TYPES[profile_id]
	return (
		"%s: %s quality %d%%+, prep score %d+, finish within %d min · +%d cr when hosted"
		% [
			rule.request,
			ShiftSession.JOB_NAMES[rule.job],
			roundi(rule.quality * 100),
			rule.score,
			int(rule.seconds) / 60,
			rule.bonus
		]
	)


static func apply_conditions(game: Node, profile_id: String) -> void:
	if profile_id != "home_rain":
		return
	var values: PackedFloat32Array = game.moisture.snapshot_moisture()
	var timers := PackedFloat32Array()
	timers.resize(values.size())
	for i in game.infield.work_indices():
		values[i] = 0.98
		timers[i] = 12.0
	# Rain is starting field wear, not player overwatering. No penalty marks.
	game.moisture.replace_moisture(values, timers)


static func checklist(profile_id: String) -> String:
	var p: Dictionary = ShiftSession.PROFILES[profile_id]
	var parts := PackedStringArray()
	for i in CrewJob.ALL:
		if p.goals[i] > 0:
			parts.append("%s %d%%" % [ShiftSession.JOB_NAMES[i], p.goals[i]])
	return ", ".join(parts)


static func investment_text(career: CareerProfile) -> String:
	var lines := PackedStringArray()
	for id in ["hose_nozzle", "wide_deck", "guide_wheel", "wide_drag"]:
		if not career.owns(id):
			var tool: Dictionary = CareerProfile.UPGRADES[id]
			lines.append(
				(
					"Next tool: %s · %d / %d cr · %d cr to save%s"
					% [
						tool.title,
						mini(career.balance, tool.cost),
						tool.cost,
						maxi(0, tool.cost - career.balance),
						" · rank locked" if not career.upgrade_unlocked(id) else ""
					]
				)
			)
			break
	for id in ClubProgress.PROJECTS:
		if id not in career.club.buildings:
			var project: Dictionary = ClubProgress.PROJECTS[id]
			var needs := PackedStringArray()
			for dependency in project.requires:
				if dependency not in career.club.buildings:
					needs.append(ClubProgress.PROJECTS[dependency].title)
			lines.append(
				(
					"Next stadium: %s · %d / %d cr · fans %d / %d%s"
					% [
						project.title,
						mini(career.balance, project.cost),
						project.cost,
						career.club.fans,
						project.fans,
						" · needs " + ", ".join(needs) if not needs.is_empty() else ""
					]
				)
			)
			break
	return (
		"\n".join(lines)
		if not lines.is_empty()
		else "All current stadium and tool upgrades owned. Keep growing the club!"
	)


static func recap(career: CareerProfile) -> String:
	if career.club.last.is_empty():
		return ""
	var last_id := ""
	for event in career.data.club.events:
		if event.type == "game":
			last_id = event.id
	var result := {}
	for record in career.data.records:
		if record.id == last_id:
			result = record.result
			break
	var last: Dictionary = career.club.last
	var wage := CareerProfile.payout(result)
	var extra: int = last.get("priority_bonus", 0)
	var status := "No cash manager request on this date."
	if TYPES.has(result.profile_id):
		var rule: Dictionary = TYPES[result.profile_id]
		var quality: float = result.get("job_quality", [1, 1, 1, 1, 1])[rule.job]
		status = (
			"%s · %s\n%s quality %.0f%% / %d%% required · Score %.1f / %d · Time %s / %s"
			% [
				rule.request,
				"MET" if extra > 0 else "MISSED",
				ShiftSession.JOB_NAMES[rule.job],
				quality * 100,
				roundi(rule.quality * 100),
				result.score,
				rule.score,
				ShiftSession.clock_text(result.elapsed_seconds),
				ShiftSession.clock_text(rule.seconds)
			]
		)
	return (
		(
			"HOME DATE %d · %s\nPrep pay %d cr (already received) + gate profit %d cr + manager "
			+ "bonus %d cr = %d cr earned\nTickets %d + food %d − operating costs %d = %d cr gate "
			+ "profit\n%d / %d seats filled · supporters %d → %d (+%d)\n%s\nAvailable budget now: %d cr"
		)
		% [
			last.game,
			info(result.profile_id).title,
			wage,
			last.net,
			extra,
			wage + last.net + extra,
			last.ticket_income,
			last.food_income,
			last.costs,
			last.net,
			last.attendance,
			last.capacity,
			last.fans_before,
			last.fans_after,
			last.fans_gained,
			status,
			career.balance
		]
	)
