class_name FieldSave
extends RefCounted
# Resource-free Variant data only. Validate the complete snapshot before mutation.
const VERSION := 1
const MAX_BYTES := 32*1024*1024
var path := "user://field-save.dat"
var error := ""

func layout(g: Node) -> String:
 return digest(var_to_bytes([g.grass.resolution,g.grass.field_origin,g.grass.field_size,g.grass.valid,g.infield.resolution,g.infield.field_origin,g.infield.field_size,g.infield.valid,g.moisture.target_moisture,g.chalk.line_start,g.chalk.line_end,g.chalk.section_length,g.chalk.chalk_width,g.chalk.valid,g.mound.patch_positions,g.mound.hits_required,g.mound.transform,g.mound.top_height,g.mound.patch_radius])).hex_encode()

func capture(g: Node,s: ShiftSession) -> Dictionary:
 return {"version":VERSION,"layout":layout(g),"grass":g.grass.image.get_data(),"dirt":g.infield.image.get_data(),"moisture":g.moisture.moisture.duplicate(),"chalk":g.chalk.covered.duplicate(),"strokes":g.chalk.stroke_archive.duplicate(true),"hits":g.mound.hits.duplicate(),"session":{"phase":int(s.phase),"profile":s.profile_id,"elapsed":s.elapsed_seconds,"result":s.get_result()}}

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
 var data: Variant = bytes_to_var(bytes)
 if not validate(data,g):
  return {}
 return data

func mask_ok(data: Variant,model: Node) -> bool:
 if not data is PackedByteArray or data.size() != model.image.get_data_size():
  return false
 for i in range(model.valid.size()):
  var red: int = data[i*4]
  if red not in [0,255] or (model.valid[i] == 0 and red != 0):
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
 if not session_ok(data.session):
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
 if typeof(data.phase) != TYPE_INT or data.phase not in [0,1,2] or not data.profile is String or not ShiftSession.PROFILES.has(data.profile):
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
 var valid := check.set_progress(result.values,result.met)
 if valid:
  check.elapsed_seconds = data.elapsed
  check.remaining_seconds = check.duration_seconds-data.elapsed
  valid = (result.reason != "completed" or check.jobs_completed() == 5) and (result.reason != "time_up" or check.remaining_seconds == 0)
  check.finish(result.reason)
  valid = valid and check.get_result() == result
 check.free()
 return valid

func restore(g: Node,director: ShiftDirector,data: Dictionary) -> bool:
 if not validate(data,g):
  return false
 director.reset_field()
 restore_mask(g.grass,data.grass,"cut","cut_count")
 restore_mask(g.infield,data.dirt,"prepared","prepared_count")
 g.moisture.moisture = data.moisture.duplicate()
 for i in range(data.moisture.size()):
  var value: float = data.moisture[i]
  if value >= g.moisture.target_moisture:
   g.moisture.watered[i] = 1
   g.moisture.wet_count += 1
  g.moisture.image.set_pixel(i%g.infield.resolution.x,i/g.infield.resolution.x,Color(value,0,0,1))
 g.moisture.texture.update(g.moisture.image)
 g.chalk.covered = data.chalk.duplicate()
 for i in range(data.chalk.size()):
  if data.chalk[i] == 1:
   g.chalk.covered_count += 1
   g.chalk.line_counts[i/g.chalk.sections_per_line] += 1
 for stroke in data.strokes:
  g.chalk.stroke_archive.append(stroke.duplicate())
  g.chalk.pending.append(stroke.duplicate())
 g.chalk.flush_visuals()
 for i in range(data.hits.size()):
  for hit in range(data.hits[i]):
   g.mound.apply_tamp(i)
 var s := director.session
 s.phase = data.session.phase
 s.profile_id = data.session.profile
 s.duration_seconds = ShiftSession.PROFILES[s.profile_id].duration
 s.elapsed_seconds = data.session.elapsed
 s.remaining_seconds = s.duration_seconds-s.elapsed_seconds
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
