class_name FieldSave
extends RefCounted
# Resource-free Variant data only. Validate the complete snapshot before mutation.
const VERSION := 3
const V1_CEDAR_HASH := "4b93508a852f996a404526525630f7fcb6b2271cd10d8adedd4c9f2364fd70b5"
const V2_CEDAR_HASH := "7b9130bdf3d3ece6fd0bdc711a4028ad8613ebebabf58008a3603857720664bd"
const MAX_BYTES := 32*1024*1024
var path := "user://field-save.dat"
var error := ""

func layout(g: Node) -> String:
 return digest(var_to_bytes([g.grass.resolution,g.grass.field_origin,g.grass.field_size,g.grass.valid,g.infield.resolution,g.infield.field_origin,g.infield.field_size,g.infield.valid,g.moisture.target_moisture,g.chalk.line_start,g.chalk.line_end,g.chalk.section_length,g.chalk.chalk_width,g.chalk.valid,g.mound.patch_positions,g.mound.hits_required,g.mound.transform,g.mound.top_height,g.mound.patch_radius])).hex_encode()

func capture(g: Node,s: ShiftSession) -> Dictionary:
 var data := {"version":VERSION,"layout":layout(g),"grass":g.grass.image.get_data(),"dirt":g.infield.image.get_data(),"moisture":g.moisture.moisture.duplicate(),"chalk":g.chalk.covered.duplicate(),"strokes":g.chalk.stroke_archive.duplicate(true),"hits":g.mound.hits.duplicate(),"session":{"attempt_id":s.attempt_id,"phase":int(s.phase),"profile":s.profile_id,"elapsed":s.elapsed_seconds,"result":s.get_result(),"start_mode":s.start_mode,"wear_seed":s.wear_seed,"starting_counts":s.starting_counts.duplicate(),"work_totals":s.work_totals.duplicate(),"quality_enabled":s.quality_enabled}}
 data.merge({"puddles":g.moisture.puddle_time.duplicate(),"overwatered":g.moisture.overwatered.duplicate(),"ruts":g.infield.ruts.duplicate(),"offguide":g.chalk.offguide_metres,"stripe_samples":g.grass.stripe_samples,"stripe_matches":g.grass.stripe_matches})
 return data

func write(g: Node,s: ShiftSession) -> bool:
 error = ""
 var data := capture(g,s)
 if not validate(data,g):
  return false
 var bytes := var_to_bytes(data)
 if bytes.size() > MAX_BYTES:
  error = "Field is too large to save."
  return false
 var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null:
  error = "Could not open the save file."
  return false
 file.store_buffer("FPGCSAVE".to_ascii_buffer())
 file.store_buffer(digest(bytes))
 file.store_buffer(bytes)
 file.flush()
 var ok := file.get_error() == OK
 file.close()
 if not ok or DirAccess.rename_absolute(path+".tmp",path) != OK:
  error = "Could not replace the save. Previous save retained."
  return false
 return true

func read(g: Node) -> Dictionary:
 error = ""
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null:
  error = "No readable save found."
  return {}
 if file.get_length() > MAX_BYTES+40 or file.get_length() < 40:
  error = "Save is damaged or too large."
  return {}
 var magic := file.get_buffer(8).get_string_from_ascii()
 var checksum := file.get_buffer(32)
 var bytes := file.get_buffer(file.get_length()-40)
 file.close()
 if magic != "FPGCSAVE" or checksum != digest(bytes):
  error = "Save is damaged. Current field kept."
  return {}
 var data: Variant = migrate(bytes_to_var(bytes),g)
 if not validate(data,g):
  return {}
 return data

func migrate(data: Variant,g: Node) -> Dictionary:
 if not data is Dictionary:
  return {}
 if data.get("version") == VERSION:
  return data
 if data.get("version") not in [1,2]:
  return {}
 if data.version == 1 and (data.get("layout") != V1_CEDAR_HASH or layout(g) != V2_CEDAR_HASH):
  return {}
 if data.version == 2 and data.get("layout") != layout(g):
  return {}
 var candidate: Dictionary = data.duplicate(true)
 candidate.version = VERSION
 candidate.layout = layout(g)
 if not candidate.get("session") is Dictionary:
  return {}
 if not candidate.session.has("attempt_id"):
  candidate.session.attempt_id = "legacy-"+digest(var_to_bytes(data)).hex_encode()
 var zeros := PackedByteArray()
 zeros.resize(g.infield.valid.size())
 var timers := PackedFloat32Array()
 timers.resize(zeros.size())
 candidate.merge({"puddles":timers,"overwatered":zeros.duplicate(),"ruts":zeros.duplicate(),"offguide":0.0,"stripe_samples":0,"stripe_matches":0},true)
 candidate.session.merge({"start_mode":"fresh","wear_seed":0,"starting_counts":PackedInt64Array([0,0,0,0,0]),"work_totals":PackedInt64Array(g.shift.totals()),"quality_enabled":false},true)
 if not validate(candidate,g):
  return {}
 if data.version == 2:
  return candidate
 var reference := preload("res://resources/layouts/cedar_grove_v1_masks.res")
 var old := {"grass":reference.get_meta("grass"),"dirt":reference.get_meta("dirt")}
 if not old is Dictionary or not mask_data_ok(candidate.grass,old.grass) or not mask_data_ok(candidate.dirt,old.dirt):
  return {}
 for i in range(candidate.moisture.size()):
  if old.dirt[i] == 0 and candidate.moisture[i] != 0:
   return {}
 for key in ["grass","dirt"]:
  var current: PackedByteArray = g.grass.valid if key == "grass" else g.infield.valid
  var pixels: PackedByteArray = candidate[key]
  for i in range(current.size()):
   if current[i] == 1 and old[key][i] == 0:
    pixels[i*4] = 0
    pixels[i*4+1] = 128 if key == "dirt" else 0
    pixels[i*4+2] = 0
    pixels[i*4+3] = 255
  candidate[key] = pixels
 return candidate

func mask_ok(data: Variant,model: Node) -> bool:
 return mask_data_ok(data,model.valid)

func mask_data_ok(data: Variant,valid: PackedByteArray) -> bool:
 if not data is PackedByteArray or data.size() != valid.size()*4:
  return false
 for i in range(valid.size()):
  var red: int = data[i*4]
  if red not in [0,255] or (valid[i] == 0 and red != 0):
   return false
 return true

func validate(data: Variant,g: Node) -> bool:
 error = "Save is damaged or incompatible with this field."
 if not data is Dictionary:
  return false
 for key in ["version","layout","grass","dirt","moisture","chalk","strokes","hits","session"]:
  if not data.has(key):
   return false
 if data.version != VERSION or data.layout != layout(g):
  return false
 if not mask_ok(data.grass,g.grass) or not mask_ok(data.dirt,g.infield):
  return false
 if not data.moisture is PackedFloat32Array or data.moisture.size() != g.moisture.moisture.size():
  return false
 for i in range(data.moisture.size()):
  var value: float = data.moisture[i]
  if not is_finite(value) or value < 0 or value > 1 or (g.infield.valid[i] == 0 and value != 0):
   return false
 if not data.chalk is PackedByteArray or data.chalk.size() != g.chalk.valid.size():
  return false
 for i in range(data.chalk.size()):
  if data.chalk[i] > 1 or (g.chalk.valid[i] == 0 and data.chalk[i] != 0):
   return false
 if not data.strokes is Array or data.strokes.size() > 200000:
  return false
 for stroke in data.strokes:
  if not stroke is PackedVector3Array or stroke.size() != 4:
   return false
  for point in stroke:
   if not point.is_finite() or absf(point.x)>200 or absf(point.z)>200 or absf(point.y)>10:
    return false
 if not data.hits is PackedInt32Array or data.hits.size() != g.mound.hits.size():
  return false
 for hit in data.hits:
  if hit < 0 or hit > g.mound.hits_required:
   return false
 if not session_ok(data.session) or not work_ok(data.session,g) or not quality_state_ok(data,g):
  return false
 error = ""
 return true

func digest(bytes: PackedByteArray) -> PackedByteArray:
 var hash := HashingContext.new()
 hash.start(HashingContext.HASH_SHA256)
 hash.update(bytes)
 return hash.finish()

func number(value: Variant) -> bool:
 return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))

func session_ok(data: Variant) -> bool:
 if not data is Dictionary or not data.has_all(["phase","profile","elapsed","result"]):
  return false
 if data.has("attempt_id") and (not data.attempt_id is String or (not data.attempt_id.is_empty() and not CareerProfile.valid_id(data.attempt_id))):
  return false
 if typeof(data.phase) != TYPE_INT or data.phase not in [0,1,2] or not data.profile is String or not ShiftSession.PROFILES.has(data.profile):
  return false
 if data.has("attempt_id") and data.phase != ShiftSession.Phase.PRACTICE and data.attempt_id.is_empty():
  return false
 if not number(data.elapsed) or data.elapsed < 0 or data.elapsed > ShiftSession.PROFILES[data.profile].duration or not data.result is Dictionary:
  return false
 if data.phase == ShiftSession.Phase.PRACTICE:
  return data.elapsed == 0 and data.result.is_empty()
 if data.phase == ShiftSession.Phase.ACTIVE:
  return data.elapsed < ShiftSession.PROFILES[data.profile].duration and data.result.is_empty()
 var result: Dictionary = data.result
 if not result.has_all(["profile_id","reason","values","met"]) or result.profile_id != data.profile or result.reason not in ["completed","time_up","ended_early"]:
  return false
 if not result.values is Array or not result.met is Array:
  return false
 var check := ShiftSession.new()
 check.start(data.profile)
 check.quality_enabled = result.has("quality")
 var valid := check.set_progress(result.values,result.met)
 if check.quality_enabled:
  valid = valid and result.has_all(["coverage_score","job_quality","mowing_bonus","quality_tip"])
  if valid:
   valid = result.job_quality is Array and number(result.mowing_bonus) and check.set_quality(result.job_quality,result.mowing_bonus)
 if valid:
  check.elapsed_seconds = data.elapsed
  check.remaining_seconds = check.duration_seconds-data.elapsed
  valid = (result.reason != "completed" or check.jobs_completed() == check.jobs_required()) and (result.reason != "time_up" or check.remaining_seconds == 0)
  check.finish(result.reason)
  valid = valid and check.get_result() == result
 check.free()
 return valid

func restore(g: Node,director: ShiftDirector,data: Dictionary) -> bool:
 data = migrate(data,g)
 if not validate(data,g):
  return false
 director.reset_field()
 director.session.profile_id = data.session.profile
 director.configure_quality()
 restore_mask(g.grass,data.grass,"cut","cut_count")
 restore_mask(g.infield,data.dirt,"prepared","prepared_count")
 g.infield.replace_cells(g.infield.prepared,data.ruts)
 g.moisture.replace_moisture(data.moisture,data.puddles,data.overwatered)
 g.chalk.replace_strokes(data.strokes,data.chalk,data.offguide)
 g.mound.replace_hits(data.hits)
 g.grass.stripe_samples = data.stripe_samples
 g.grass.stripe_matches = data.stripe_matches
 var s := director.session
 s.attempt_id = data.session.get("attempt_id","legacy-"+digest(var_to_bytes(data)).hex_encode())
 s.phase = data.session.phase
 s.profile_id = data.session.profile
 s.duration_seconds = ShiftSession.PROFILES[s.profile_id].duration
 s.elapsed_seconds = data.session.elapsed
 s.remaining_seconds = s.duration_seconds-s.elapsed_seconds
 s.configure_work(Array(data.session.starting_counts),Array(data.session.work_totals),data.session.start_mode,data.session.wear_seed)
 s.quality_enabled = data.session.quality_enabled
 s._result = data.session.result.duplicate(true)
 director.collect_progress()
 s.changed.emit()
 g.update_progress(0)
 return true

func restore_mask(model: Node,bytes: PackedByteArray,flags_name: String,count_name: String) -> void:
 model.image = Image.create_from_data(model.resolution.x,model.resolution.y,false,Image.FORMAT_RGBA8,bytes)
 var flags: PackedByteArray = model.get(flags_name)
 var count := 0
 for i in range(flags.size()):
  flags[i] = 1 if bytes[i*4] == 255 else 0
  count += flags[i]
 model.set(flags_name,flags)
 model.set(count_name,count)
 model.texture.update(model.image)
 model.completion_changed.emit(model.percentage())

func work_ok(data: Dictionary,g: Node) -> bool:
 if not data.has_all(["start_mode","wear_seed","starting_counts","work_totals","quality_enabled"]):
  return false
 if data.start_mode not in ["fresh","game_day"] or typeof(data.quality_enabled) != TYPE_BOOL or typeof(data.wear_seed) != TYPE_INT or data.wear_seed < 0 or data.wear_seed > 0xffffffff:
  return false
 if not data.starting_counts is PackedInt64Array or not data.work_totals is PackedInt64Array or data.starting_counts.size() != 5 or data.work_totals != PackedInt64Array(g.shift.totals()):
  return false
 for i in range(5):
  if data.starting_counts[i] < 0 or data.starting_counts[i] > data.work_totals[i] or (data.start_mode == "fresh" and data.starting_counts[i] != 0):
   return false
 if data.start_mode == "game_day" and (not data.has("attempt_id") or data.wear_seed != data.attempt_id.sha256_buffer().decode_u32(0)):
  return false
 if data.start_mode == "fresh" and data.wear_seed != 0:
  return false
 if data.phase == ShiftSession.Phase.FINISHED and data.result.has("quality") != data.quality_enabled:
  return false
 return true

func quality_state_ok(data: Dictionary,g: Node) -> bool:
 if not data.has_all(["puddles","overwatered","ruts","offguide","stripe_samples","stripe_matches"]):
  return false
 if not data.puddles is PackedFloat32Array or not data.overwatered is PackedByteArray or not data.ruts is PackedByteArray:
  return false
 var count: int = g.infield.valid.size()
 if data.puddles.size() != count or data.overwatered.size() != count or data.ruts.size() != count:
  return false
 var rules := ShiftSession.quality_rules(data.session.profile)
 for i in range(count):
  var timer: float = data.puddles[i]
  if not is_finite(timer) or timer < 0 or timer > float(rules.puddle_seconds) or data.overwatered[i] > 1 or data.ruts[i] > 1:
   return false
  if g.infield.valid[i] == 0 and (timer != 0 or data.overwatered[i] != 0 or data.ruts[i] != 0):
   return false
  if timer > 0 and (data.moisture[i] < float(rules.puddle_threshold) or data.overwatered[i] != 1):
   return false
  if data.ruts[i] == 1 and data.dirt[i*4] != 255:
   return false
 if typeof(data.stripe_samples) != TYPE_INT or typeof(data.stripe_matches) != TYPE_INT or data.stripe_samples < 0 or data.stripe_samples > g.grass.total*4 or data.stripe_matches < 0 or data.stripe_matches > data.stripe_samples:
  return false
 if not number(data.offguide) or data.offguide < 0:
  return false
 var length := 0.0
 for stroke in data.strokes:
  var a: Vector3 = (stroke[0]+stroke[1])*0.5
  var b: Vector3 = (stroke[2]+stroke[3])*0.5
  length += Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
 return data.offguide <= length+maxf(0.01,length*0.0001)
