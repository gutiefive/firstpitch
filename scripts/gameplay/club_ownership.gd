class_name ClubOwnership
extends RefCounted
# Version-one objective order is fixed so later project catalogs cannot retarget history.
const OBJECTIVE_PROJECTS := [
	"bleachers", "snack_shack", "grandstand", "grill_stand", "scoreboard", "video_board"
]


static func closing_state(career: CareerProfile, season: int) -> Dictionary:
	if career.data.version == 4:
		return career.data.state.seasons[str(season)].club.duplicate(true)
	var games := 0
	for i in range(career.data.club.events.size()):
		var event: Dictionary = career.data.club.events[i]
		if event.type == "game":
			games += 1
			if games == season * 6:
				return ClubProgress.legacy_replay(
					{
						"record_start": career.data.club.record_start,
						"tool_start": career.data.club.tool_start,
						"events": career.data.club.events.slice(0, i + 1)
					},
					career.data.records.slice(0, event.records),
					career.data.upgrades.slice(0, event.tools)
				)
	return {}


static func objective(state: Dictionary, tools: PackedStringArray) -> Dictionary:
	var goal := {"fans": mini(10000, int(state.fans) + 80), "project": "", "tool": "", "targets": 0}
	for id in OBJECTIVE_PROJECTS:
		if id not in state.buildings:
			goal.project = id
			return goal
	for id in ["hose_nozzle", "wide_deck", "guide_wheel", "wide_drag"]:
		if id not in tools:
			goal.tool = id
			return goal
	goal.targets = 4
	return goal


static func tool_prefix(career: CareerProfile, season: int) -> PackedStringArray:
	if career.data.version == 4:
		return career.data.state.seasons[str(season)].tools.duplicate()
	var games := 0
	for event in career.data.club.events:
		if event.type == "game":
			games += 1
			if games == season * 6:
				return career.data.upgrades.slice(0, event.tools)
	return PackedStringArray()


static func met(goal: Dictionary, state: Dictionary, tools: PackedStringArray, targets: int) -> bool:
	return (
		state.fans >= goal.fans
		and (goal.project.is_empty() or goal.project in state.buildings)
		and (goal.tool.is_empty() or goal.tool in tools)
		and targets >= goal.targets
	)


static func goal_text(goal: Dictionary) -> String:
	var text := "Reach %d supporters" % goal.fans
	if not goal.project.is_empty():
		text += " and open " + String(ClubProgress.PROJECTS[goal.project].title)
	elif not goal.tool.is_empty():
		text += " and buy " + String(CareerProfile.UPGRADES[goal.tool].title)
	else:
		text += " and meet %d manager targets" % goal.targets
	return text + " by the next home finale."


static func review(career: CareerProfile) -> Dictionary:
	if not career.club_started() or career.club.games < 6:
		return {}
	var season := int(career.club.games) / 6
	var end := closing_state(career, season)
	var tools := tool_prefix(career, season)
	var receipts: Array = []
	var results: Array = []
	var by_id := {}
	for record in career.data.records:
		by_id[record.id] = record.result
	var played_ids := career.host_ids()
	for id in played_ids:
		receipts.append(career.club.hosted[id])
		results.append(by_id[id])
	var start := (season - 1) * 6
	var pay := 0
	var gate := 0
	var bonus := 0
	var targets := 0
	var score := 0.0
	for i in range(start, start + 6):
		pay += career.recorded_pay(played_ids[i])
		gate += int(receipts[i].net)
		bonus += int(receipts[i].get("priority_bonus", 0))
		targets += int(career.target_met(played_ids[i], i, results[i]))
		score += float(results[i].score)
	var goal := career.saved_objective(season) if career.data.version == 4 else objective(end, tools)
	var current_targets := 0
	for i in range(season * 6, receipts.size()):
		current_targets += int(career.target_met(played_ids[i], i, results[i]))
	var previous := ""
	if season > 1:
		var prior := closing_state(career, season - 1)
		var old_goal := (
			career.saved_objective(season - 1)
			if career.data.version == 4
			else objective(prior, tool_prefix(career, season - 1))
		)
		previous = (
			"Previous ownership objective: "
			+ ("MET" if met(old_goal, end, tools, targets) else "MISSED")
			+ ".\n"
		)
	var achieved := met(goal, career.club, career.data.upgrades, current_targets)
	var verdict := "A dependable home club" if targets >= 4 else "Roots worth building on"
	var voice := (
		"Mara: The town can count on this crew. Let's turn that trust into the next improvement."
		if targets >= 4
		else "Mara: We kept the gates open. Next season, let's make the priority work more consistent."
	)
	var progress := "Fans %d / %d" % [career.club.fans, goal.fans]
	if not goal.project.is_empty():
		progress += (
			" · " + ("project open" if goal.project in career.club.buildings else "project still needed")
		)
	elif not goal.tool.is_empty():
		progress += " · " + ("tool owned" if goal.tool in career.data.upgrades else "tool still needed")
	else:
		progress += " · manager targets %d / %d" % [current_targets, goal.targets]
	var text := (
		(
			"MARA'S OWNERSHIP REVIEW · SEASON %d\n%s · %d / 6 targets · %.1f average "
			+ "score\nSupporters %d → %d · %d seats at the finale\nSeason earnings: prep %d + gate %d "
			+ "+ manager bonuses %d = %d cr\n%s\n%sSeason %d objective: %s\n%s · %s"
		)
		% [
			season,
			verdict,
			targets,
			score / 6,
			receipts[start].fans_before,
			end.fans,
			end.capacity,
			pay,
			gate,
			bonus,
			pay + gate + bonus,
			voice,
			previous,
			season + 1,
			goal_text(goal),
			progress,
			"READY FOR THE FINALE" if achieved else "IN PROGRESS"
		]
	)
	return {
		"season": season,
		"targets": targets,
		"fans": end.fans,
		"capacity": end.capacity,
		"earnings": pay + gate + bonus,
		"objective": goal,
		"achieved": achieved,
		"text": text,
		"previous": previous
	}
