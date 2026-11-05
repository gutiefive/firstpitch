class_name ShiftSession
extends Node
signal changed
signal finished(result: Dictionary)
enum Phase { PRACTICE, ACTIVE, FINISHED }
const JOB_NAMES := ["Mow outfield", "Drag dirt", "Chalk lines", "Water dirt", "Repair mound"]
const PROFILES := {
	"training":
	{
		"title": "Training shift",
		"duration": 900.0,
		"goals": [25.0, 50.0, 50.0, 50.0, 100.0],
		"pay_rate": 1.0,
		"bonus": 50,
		"start": "fresh",
		"quality":
		{
			"minimum": 0.7,
			"chalk_per_metre": 0.005,
			"water_penalty": 0.25,
			"rut_penalty": 0.25,
			"stripe_bonus": 0.03,
			"stripe_tolerance": 0.15,
			"stripe_min_samples": 20,
			"puddle_threshold": 0.95,
			"puddle_seconds": 12.0,
			"wet_drag_threshold": 0.75,
			"dry_moisture": 0.7
		},
		"wear_rules":
		{
			"dry_fraction": 0.7,
			"base_radius": 2.2,
			"batter_radius": 4.5,
			"hole_radius": 3.0,
			"hole_axis_x": 0.55,
			"hole_axis_y": -0.35,
			"lane_width": 1.8,
			"heavy_chance": 0.85,
			"light_chance": 0.12,
			"chalk_home_radius": 8.0,
			"chalk_base_radius": 3.0,
			"rear_mound_weight": 0.55,
			"mound_min_fraction": 0.65,
			"ready_moisture": 0.8
		}
	},
	"home_game":
	{
		"title": "Owls home-game prep",
		"duration": 1200.0,
		"goals": [15.0, 50.0, 100.0, 50.0, 100.0],
		"pay_rate": 1.0,
		"bonus": 60,
		"start": "game_day",
		"wear": 0.35,
		"club": true
	},
	"home_hot":
	{
		"title": "Owls hot-afternoon prep",
		"duration": 1200.0,
		"goals": [15.0, 25.0, 100.0, 90.0, 100.0],
		"pay_rate": 1.0,
		"bonus": 60,
		"start": "game_day",
		"wear": 0.55,
		"club": true,
		"wear_rules": {"dry_fraction": 1.0}
	},
	"home_rain":
	{
		"title": "Owls rain-recovery prep",
		"duration": 1200.0,
		"goals": [10.0, 75.0, 100.0, 0.0, 100.0],
		"pay_rate": 1.0,
		"bonus": 60,
		"start": "game_day",
		"wear": 0.65,
		"club": true
	},
	"home_double":
	{
		"title": "Owls doubleheader prep",
		"duration": 900.0,
		"goals": [10.0, 75.0, 100.0, 25.0, 100.0],
		"pay_rate": 1.0,
		"bonus": 60,
		"start": "game_day",
		"wear": 0.85,
		"club": true
	},
	"full":
	{
		"title": "Full park prep",
		"duration": 1800.0,
		"goals": [100.0, 100.0, 100.0, 100.0, 100.0],
		"pay_rate": 3.0,
		"bonus": 150,
		"start": "game_day",
		"wear": 0.55
	},
	"quick_mow":
	{
		"title": "Morning mowing",
		"duration": 600.0,
		"goals": [10.0, 0.0, 0.0, 0.0, 0.0],
		"pay_rate": 0.6,
		"bonus": 40,
		"contract": true,
		"minimum_earnings": 0
	},
	"mound_callout":
	{
		"title": "Mound callout",
		"duration": 300.0,
		"goals": [0.0, 0.0, 0.0, 0.0, 100.0],
		"pay_rate": 0.25,
		"bonus": 15,
		"contract": true,
		"minimum_earnings": 0
	},
	"infield_turnaround":
	{
		"title": "Between-games infield",
		"duration": 720.0,
		"goals": [0.0, 25.0, 0.0, 25.0, 0.0],
		"pay_rate": 0.9,
		"bonus": 60,
		"contract": true,
		"minimum_earnings": 500,
		"start": "game_day",
		"wear": 0.45
	},
	"doubleheader":
	{
		"title": "Doubleheader turnaround",
		"duration": 480.0,
		"goals": [0.0, 75.0, 100.0, 75.0, 100.0],
		"pay_rate": 2.0,
		"bonus": 100,
		"contract": true,
		"minimum_earnings": 1500,
		"start": "game_day",
		"wear": 0.85
	}
}
var attempt_id := ""
var phase: Phase = Phase.PRACTICE
var profile_id := "full"
var duration_seconds := 1800.0
var remaining_seconds := 1800.0
var elapsed_seconds := 0.0
var values := PackedFloat64Array([0, 0, 0, 0, 0])
var full_completion := [false, false, false, false, false]
var _result: Dictionary = {}
var start_mode := "fresh"
var wear_seed := 0
var starting_counts := PackedInt64Array([0, 0, 0, 0, 0])
var work_totals := PackedInt64Array([0, 0, 0, 0, 0])
var quality_enabled := true
var job_quality := PackedFloat64Array([1, 1, 1, 1, 1])
var mowing_bonus := 0.0


static func quality_rules(profile: String = "training") -> Dictionary:
	var rules: Dictionary = PROFILES.training.quality.duplicate(true)
	if profile != "training":
		rules.merge(PROFILES[profile].get("quality", {}), true)
	return rules


static func wear_rules(profile: String = "training") -> Dictionary:
	var rules: Dictionary = PROFILES.training.wear_rules.duplicate(true)
	if profile != "training":
		rules.merge(PROFILES[profile].get("wear_rules", {}), true)
	return rules


func configure_work(starting: Array, totals: Array, mode: String = "fresh", wear_seed_value: int = 0) -> bool:
	if starting.size() != 5 or totals.size() != 5 or mode not in ["fresh", "game_day"]:
		return false
	for i in CrewJob.ALL:
		if (
			typeof(starting[i]) != TYPE_INT
			or typeof(totals[i]) != TYPE_INT
			or starting[i] < 0
			or totals[i] < starting[i]
		):
			return false
	starting_counts = PackedInt64Array(starting)
	work_totals = PackedInt64Array(totals)
	start_mode = mode
	wear_seed = wear_seed_value
	return true


func set_counts(current: Array, complete: Array) -> bool:
	if current.size() != 5:
		return false
	var progress := []
	for i in CrewJob.ALL:
		var needed := work_totals[i] - starting_counts[i]
		progress.append(
			(
				100.0
				if needed == 0 and work_totals[i] > 0
				else 100.0 * maxi(0, int(current[i]) - starting_counts[i]) / maxi(1, needed)
			)
		)
	return set_progress(progress, complete)


func set_quality(qualities: Array, bonus: float = 0) -> bool:
	var rules := quality_rules(profile_id)
	if qualities.size() != 5 or not is_finite(bonus) or bonus < 0 or bonus > float(rules.stripe_bonus):
		return false
	for q in qualities:
		if typeof(q) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(q)) or q < rules.minimum or q > 1:
			return false
	if float(qualities[CrewJob.MOW]) != 1 or float(qualities[CrewJob.MOUND]) != 1:
		return false
	var different := Array(job_quality) != qualities or mowing_bonus != bonus
	job_quality = PackedFloat64Array(qualities)
	mowing_bonus = bonus
	if different:
		changed.emit()
	return true


func quality_multiplier() -> float:
	if not quality_enabled:
		return 1
	var total := 0.0
	for i in CrewJob.ALL:
		if goals()[i] > 0:
			total += job_quality[i]
	if goals()[CrewJob.MOW] > 0:
		total += mowing_bonus
	return clampf(total / maxi(1, jobs_required()), quality_rules(profile_id).minimum, 1)


func quality_tip() -> String:
	if not quality_enabled:
		return "Legacy attempt: finish quality is neutral."
	var worst := -1
	var loss := 0.0
	for i in [1, 2, 3]:
		if goals()[i] > 0 and 1 - job_quality[i] > loss:
			loss = 1 - job_quality[i]
			worst = i
	return (
		{
			1: "Biggest loss: wet-dirt ruts. Let dirt dry before dragging.",
			2: "Biggest loss: off-guide chalk. Close the gate when repositioning.",
			3: "Biggest loss: puddles. Water in passes rather than soaking one spot."
		}
		. get(worst, "Clean finish. Keep passes controlled and stripes consistent.")
	)


func start(profile: String) -> bool:
	if phase == Phase.ACTIVE or not PROFILES.has(profile):
		return false
	attempt_id = Crypto.new().generate_random_bytes(16).hex_encode()
	profile_id = profile
	duration_seconds = PROFILES[profile]["duration"]
	remaining_seconds = duration_seconds
	elapsed_seconds = 0
	values.fill(0)
	full_completion = [false, false, false, false, false]
	_result.clear()
	start_mode = "fresh"
	wear_seed = 0
	starting_counts.fill(0)
	quality_enabled = true
	job_quality.fill(1)
	mowing_bonus = 0
	phase = Phase.ACTIVE
	changed.emit()
	return true


func goals() -> Array:
	return PROFILES[profile_id]["goals"].duplicate()


func title() -> String:
	return PROFILES[profile_id]["title"]


func set_progress(progress: Array, complete: Array) -> bool:
	if progress.size() != JOB_NAMES.size() or complete.size() != JOB_NAMES.size():
		return false
	for i in range(progress.size()):
		if (
			typeof(progress[i]) not in [TYPE_INT, TYPE_FLOAT]
			or not is_finite(float(progress[i]))
			or typeof(complete[i]) != TYPE_BOOL
		):
			return false
	var different := false
	for i in range(progress.size()):
		var value := clampf(float(progress[i]), 0, 100)
		different = different or value != values[i] or complete[i] != full_completion[i]
		values[i] = value
		full_completion[i] = complete[i]
	if different:
		changed.emit()
	return true


func goal_met(index: int) -> bool:
	var goal: float = PROFILES[profile_id]["goals"][index]
	if goal <= 0:
		return false
	return bool(full_completion[index]) and values[index] >= 100 if goal == 100 else values[index] >= goal


func jobs_required() -> int:
	var count := 0
	for goal in goals():
		if goal > 0:
			count += 1
	return count


func jobs_completed() -> int:
	var count := 0
	for i in range(JOB_NAMES.size()):
		if goal_met(i):
			count += 1
	return count


func coverage_score() -> float:
	var points := 0.0
	var targets := goals()
	for i in range(JOB_NAMES.size()):
		if float(targets[i]) > 0:
			points += clampf(values[i] / float(targets[i]), 0, 1) * (100.0 / maxi(jobs_required(), 1))
	var value := snappedf(points, 0.1)
	return value if jobs_completed() == jobs_required() else minf(value, 99.9)


func score() -> float:
	return snappedf(coverage_score() * quality_multiplier(), 0.1)


func advance(delta: float) -> void:
	if phase != Phase.ACTIVE or delta < 0 or not is_finite(delta):
		return
	var previous := ceili(remaining_seconds)
	elapsed_seconds = minf(duration_seconds, elapsed_seconds + delta)
	remaining_seconds = maxf(0, duration_seconds - elapsed_seconds)
	# Work collected during the deadline frame wins over the timeout condition.
	if jobs_completed() == jobs_required():
		finish("completed")
	elif remaining_seconds <= 0:
		finish("time_up")
	elif ceili(remaining_seconds) != previous:
		changed.emit()


func end_early() -> bool:
	if phase != Phase.ACTIVE:
		return false
	finish("completed" if jobs_completed() == jobs_required() else "ended_early")
	return true


func finish(reason: String) -> void:
	if phase != Phase.ACTIVE:
		return
	var met := []
	for i in range(JOB_NAMES.size()):
		met.append(goal_met(i))
	_result = {
		"profile_id": profile_id,
		"title": title(),
		"reason": reason,
		"score": score(),
		"jobs_completed": jobs_completed(),
		"values": Array(values),
		"goals": goals(),
		"met": met,
		"elapsed_seconds": elapsed_seconds,
		"remaining_seconds": remaining_seconds,
		"duration_seconds": duration_seconds
	}
	if quality_enabled:
		_result.merge(
			{
				"coverage_score": coverage_score(),
				"quality": quality_multiplier(),
				"job_quality": Array(job_quality),
				"mowing_bonus": mowing_bonus,
				"quality_tip": quality_tip()
			}
		)
	phase = Phase.FINISHED
	changed.emit()
	finished.emit(get_result())


func get_result() -> Dictionary:
	return _result.duplicate(true)


static func clock_text(seconds: float) -> String:
	var whole := maxi(0, ceili(seconds))
	return "%02d:%02d" % [whole / 60, whole % 60]
