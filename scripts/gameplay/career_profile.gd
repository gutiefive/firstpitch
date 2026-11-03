class_name CareerProfile
extends RefCounted
signal changed
const UPGRADES := {
 "wide_deck":{"title":"Wide mower deck","cost":300,"detail":"3.0 m cut width (standard: 2.4 m)"},
 "hose_nozzle":{"title":"High-flow nozzle","cost":200,"detail":"25% faster watering; same reach and moisture target"}
}
const RANKS := [[0,"Rookie"],[500,"Field Hand"],[1500,"Crew Lead"],[3500,"Head Groundskeeper"]]
const MAX_RECORDS := 2000
var path := "user://career.dat"
var data := {"version":1,"records":[],"upgrades":PackedStringArray()}
var healthy := true
var error := ""
var earned := 0
var balance := 0
var completed := 0
var best := {"training":0.0,"full":0.0}

static func valid_id(id: Variant) -> bool:
 if not id is String:
  return false
 return (id.length()==32 and id.is_valid_hex_number(false)) or (id.begins_with("legacy-") and id.length()==71 and id.substr(7).is_valid_hex_number(false))

static func valid_result(result: Variant) -> bool:
 if not result is Dictionary or not result.has_all(["profile_id","elapsed_seconds"]):
  return false
 return FieldSave.new().session_ok({"phase":2,"profile":result.profile_id,"elapsed":result.elapsed_seconds,"result":result})

static func payout(result: Dictionary) -> int:
 var profile: Dictionary = ShiftSession.PROFILES[result.profile_id]
 return floori(float(result.score)*float(profile.pay_rate))+(int(profile.bonus) if result.reason == "completed" else 0)

func validate(value: Variant) -> bool:
 if not value is Dictionary or not value.has_all(["version","records","upgrades"]) or value.version != 1:
  return false
 if not value.records is Array or value.records.size()>MAX_RECORDS or not value.upgrades is PackedStringArray:
  return false
 var ids := {}
 var total := 0
 for record in value.records:
  if not record is Dictionary or not record.has_all(["id","result"]) or not valid_id(record.id) or ids.has(record.id) or not valid_result(record.result):
   return false
  ids[record.id] = true
  total += payout(record.result)
 var owned := {}
 for id in value.upgrades:
  if not UPGRADES.has(id) or owned.has(id):
   return false
  owned[id] = true
  total -= int(UPGRADES[id].cost)
 return total >= 0

func load_profile() -> bool:
 error = ""
 if not FileAccess.file_exists(path):
  data = {"version":1,"records":[],"upgrades":PackedStringArray()}
  healthy = true
  rebuild()
  changed.emit()
  return true
 var file := FileAccess.open(path,FileAccess.READ)
 var value: Variant = null
 if file != null and file.get_length() >= 40 and file.get_length() <= 4*1024*1024:
  var magic := file.get_buffer(8).get_string_from_ascii()
  var hash := file.get_buffer(32)
  var bytes := file.get_buffer(file.get_length()-40)
  if magic == "FPCREW01" and hash == FieldSave.new().digest(bytes):
   value = bytes_to_var(bytes)
 if file != null:
  file.close()
 if not validate(value):
  healthy = false
  error = "Career file is unreadable or damaged. Existing file kept."
  changed.emit()
  return false
 data = value.duplicate(true)
 healthy = true
 rebuild()
 changed.emit()
 return true

func commit(candidate: Dictionary) -> bool:
 if not healthy or not validate(candidate):
  if error.is_empty():
   error = "Career change could not be validated."
  changed.emit()
  return false
 var bytes := var_to_bytes(candidate)
 if bytes.size() > 4*1024*1024-40:
  error = "Career record is full. No credits changed."
  changed.emit()
  return false
 var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null:
  error = "Career could not be saved. No credits changed; retry from Career."
  changed.emit()
  return false
 file.store_buffer("FPCREW01".to_ascii_buffer())
 file.store_buffer(FieldSave.new().digest(bytes))
 file.store_buffer(bytes)
 file.flush()
 var ok := file.get_error() == OK
 file.close()
 if not ok or DirAccess.rename_absolute(path+".tmp",path) != OK:
  error = "Career could not be saved. No credits changed; retry from Career."
  changed.emit()
  return false
 data = candidate.duplicate(true)
 error = ""
 rebuild()
 changed.emit()
 return true

func claim(id: String,result: Dictionary) -> Dictionary:
 if not healthy:
  return {"status":"error","message":error}
 if not valid_id(id) or not valid_result(result):
  return {"status":"error","message":"Shift result could not be recorded."}
 for record in data.records:
  if record.id == id:
   return {"status":"recorded","pay":payout(record.result),"message":"Already recorded: %d cr for this attempt." % payout(record.result)}
 if data.records.size() >= MAX_RECORDS:
  return {"status":"error","message":"Career record is full (2,000 shifts)."}
 var candidate := data.duplicate(true)
 candidate.records.append({"id":id,"result":result.duplicate(true)})
 var previous_rank := rank_title()
 if not commit(candidate):
  return {"status":"error","message":error}
 var pay := payout(result)
 return {"status":"awarded","pay":pay,"message":"Earned %d cr%s" % [pay," · Promoted to "+rank_title() if previous_rank != rank_title() else ""]}

func purchase(id: String) -> bool:
 if not healthy or not UPGRADES.has(id) or owns(id) or balance < int(UPGRADES[id].cost):
  return false
 var candidate := data.duplicate(true)
 candidate.upgrades.append(id)
 return commit(candidate)

func owns(id: String) -> bool:
 return id in data.upgrades

func rebuild() -> void:
 earned = 0
 completed = 0
 best = {}
 for id in ShiftSession.PROFILES:
  best[id] = 0.0
 for record in data.records:
  var result: Dictionary = record.result
  earned += payout(result)
  completed += 1 if result.reason == "completed" else 0
  best[result.profile_id] = maxf(best[result.profile_id],result.score)
 balance = earned
 for id in data.upgrades:
  balance -= int(UPGRADES[id].cost)

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
 return "%d cr lifetime earnings to %s" % [int(RANKS[index+1][0])-earned,RANKS[index+1][1]] if index < RANKS.size()-1 else "Top crew rank reached"
