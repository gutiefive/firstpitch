class_name CareerState
extends RefCounted
const MAX_MONEY := 1_000_000_000_000
const CLUB_KEYS := [
	"active",
	"fans",
	"capacity",
	"games",
	"income",
	"spent",
	"buildings",
	"hosted",
	"last",
	"pending",
	"record_start",
	"services",
	"host_buildings"
]
const REPORT_KEYS := [
	"rating",
	"stars",
	"bonus",
	"fans",
	"field",
	"comfort",
	"amenities",
	"service",
	"queue_penalty",
	"completed",
	"opportunities"
]


static func integer(value: Variant, minimum: int = 0, maximum: int = MAX_MONEY) -> bool:
	return typeof(value) == TYPE_INT and value >= minimum and value <= maximum


static func number(value: Variant, minimum: float = 0, maximum: float = MAX_MONEY) -> bool:
	return (
		typeof(value) in [TYPE_INT, TYPE_FLOAT]
		and is_finite(float(value))
		and value >= minimum
		and value <= maximum
	)


static func ids(value: Variant, allowed: Array) -> bool:
	if not value is PackedStringArray:
		return false
	var seen := {}
	for id in value:
		if id not in allowed or seen.has(id):
			return false
		seen[id] = true
	return true


static func historical_result(value: Variant) -> bool:
	if (
		not value is Dictionary
		or not value.has_all(
			[
				"profile_id",
				"title",
				"reason",
				"score",
				"jobs_completed",
				"values",
				"goals",
				"met",
				"elapsed_seconds",
				"remaining_seconds",
				"duration_seconds"
			]
		)
	):
		return false
	if (
		value.profile_id not in ShiftSession.PROFILES
		or not value.title is String
		or value.reason not in ["completed", "time_up", "ended_early"]
		or not number(value.score, 0, 100)
		or not integer(value.jobs_completed, 0, 5)
	):
		return false
	for key in ["elapsed_seconds", "remaining_seconds", "duration_seconds"]:
		if not number(value[key], 0, 10_000_000):
			return false
	for key in ["values", "goals", "met"]:
		if not value[key] is Array or value[key].size() != CrewJob.ALL.size():
			return false
	for job in CrewJob.ALL:
		if (
			not number(value.values[job], 0, 100)
			or not number(value.goals[job], 0, 100)
			or not value.met[job] is bool
		):
			return false
	if value.has("quality"):
		if (
			not value.has_all(["coverage_score", "job_quality", "mowing_bonus", "quality_tip"])
			or not value.job_quality is Array
			or value.job_quality.size() != 5
			or not value.quality_tip is String
		):
			return false
		for quality in value.job_quality:
			if not number(quality, 0, 1):
				return false
		if (
			not number(value.quality, 0, 1)
			or not number(value.coverage_score, 0, 100)
			or not number(value.mowing_bonus, 0, 100)
		):
			return false
	return true


static func receipt(value: Variant) -> bool:
	if (
		not value is Dictionary
		or not value.has_all(
			[
				"game",
				"score",
				"attendance",
				"capacity",
				"fans_before",
				"fans_gained",
				"fans_after",
				"ticket_income",
				"food_income",
				"costs",
				"net"
			]
		)
	):
		return false
	for key in value:
		if key == "score":
			if not number(value[key], 0, 100):
				return false
		elif not integer(value[key]):
			return false
	return value.game > 0 and value.capacity > 0 and value.attendance <= value.capacity


static func service_input(value: Variant, buildings: PackedStringArray) -> bool:
	return (
		value is Dictionary
		and value.size() == 4
		and value.has_all(["seconds", "queue", "completed", "buildings"])
		and integer(value.seconds, 30, 3600)
		and integer(value.queue, 0, value.seconds)
		and ids(value.completed, ["spill", "eli", "supply", "litter", "rush", "lost"])
		and ids(value.buildings, Array(buildings))
	)


static func report(value: Variant) -> bool:
	if not value is Dictionary or not value.has_all(REPORT_KEYS):
		return false
	for key in REPORT_KEYS:
		if not integer(value[key]):
			return false
	return value.rating <= 100 and value.stars <= 5 and value.fans <= 10000


static func goal(value: Variant) -> bool:
	return (
		value is Dictionary
		and value.has_all(["fans", "project", "tool", "targets"])
		and integer(value.fans, 0, 10000)
		and (value.project == "" or value.project in ClubProgress.PROJECTS)
		and (value.tool == "" or value.tool in CareerProfile.UPGRADES)
		and integer(value.targets, 0, 6)
	)


static func snapshot(club: Dictionary, tools: PackedStringArray) -> Dictionary:
	var closing := {}
	for key in [
		"active",
		"fans",
		"capacity",
		"games",
		"income",
		"spent",
		"buildings",
		"pending",
		"record_start",
		"host_buildings"
	]:
		closing[key] = club[key].duplicate() if club[key] is PackedStringArray else club[key]
	return {"club": closing, "tools": tools.duplicate(), "objective": ClubOwnership.objective(club, tools)}


static func from_legacy(value: Dictionary, context: Dictionary = {}) -> Dictionary:
	# Called only after the unchanged legacy validator/replay has accepted the complete ledger.
	if context.is_empty():
		var validator := CareerProfile.new()
		if not validator.legacy_validate(value):
			return {}
		context = validator.legacy_context
	var migrated := {
		"version": 4,
		"records": value.records.duplicate(true),
		"upgrades": value.upgrades.duplicate(),
		"club": value.get("club", {"record_start": 0, "tool_start": 0, "events": []}).duplicate(true)
	}
	var state := {
		"balance": context.balance,
		"earned": context.earned,
		"completed": context.completed,
		"best": context.best.duplicate(true),
		"club": context.club.duplicate(true),
		"host_order": PackedStringArray(),
		"pending_ids": PackedStringArray(),
		"targets": {},
		"service_inputs": {},
		"seasons": {},
		"tool_costs": {},
		"project_costs": {}
	}
	var by_id := {}
	for record in migrated.records:
		record.pay = LegacyCareerRules.payout(record.result)
		by_id[record.id] = record.result
	for id in migrated.upgrades:
		state.tool_costs[id] = int(LegacyCareerRules.UPGRADES[id].cost)
	for id in context.club.buildings:
		state.project_costs[id] = int(LegacyCareerRules.PROJECTS[id].cost)
	for event in migrated.club.events:
		if event.type == "game":
			state.targets[event.id] = LegacyCareerRules.target_met(state.host_order.size(), by_id[event.id])
			state.host_order.append(event.id)
		elif event.type == "service":
			state.service_inputs[event.id] = event.input.duplicate(true)
	if value.version in [2, 3]:
		for i in range(int(context.club.record_start), migrated.records.size()):
			var record: Dictionary = migrated.records[i]
			if ClubProgress.eligible(record.result) and not context.club.hosted.has(record.id):
				state.pending_ids.append(record.id)
	state.seasons = context.seasons.duplicate(true)
	migrated.state = state
	return migrated


static func validate(value: Variant) -> bool:
	if (
		not value is Dictionary
		or value.get("version") != 4
		or typeof(value.version) != TYPE_INT
		or not value.has_all(["records", "upgrades", "club", "state"])
	):
		return false
	if (
		not value.records is Array
		or value.records.size() > CareerProfile.MAX_RECORDS
		or not ids(value.upgrades, CareerProfile.UPGRADES.keys())
	):
		return false
	var attempts := {}
	for i in range(value.records.size()):
		var record: Variant = value.records[i]
		if (
			not record is Dictionary
			or not record.has_all(["id", "result", "pay"])
			or not CareerProfile.valid_id(record.id)
			or attempts.has(record.id)
			or not integer(record.pay)
			or not historical_result(record.result)
		):
			return false
		attempts[record.id] = i
	var state: Variant = value.state
	if (
		not state is Dictionary
		or not state.has_all(
			[
				"balance",
				"earned",
				"completed",
				"best",
				"club",
				"host_order",
				"pending_ids",
				"targets",
				"service_inputs",
				"seasons",
				"tool_costs",
				"project_costs"
			]
		)
	):
		return false
	if (
		not integer(state.balance)
		or not integer(state.earned)
		or state.balance > state.earned
		or not integer(state.completed, 0, value.records.size())
		or not state.best is Dictionary
		or not state.best.has_all(["training", "full"])
	):
		return false
	for profile in state.best:
		if profile not in ShiftSession.PROFILES or not number(state.best[profile], 0, 100):
			return false
	var club: Variant = state.club
	if (
		not club is Dictionary
		or not club.has_all(CLUB_KEYS)
		or club.size() != CLUB_KEYS.size()
		or not club.active is bool
	):
		return false
	for key in ["fans", "capacity", "games", "income", "spent", "record_start"]:
		if not integer(club[key]):
			return false
	if (
		club.fans > 10000
		or club.capacity < 1
		or club.games > value.records.size()
		or not ids(club.buildings, ClubProgress.PROJECTS.keys())
		or not ids(club.host_buildings, Array(club.buildings))
	):
		return false
	if (
		not club.hosted is Dictionary
		or not club.services is Dictionary
		or not state.targets is Dictionary
		or not state.service_inputs is Dictionary
		or not state.seasons is Dictionary
	):
		return false
	if (
		not ids(state.host_order, attempts.keys())
		or state.host_order.size() != club.games
		or club.hosted.size() != club.games
		or state.targets.size() != club.games
	):
		return false
	for id in state.host_order:
		if not club.hosted.has(id) or not receipt(club.hosted[id]) or not state.targets.get(id) is bool:
			return false
	if club.games == 0:
		if club.last != {}:
			return false
	elif club.last != club.hosted[state.host_order[-1]]:
		return false
	if (
		not ids(state.pending_ids, attempts.keys())
		or not club.pending is String
		or club.pending != (state.pending_ids[0] if not state.pending_ids.is_empty() else "")
	):
		return false
	for id in state.pending_ids:
		if club.hosted.has(id) or attempts[id] < club.record_start:
			return false
	if (
		not club.active
		and (club.games != 0 or not club.buildings.is_empty() or not state.pending_ids.is_empty())
	):
		return false
	if state.service_inputs.size() != club.services.size():
		return false
	for id in club.services:
		if (
			not club.hosted.has(id)
			or not report(club.services[id])
			or not service_input(state.service_inputs.get(id), club.buildings)
		):
			return false
	if (
		not state.tool_costs is Dictionary
		or not state.project_costs is Dictionary
		or state.tool_costs.size() != value.upgrades.size()
		or state.project_costs.size() != club.buildings.size()
	):
		return false
	for id in value.upgrades:
		if not integer(state.tool_costs.get(id)):
			return false
	for id in club.buildings:
		if not integer(state.project_costs.get(id)):
			return false
	if state.seasons.size() != int(club.games) / 6:
		return false
	for key in state.seasons:
		if not key is String or not key.is_valid_int() or int(key) < 1 or int(key) > int(club.games) / 6:
			return false
		var season: Variant = state.seasons[key]
		if (
			not season is Dictionary
			or not season.has_all(["club", "tools", "objective"])
			or not season.club is Dictionary
			or not season.club.has_all(
				[
					"active",
					"fans",
					"capacity",
					"games",
					"income",
					"spent",
					"buildings",
					"pending",
					"record_start",
					"host_buildings"
				]
			)
			or not ids(season.tools, Array(value.upgrades))
			or not goal(season.objective)
		):
			return false
		if (
			not season.club.active is bool
			or not season.club.pending is String
			or not integer(season.club.fans, 0, 10000)
			or not integer(season.club.capacity, 1)
			or not ids(season.club.buildings, Array(club.buildings))
			or not ids(season.club.host_buildings, Array(season.club.buildings))
		):
			return false
		for field in ["games", "income", "spent", "record_start"]:
			if not integer(season.club[field]):
				return false
		if season.club.games != int(key) * 6:
			return false
	var event_log: Variant = value.club
	if (
		not event_log is Dictionary
		or event_log.size() != 3
		or not event_log.has_all(["record_start", "tool_start", "events"])
		or not integer(event_log.record_start, 0, value.records.size())
		or not integer(event_log.tool_start, 0, value.upgrades.size())
		or event_log.record_start != club.record_start
		or not event_log.events is Array
		or event_log.events.size() > 4000 + ClubProgress.PROJECTS.size()
	):
		return false
	var hosts := {}
	var services := {}
	var buildings := {}
	var previous_records: int = event_log.record_start
	var previous_tools: int = event_log.tool_start
	for event in event_log.events:
		if (
			not event is Dictionary
			or not event.has_all(["type", "id", "records", "tools"])
			or not event.id is String
			or event.size() != (5 if event.type == "service" else 4)
			or not integer(event.records, previous_records, value.records.size())
			or not integer(event.tools, previous_tools, value.upgrades.size())
		):
			return false
		previous_records = event.records
		previous_tools = event.tools
		match event.type:
			"game":
				if (
					not club.hosted.has(event.id)
					or hosts.has(event.id)
					or not attempts.has(event.id)
					or attempts[event.id] >= event.records
					or hosts.size() >= state.host_order.size()
					or state.host_order[hosts.size()] != event.id
				):
					return false
				hosts[event.id] = true
			"service":
				if (
					not hosts.has(event.id)
					or services.has(event.id)
					or not club.services.has(event.id)
					or event.get("input") != state.service_inputs[event.id]
				):
					return false
				services[event.id] = true
			"build":
				if event.id not in club.buildings or buildings.has(event.id):
					return false
				buildings[event.id] = true
			_:
				return false
	return (
		hosts.size() == club.hosted.size()
		and services.size() == club.services.size()
		and buildings.size() == club.buildings.size()
	)
