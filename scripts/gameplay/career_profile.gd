class_name CareerProfile
extends RefCounted
signal changed
const UPGRADES := {
 "wide_deck":{"title":"Wide mower deck","cost":300,"detail":"3.0 m cut width (standard: 2.4 m)"},
 "hose_nozzle":{"title":"High-flow nozzle","cost":200,"detail":"25% faster watering; same reach and moisture target"},
 "wide_drag":{"title":"Wide drag mat","cost":400,"minimum_earnings":500,"width_multiplier":1.25,"detail":"3.5 m preparation width (standard: 2.8 m). Requires Field Hand."},
 "guide_wheel":{"title":"Chalk guide wheel","cost":350,"minimum_earnings":500,"capture_distance":0.65,"capture_angle":30.0,"lookahead":2.5,"correction_rate":0.65,"detail":"Helps follow a nearby foul guide while pushing with the gate open. Manual steering overrides. Requires Field Hand."}
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
var club := ClubProgress.initial()
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
 if not value is Dictionary or not value.has_all(["version","records","upgrades"]) or typeof(value.version) != TYPE_INT or value.version not in [1,2,3]:
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
 var costs := 0
 for id in value.upgrades:
  if not UPGRADES.has(id) or owned.has(id):
   return false
  owned[id] = true
  costs += int(UPGRADES[id].cost)
 var income := 0
 var stadium_cost := 0
 if value.version in [2,3]:
  var state := ClubProgress.replay(value.get("club"),value.records,value.upgrades)
  if state.is_empty():
   return false
  if value.version == 2:
   for event in value.club.events:
    if event.type == "service":
     return false
  income = state.income
  stadium_cost = state.spent
 elif value.has("club"):
  return false
 for id in value.upgrades:
  if total+income < int(UPGRADES[id].get("minimum_earnings",0)):
   return false
 return total+income-costs-stadium_cost >= 0

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
 if not healthy or not upgrade_unlocked(id) or owns(id) or balance < int(UPGRADES[id].cost):
  return false
 var candidate := data.duplicate(true)
 candidate.upgrades.append(id)
 return commit(candidate)

func upgrade_unlocked(id: String) -> bool:
 return UPGRADES.has(id) and earned >= int(UPGRADES[id].get("minimum_earnings",0))

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
 club = ClubProgress.replay(data.club,data.records,data.upgrades) if club_started() else ClubProgress.initial()
 earned += int(club.income)
 balance = earned-int(club.spent)
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

func club_started() -> bool:
 return data.version in [2,3]

func start_club() -> bool:
 if not healthy or club_started():
  return false
 var candidate := data.duplicate(true)
 candidate.version = 2
 candidate.club = {"record_start":data.records.size(),"tool_start":data.upgrades.size(),"events":[]}
 return commit(candidate)

func pending_home_game(id: String) -> bool:
 if not club_started() or club.hosted.has(id):
  return false
 for i in range(int(club.record_start),data.records.size()):
  if data.records[i].id == id:
   return ClubProgress.eligible(data.records[i].result)
 return false

func host_game(id: String) -> Dictionary:
 if not healthy or not club_started():
  return {"status":"error","message":"Join the Owls before hosting a home game."}
 if club.hosted.has(id):
  return {"status":"recorded","message":"This home game has already been hosted."}
 if not pending_home_game(id):
  return {"status":"error","message":"Complete all home-game prep goals first."}
 var candidate := data.duplicate(true)
 candidate.club.events.append({"type":"game","id":id,"records":data.records.size(),"tools":data.upgrades.size()})
 if not commit(candidate):
  return {"status":"error","message":error}
 var receipt: Dictionary = club.last.duplicate(true)
 return {"status":"hosted","receipt":receipt,"message":"Home game %d: %d attended · +%d fans · %d cr net club income" % [receipt.game,receipt.attendance,receipt.fans_gained,receipt.net+int(receipt.get("priority_bonus",0))]}

func purchase_stadium(id: String) -> bool:
 if not healthy or not club_started() or not ClubProgress.project_ready(club,id) or balance < int(ClubProgress.PROJECTS[id].cost):
  return false
 var candidate := data.duplicate(true)
 candidate.club.events.append({"type":"build","id":id,"records":data.records.size(),"tools":data.upgrades.size()})
 return commit(candidate)

func latest_host_id() -> String:
 var id := ""
 if club_started():
  for event in data.club.events:
   if event.type == "game":
    id = event.id
 return id
func claim_service(id: String,input: Dictionary) -> bool:
 if not healthy or not club_started() or id != latest_host_id() or club.services.has(id) or not String(club.pending).is_empty() or ParkSatisfaction.evaluate(club,input).is_empty():
  return false
 var candidate := data.duplicate(true)
 candidate.version = 3
 candidate.club.events.append({"type":"service","id":id,"records":data.records.size(),"tools":data.upgrades.size(),"input":input.duplicate(true)})
 return commit(candidate)
