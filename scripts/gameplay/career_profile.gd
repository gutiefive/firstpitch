class_name CareerProfile
extends RefCounted
signal changed
const UPGRADES := {
	"wide_deck": {"title": "Wide mower deck", "cost": 300, "detail": "3.0 m cut width (standard: 2.4 m)"},
	"hose_nozzle":
	{
		"title": "High-flow nozzle",
		"cost": 200,
		"detail": "25% faster watering; same reach and moisture target"
	},
	"wide_drag":
	{
		"title": "Wide drag mat",
		"cost": 400,
		"minimum_earnings": 500,
		"width_multiplier": 1.25,
		"detail": "3.5 m preparation width (standard: 2.8 m). Requires Field Hand."
	},
	"guide_wheel":
	{
		"title": "Chalk guide wheel",
		"cost": 350,
		"minimum_earnings": 500,
		"capture_distance": 0.65,
		"capture_angle": 30.0,
		"lookahead": 2.5,
		"correction_rate": 0.65,
		"detail":
		(
			"Helps follow a nearby foul guide while pushing with the gate open. Manual steering "
			+ "overrides. Requires Field Hand."
		)
	}
}
const RANKS := [[0, "Rookie"], [500, "Field Hand"], [1500, "Crew Lead"], [3500, "Head Groundskeeper"]]
const MAX_RECORDS := 2000
# V4 adds frozen receipts/state; preserve the full existing 2,000-attempt limit.
const MAX_BYTES := 16 * 1024 * 1024
var path := "user://career.dat"
var data := {"version": 1, "records": [], "upgrades": PackedStringArray()}
var files := SaveRecovery.new()
var legacy_context := {}
var healthy := true
var error := ""
var earned := 0
var balance := 0
var completed := 0
var club := ClubProgress.initial()
var best := {"training": 0.0, "full": 0.0}


static func valid_id(id: Variant) -> bool:
	if not id is String:
		return false
	return (
		(id.length() == 32 and id.is_valid_hex_number(false))
		or (id.begins_with("legacy-") and id.length() == 71 and id.substr(7).is_valid_hex_number(false))
	)


static func valid_result(result: Variant) -> bool:
	if not result is Dictionary or not result.has_all(["profile_id", "elapsed_seconds"]):
		return false
	return FieldSave.new().session_ok(
		{"phase": 2, "profile": result.profile_id, "elapsed": result.elapsed_seconds, "result": result}
	)


static func payout(result: Dictionary) -> int:
	var profile: Dictionary = ShiftSession.PROFILES[result.profile_id]
	return (
		floori(float(result.score) * float(profile.pay_rate))
		+ (int(profile.bonus) if result.reason == "completed" else 0)
	)


func legacy_validate(value: Variant) -> bool:
	if (
		not value is Dictionary
		or not value.has_all(["version", "records", "upgrades"])
		or typeof(value.version) != TYPE_INT
		or value.version not in [1, 2, 3]
	):
		return false
	if (
		not value.records is Array
		or value.records.size() > MAX_RECORDS
		or not value.upgrades is PackedStringArray
	):
		return false
	var ids := {}
	var total := 0
	var finished_count := 0
	var personal_best := {}
	var seasons := {}
	for profile in ShiftSession.PROFILES:
		personal_best[profile] = 0.0
	for record in value.records:
		if (
			not record is Dictionary
			or not record.has_all(["id", "result"])
			or not valid_id(record.id)
			or ids.has(record.id)
			or not LegacyCareerRules.valid_result(record.result)
		):
			return false
		ids[record.id] = true
		total += LegacyCareerRules.payout(record.result)
		finished_count += int(record.result.reason == "completed")
		personal_best[record.result.profile_id] = maxf(
			personal_best[record.result.profile_id], record.result.score
		)
	var owned := {}
	var costs := 0
	for id in value.upgrades:
		if not LegacyCareerRules.UPGRADES.has(id) or owned.has(id):
			return false
		owned[id] = true
		costs += int(LegacyCareerRules.UPGRADES[id].cost)
	var income := 0
	var stadium_cost := 0
	var replayed := LegacyCareerRules.initial()
	if value.version in [2, 3]:
		var state := ClubProgress.legacy_replay(value.get("club"), value.records, value.upgrades, seasons)
		if state.is_empty():
			return false
		if value.version == 2:
			for event in value.club.events:
				if event.type == "service":
					return false
		replayed = state
		income = state.income
		stadium_cost = state.spent
	elif value.has("club"):
		return false
	for id in value.upgrades:
		if total + income < int(LegacyCareerRules.UPGRADES[id].get("minimum_earnings", 0)):
			return false
	if total + income - costs - stadium_cost < 0:
		return false
	legacy_context = {
		"balance": total + income - costs - stadium_cost,
		"earned": total + income,
		"completed": finished_count,
		"best": personal_best,
		"club": replayed,
		"seasons": seasons
	}
	return true


func load_profile() -> bool:
	error = ""
	var loaded := files.load_checked(path, "FPCREW01", MAX_BYTES - 40, validate)
	if loaded.get("missing", false):
		data = {"version": 1, "records": [], "upgrades": PackedStringArray()}
		healthy = true
		rebuild()
		changed.emit()
		return true
	if loaded.is_empty():
		healthy = false
		error = files.error
		changed.emit()
		return false
	var value: Dictionary = loaded.value
	var recovery_notice := files.notice
	healthy = true
	if value.version != 4:
		var backup := path.get_basename() + ".v3.bak"
		if FileAccess.file_exists(backup):
			if FileAccess.get_file_as_bytes(backup) != FileAccess.get_file_as_bytes(path):
				backup = (
					path.get_basename()
					+ ".v3."
					+ str(Time.get_unix_time_from_system()).replace(".", "-")
					+ ".bak"
				)
		if not FileAccess.file_exists(backup) and not files.copy_flushed(path, backup):
			healthy = false
			error = "Career migration could not keep the original backup. Existing files kept."
			changed.emit()
			return false
		if not commit(CareerState.from_legacy(value, legacy_context)):
			healthy = false
			changed.emit()
			return false
		error = recovery_notice + " Career migrated to v4; original kept as " + backup.get_file() + "."
	else:
		data = value.duplicate(true)
		rebuild()
		error = recovery_notice
	changed.emit()
	return true


func commit(candidate: Dictionary) -> bool:
	if candidate.get("version") != 4:
		if not legacy_validate(candidate):
			error = "Career change could not be validated."
			return false
		candidate = CareerState.from_legacy(candidate, legacy_context)
	if not healthy or not validate(candidate):
		if error.is_empty():
			error = "Career change could not be validated."
		changed.emit()
		return false
	var bytes := var_to_bytes(candidate)
	if bytes.size() > MAX_BYTES - 40:
		error = "Career record is full. No credits changed."
		changed.emit()
		return false
	if not files.write(path, "FPCREW01", bytes, MAX_BYTES - 40, validate):
		error = "Career could not be saved. No credits changed; retry from Career. " + files.error
		changed.emit()
		return false
	data = candidate.duplicate(true)
	error = ""
	rebuild()
	changed.emit()
	return true


func claim(id: String, result: Dictionary) -> Dictionary:
	if not healthy:
		return {"status": "error", "message": error}
	if not valid_id(id):
		return {"status": "error", "message": "Shift result could not be recorded."}
	for record in data.records:
		if record.id == id:
			var frozen_pay := recorded_pay(id)
			return {
				"status": "recorded",
				"pay": frozen_pay,
				"message": "Already recorded: %d cr for this attempt." % frozen_pay
			}
	if not valid_result(result):
		return {"status": "error", "message": "Shift result could not be recorded."}
	if data.records.size() >= MAX_RECORDS:
		return {"status": "error", "message": "Career record is full (2,000 shifts)."}
	var candidate := candidate_snapshot()
	var pay := payout(result)
	candidate.records.append({"id": id, "result": result.duplicate(true), "pay": pay})
	candidate.state.balance += pay
	candidate.state.earned += pay
	candidate.state.completed += int(result.reason == "completed")
	candidate.state.best[result.profile_id] = maxf(
		candidate.state.best.get(result.profile_id, 0), result.score
	)
	if candidate.state.club.active and ClubProgress.eligible(result):
		candidate.state.pending_ids.append(id)
		candidate.state.club.pending = candidate.state.pending_ids[0]
	var previous_rank := rank_title()
	if not commit(candidate):
		return {"status": "error", "message": error}
	return {
		"status": "awarded",
		"pay": pay,
		"message":
		"Earned %d cr%s" % [pay, " · Promoted to " + rank_title() if previous_rank != rank_title() else ""]
	}


func purchase(id: String) -> bool:
	if not healthy or not upgrade_unlocked(id) or owns(id) or balance < int(UPGRADES[id].cost):
		return false
	var candidate := candidate_snapshot()
	var cost := int(UPGRADES[id].cost)
	candidate.upgrades.append(id)
	candidate.state.balance -= cost
	candidate.state.tool_costs[id] = cost
	return commit(candidate)


func upgrade_unlocked(id: String) -> bool:
	return UPGRADES.has(id) and earned >= int(UPGRADES[id].get("minimum_earnings", 0))


func owns(id: String) -> bool:
	return id in data.upgrades


func legacy_rebuild() -> void:
	if not legacy_validate(data):
		return
	earned = legacy_context.earned
	balance = legacy_context.balance
	completed = legacy_context.completed
	best = legacy_context.best.duplicate(true)
	club = legacy_context.club.duplicate(true)


func rank_index() -> int:
	var index := 0
	for i in range(RANKS.size()):
		if earned >= int(RANKS[i][0]):
			index = i
	return index


func rank_title() -> String:
	return RANKS[rank_index()][1]


func next_rank_text() -> String:
	var index := rank_index()
	return (
		"%d cr lifetime earnings to %s" % [int(RANKS[index + 1][0]) - earned, RANKS[index + 1][1]]
		if index < RANKS.size() - 1
		else "Top crew rank reached"
	)


func club_started() -> bool:
	return bool(data.state.club.active) if data.version == 4 else data.version in [2, 3]


func start_club() -> bool:
	if not healthy or club_started():
		return false
	var candidate := candidate_snapshot()
	candidate.club = {"record_start": data.records.size(), "tool_start": data.upgrades.size(), "events": []}
	candidate.state.club = ClubProgress.initial()
	candidate.state.club.active = true
	candidate.state.club.record_start = data.records.size()
	return commit(candidate)


func pending_home_game(id: String) -> bool:
	if not club_started() or club.hosted.has(id):
		return false
	if data.version == 4:
		return id in data.state.pending_ids
	for i in range(int(club.record_start), data.records.size()):
		if data.records[i].id == id:
			return ClubProgress.eligible(data.records[i].result)
	return false


func host_game(id: String) -> Dictionary:
	if not healthy or not club_started():
		return {"status": "error", "message": "Join the Owls before hosting a home game."}
	if club.hosted.has(id):
		return {"status": "recorded", "message": "This home game has already been hosted."}
	if not pending_home_game(id):
		return {"status": "error", "message": "Complete all home-game prep goals first."}
	var candidate := candidate_snapshot()
	var result := {}
	for record in candidate.records:
		if record.id == id:
			result = record.result
			break
	var state: Dictionary = candidate.state.club
	var receipt := ClubProgress.forecast(state, result)
	var income := int(receipt.net) + int(receipt.get("priority_bonus", 0))
	state.host_buildings = state.buildings.duplicate()
	state.games = receipt.game
	state.fans = receipt.fans_after
	state.income += income
	state.hosted[id] = receipt.duplicate(true)
	state.last = receipt
	candidate.state.targets[id] = ClubSchedule.target_met(candidate.state.host_order.size(), result)
	candidate.state.host_order.append(id)
	candidate.state.pending_ids.remove_at(candidate.state.pending_ids.find(id))
	state.pending = candidate.state.pending_ids[0] if not candidate.state.pending_ids.is_empty() else ""
	candidate.state.balance += income
	candidate.state.earned += income
	candidate.club.events.append(
		{"type": "game", "id": id, "records": data.records.size(), "tools": data.upgrades.size()}
	)
	if int(state.games) % 6 == 0:
		candidate.state.seasons[str(int(state.games) / 6)] = CareerState.snapshot(state, candidate.upgrades)
	if not commit(candidate):
		return {"status": "error", "message": error}
	return {
		"status": "hosted",
		"receipt": receipt.duplicate(true),
		"message":
		(
			"Home game %d: %d attended · +%d fans · %d cr net club income"
			% [receipt.game, receipt.attendance, receipt.fans_gained, income]
		)
	}


func purchase_stadium(id: String) -> bool:
	if (
		not healthy
		or not club_started()
		or not ClubProgress.project_ready(club, id)
		or balance < int(ClubProgress.PROJECTS[id].cost)
	):
		return false
	var candidate := candidate_snapshot()
	var cost := int(ClubProgress.PROJECTS[id].cost)
	var state: Dictionary = candidate.state.club
	candidate.state.balance -= cost
	candidate.state.project_costs[id] = cost
	state.spent += cost
	state.capacity += int(ClubProgress.PROJECTS[id].seats)
	state.buildings.append(id)
	candidate.club.events.append(
		{"type": "build", "id": id, "records": data.records.size(), "tools": data.upgrades.size()}
	)
	return commit(candidate)


func latest_host_id() -> String:
	var hosted := host_ids()
	return hosted[-1] if not hosted.is_empty() else ""


func claim_service(id: String, input: Dictionary) -> bool:
	if (
		not healthy
		or not club_started()
		or id != latest_host_id()
		or club.services.has(id)
		or not String(club.pending).is_empty()
	):
		return false
	var report := ParkSatisfaction.evaluate(club, input)
	if report.is_empty():
		return false
	var candidate := candidate_snapshot()
	var bonus := int(report.bonus)
	candidate.state.club.services[id] = report.duplicate(true)
	candidate.state.service_inputs[id] = input.duplicate(true)
	candidate.state.club.income += bonus
	candidate.state.club.fans += int(report.fans)
	candidate.state.balance += bonus
	candidate.state.earned += bonus
	candidate.club.events.append(
		{
			"type": "service",
			"id": id,
			"records": data.records.size(),
			"tools": data.upgrades.size(),
			"input": input.duplicate(true)
		}
	)
	return commit(candidate)


func validate(value: Variant) -> bool:
	return (
		CareerState.validate(value)
		if value is Dictionary and value.get("version") == 4
		else legacy_validate(value)
	)


func candidate_snapshot() -> Dictionary:
	if data.version == 4:
		return data.duplicate(true)
	if not legacy_validate(data):
		return {}
	return CareerState.from_legacy(data, legacy_context)


func rebuild() -> void:
	if data.version != 4:
		legacy_rebuild()
		return
	earned = data.state.earned
	balance = data.state.balance
	completed = data.state.completed
	best = data.state.best.duplicate(true)
	club = data.state.club.duplicate(true)


func recorded_pay(id: String) -> int:
	for record in data.records:
		if record.id == id:
			return int(record.pay) if data.version == 4 else LegacyCareerRules.payout(record.result)
	return 0


func host_ids() -> PackedStringArray:
	if data.version == 4:
		return data.state.host_order.duplicate()
	var hosted := PackedStringArray()
	if club_started():
		for event in data.club.events:
			if event.type == "game":
				hosted.append(event.id)
	return hosted


func target_met(id: String, index: int, result: Dictionary) -> bool:
	return bool(data.state.targets[id]) if data.version == 4 else LegacyCareerRules.target_met(index, result)


func saved_objective(season: int) -> Dictionary:
	return data.state.seasons[str(season)].objective.duplicate(true)
