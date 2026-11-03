class_name ShiftSession
extends Node
signal changed
signal finished(result: Dictionary)
enum Phase { PRACTICE, ACTIVE, FINISHED }
const JOB_NAMES := ["Mow outfield","Drag dirt","Chalk lines","Water dirt","Repair mound"]
const PROFILES := {
 "training": {"title":"Training shift","duration":900.0,"goals":[25.0,50.0,50.0,50.0,100.0],"pay_rate":1.0,"bonus":50},
 "full": {"title":"Full park prep","duration":1800.0,"goals":[100.0,100.0,100.0,100.0,100.0],"pay_rate":3.0,"bonus":150},
 "quick_mow": {"title":"Morning mowing","duration":600.0,"goals":[10.0,0.0,0.0,0.0,0.0],"pay_rate":0.6,"bonus":40,"contract":true,"minimum_earnings":0},
 "mound_callout": {"title":"Mound callout","duration":300.0,"goals":[0.0,0.0,0.0,0.0,100.0],"pay_rate":0.25,"bonus":15,"contract":true,"minimum_earnings":0},
 "infield_turnaround": {"title":"Between-games infield","duration":720.0,"goals":[0.0,25.0,0.0,25.0,0.0],"pay_rate":0.9,"bonus":60,"contract":true,"minimum_earnings":500}
}
var attempt_id := ""
var phase: Phase = Phase.PRACTICE
var profile_id := "full"
var duration_seconds := 1800.0
var remaining_seconds := 1800.0
var elapsed_seconds := 0.0
var values := PackedFloat64Array([0,0,0,0,0])
var full_completion := [false,false,false,false,false]
var _result: Dictionary = {}

func start(profile: String) -> bool:
 if phase == Phase.ACTIVE or not PROFILES.has(profile):
  return false
 attempt_id = Crypto.new().generate_random_bytes(16).hex_encode()
 profile_id = profile
 duration_seconds = PROFILES[profile]["duration"]
 remaining_seconds = duration_seconds
 elapsed_seconds = 0
 values.fill(0)
 full_completion = [false,false,false,false,false]
 _result.clear()
 phase = Phase.ACTIVE
 changed.emit()
 return true

func goals() -> Array:
 return PROFILES[profile_id]["goals"].duplicate()

func title() -> String:
 return PROFILES[profile_id]["title"]

func set_progress(progress: Array,complete: Array) -> bool:
 if progress.size() != JOB_NAMES.size() or complete.size() != JOB_NAMES.size():
  return false
 for i in range(progress.size()):
  if typeof(progress[i]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(progress[i])) or typeof(complete[i]) != TYPE_BOOL:
   return false
 var different := false
 for i in range(progress.size()):
  var value := clampf(float(progress[i]),0,100)
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

func score() -> float:
 var points := 0.0
 var targets := goals()
 for i in range(JOB_NAMES.size()):
  if float(targets[i]) > 0:
   points += clampf(values[i]/float(targets[i]),0,1)*(100.0/maxi(jobs_required(),1))
 var value := snappedf(points,0.1)
 return value if jobs_completed() == jobs_required() else minf(value,99.9)

func advance(delta: float) -> void:
 if phase != Phase.ACTIVE or delta < 0 or not is_finite(delta):
  return
 var previous := ceili(remaining_seconds)
 elapsed_seconds = minf(duration_seconds,elapsed_seconds+delta)
 remaining_seconds = maxf(0,duration_seconds-elapsed_seconds)
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
 _result = {"profile_id":profile_id,"title":title(),"reason":reason,"score":score(),"jobs_completed":jobs_completed(),"values":Array(values),"goals":goals(),"met":met,"elapsed_seconds":elapsed_seconds,"remaining_seconds":remaining_seconds,"duration_seconds":duration_seconds}
 phase = Phase.FINISHED
 changed.emit()
 finished.emit(get_result())

func get_result() -> Dictionary:
 return _result.duplicate(true)

static func clock_text(seconds: float) -> String:
 var whole := maxi(0,ceili(seconds))
 return "%02d:%02d" % [whole/60,whole%60]
