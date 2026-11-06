class_name LegacyCareerRules
extends RefCounted
# Immutable pre-v4 economics and validation, used only to import old careers.
# New transactions use the current catalogs; never tune these historical constants.
const START_FANS := 48
const START_CAPACITY := 120
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
const PROJECTS := {
	"bleachers":
	{
		"title": "Community bleachers",
		"cost": 600,
		"fans": 90,
		"requires": [],
		"seats": 120,
		"fan_bonus": 0,
		"ticket_bonus": 0,
		"food": 0,
		"detail": "Extend both foul lines with 120 seats. Supporters need room before crowds can grow."
	},
	"snack_shack":
	{
		"title": "Family snack shack",
		"cost": 450,
		"fans": 75,
		"requires": [],
		"seats": 0,
		"fan_bonus": 3,
		"ticket_bonus": 0,
		"food": 1,
		"detail": "Open a first-base concession: +1 cr food profit per attendee and +3 fans per game."
	},
	"grandstand":
	{
		"title": "Covered grandstand",
		"cost": 1400,
		"fans": 200,
		"requires": ["bleachers", "snack_shack"],
		"seats": 240,
		"fan_bonus": 5,
		"ticket_bonus": 1,
		"food": 0,
		"detail":
		"Extend both lines with 240 seats and cover the stands: +1 cr per ticket and +5 fans per game."
	},
	"grill_stand":
	{
		"title": "Owls grill stand",
		"cost": 900,
		"fans": 150,
		"requires": ["snack_shack"],
		"seats": 0,
		"fan_bonus": 3,
		"ticket_bonus": 0,
		"food": 1,
		"detail": "Open a third-base grill: +1 cr food profit per attendee and +3 fans per game."
	},
	"scoreboard":
	{
		"title": "Electronic scoreboard",
		"cost": 1100,
		"fans": 120,
		"requires": [],
		"seats": 0,
		"fan_bonus": 2,
		"ticket_bonus": 1,
		"food": 0,
		"detail": "Replace the old board: +1 cr per ticket and +2 fans per game."
	},
	"video_board":
	{
		"title": "Owls video board",
		"cost": 2600,
		"fans": 320,
		"requires": ["scoreboard", "grandstand"],
		"seats": 0,
		"fan_bonus": 6,
		"ticket_bonus": 1,
		"food": 0,
		"detail":
		"Replace the electronic board with a video screen: another +1 cr per ticket and +6 fans per game."
	}
}

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

const DATES := [
	{
		"opponent": "Mill Creek Foxes",
		"event": "Opening weekend",
		"target": 85,
		"minutes": 20,
		"brief": "Mara: Give our regulars a field they can be proud of. Aim for an 85 prep score."
	},
	{
		"opponent": "Riverbend Otters",
		"event": "Family afternoon",
		"target": 85,
		"minutes": 18,
		"brief": "Mara: Families arrive early today. Finish with two minutes to spare and an 85 prep score."
	},
	{
		"opponent": "Pine Ridge Bears",
		"event": "Rivalry night",
		"target": 90,
		"minutes": 20,
		"brief": "Mara: The neighbors are visiting. A 90 prep score will give us something to brag about."
	},
	{
		"opponent": "Maple Falls Robins",
		"event": "Community appreciation",
		"target": 90,
		"minutes": 18,
		"brief": "Mara: The volunteers have brought their families. Aim for 90 with two minutes left."
	},
	{
		"opponent": "Riverbend Otters",
		"event": "Friday under the lights",
		"target": 95,
		"minutes": 20,
		"brief": "Mara: The field is our calling card tonight. Let's aim for a 95 prep score."
	},
	{
		"opponent": "Pine Ridge Bears",
		"event": "Home finale",
		"target": 95,
		"minutes": 17,
		"brief": "Mara: Finish the home season strong: a 95 prep score with three minutes to spare."
	}
]


static func initial() -> Dictionary:
	var state := ClubProgress.initial()
	state.fans = START_FANS
	state.capacity = START_CAPACITY
	return state


static func number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func payout(result: Dictionary) -> int:
	var profile: Dictionary = LegacyShiftSession.PROFILES[result.profile_id]
	return (
		floori(float(result.score) * float(profile.pay_rate))
		+ (int(profile.bonus) if result.reason == "completed" else 0)
	)


static func valid_result(result: Variant) -> bool:
	if not result is Dictionary or not result.has_all(["profile_id", "elapsed_seconds"]):
		return false
	return session_ok(
		{"phase": 2, "profile": result.profile_id, "elapsed": result.elapsed_seconds, "result": result}
	)


static func session_ok(data: Variant) -> bool:
	if not data is Dictionary or not data.has_all(["phase", "profile", "elapsed", "result"]):
		return false
	if (
		data.has("attempt_id")
		and (
			not data.attempt_id is String
			or (not data.attempt_id.is_empty() and not CareerProfile.valid_id(data.attempt_id))
		)
	):
		return false
	if (
		typeof(data.phase) != TYPE_INT
		or data.phase not in [0, 1, 2]
		or not data.profile is String
		or not LegacyShiftSession.PROFILES.has(data.profile)
	):
		return false
	if (
		data.has("attempt_id")
		and data.phase != LegacyShiftSession.Phase.PRACTICE
		and data.attempt_id.is_empty()
	):
		return false
	if (
		not number(data.elapsed)
		or data.elapsed < 0
		or data.elapsed > LegacyShiftSession.PROFILES[data.profile].duration
		or not data.result is Dictionary
	):
		return false
	if data.phase == LegacyShiftSession.Phase.PRACTICE:
		return data.elapsed == 0 and data.result.is_empty()
	if data.phase == LegacyShiftSession.Phase.ACTIVE:
		return data.elapsed < LegacyShiftSession.PROFILES[data.profile].duration and data.result.is_empty()
	var result: Dictionary = data.result
	if (
		not result.has_all(["profile_id", "reason", "values", "met"])
		or result.profile_id != data.profile
		or result.reason not in ["completed", "time_up", "ended_early"]
	):
		return false
	if not result.values is Array or not result.met is Array:
		return false
	var check := LegacyShiftSession.new()
	check.start(data.profile)
	check.quality_enabled = result.has("quality")
	var valid := check.set_progress(result.values, result.met)
	if check.quality_enabled:
		valid = valid and result.has_all(["coverage_score", "job_quality", "mowing_bonus", "quality_tip"])
		if valid:
			valid = (
				result.job_quality is Array
				and number(result.mowing_bonus)
				and check.set_quality(result.job_quality, result.mowing_bonus)
			)
	if valid:
		check.elapsed_seconds = data.elapsed
		check.remaining_seconds = check.duration_seconds - data.elapsed
		valid = (
			(result.reason != "completed" or check.jobs_completed() == check.jobs_required())
			and (result.reason != "time_up" or check.remaining_seconds == 0)
		)
		check.finish(result.reason)
		valid = valid and check.get_result() == result
	check.free()
	return valid


static func forecast(state: Dictionary, result: Dictionary) -> Dictionary:
	var score: float = result.score
	var ticket := 4
	var food := 0
	var fan_bonus := 0
	for id in state.buildings:
		ticket += int(PROJECTS[id].ticket_bonus)
		food += int(PROJECTS[id].food)
		fan_bonus += int(PROJECTS[id].fan_bonus)
	var crowd := mini(state.capacity, maxi(1, floori(state.fans * (0.65 + 0.35 * score / 100))))
	var tickets := crowd * ticket
	var food_income := crowd * food
	var costs := 60 + crowd
	var growth := mini(10000 - int(state.fans), 8 + floori(score * 0.12) + fan_bonus)
	var receipt := {
		"game": int(state.games) + 1,
		"score": score,
		"attendance": crowd,
		"capacity": state.capacity,
		"fans_before": state.fans,
		"fans_gained": growth,
		"fans_after": int(state.fans) + growth,
		"ticket_income": tickets,
		"food_income": food_income,
		"costs": costs,
		"net": maxi(0, tickets + food_income - costs)
	}
	if TYPES.has(result.get("profile_id", "")):
		receipt.priority_bonus = bonus(result)
	return receipt


static func project_ready(state: Dictionary, id: String) -> bool:
	if not PROJECTS.has(id) or id in state.buildings or state.fans < int(PROJECTS[id].fans):
		return false
	for requirement in PROJECTS[id].requires:
		if requirement not in state.buildings:
			return false
	return true


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


static func target_met(index: int, result: Dictionary) -> bool:
	if TYPES.has(result.get("profile_id", "")):
		return priority_met(result)
	var date: Dictionary = DATES[posmod(index, DATES.size())]
	return (
		ClubProgress.eligible(result)
		and float(result.score) >= date.target
		and float(result.elapsed_seconds) <= int(date.minutes) * 60
	)


const OBJECTIVE_PROJECTS := [
	"bleachers", "snack_shack", "grandstand", "grill_stand", "scoreboard", "video_board"
]


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
