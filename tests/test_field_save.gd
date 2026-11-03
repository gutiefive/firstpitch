extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
 else:
  print("PASS: ",message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 root.add_child(g)
 for i in range(5):
  await physics_frame
 var store := FieldSave.new()
 store.path = "user://test-field-save.dat"
 if FileAccess.file_exists(store.path):
  DirAccess.remove_absolute(store.path)
 check(store.read(g).is_empty(),"missing save leaves scene intact")
 g.shift.open_board()
 g.shift.start_shift("training")
 g.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 g.infield.paint(Vector3(10,0,-10),Vector3.RIGHT,2.8,1.2)
 g.moisture.spray_at(Vector3(10,0,-10),1.3)
 g.chalk.paint_segment(Vector3(4,0,-4),Vector3(8,0,-8))
 g.chalk.paint_segment(Vector3(15,0,-5),Vector3(17,0,-5))
 g.mound.apply_tamp(0)
 g.mound.apply_tamp(1)
 g.mound.apply_tamp(1)
 g.mound.apply_tamp(1)
 g.shift.session.advance(123.4)
 g.shift.open_board()
 var saved := store.capture(g,g.shift.session)
 check(store.validate(saved,g),"mixed real work validates before texture flush")
 check(store.write(g,g.shift.session),"manual save writes to disk")
 check(store.write(g,g.shift.session),"existing slot can be atomically replaced")
 var loaded := store.read(g)
 check(not loaded.is_empty() and loaded.grass == saved.grass,"disk round trip preserves grass direction bytes")
 g.shift.reset_field()
 check(store.restore(g,g.shift,loaded),"validated save restores real scene")
 check(g.grass.cut_count > 0 and g.infield.prepared_count > 0 and g.moisture.wet_count > 0 and g.chalk.covered_count > 0 and g.mound.work_done == 4,"all five independent job counters return")
 check(g.grass.image.get_data() == saved.grass and g.infield.image.get_data() == saved.dirt,"mowing and dragging appearance round trips exactly")
 check(g.moisture.moisture == saved.moisture and g.mound.hits == saved.hits,"partial moisture and per-patch impacts survive")
 check(g.chalk.stroke_archive == saved.strokes and g.chalk.get_child_count() > 1,"on-guide and off-guide chalk meshes rebuilt")
 check(paused and g.shift.session.phase == ShiftSession.Phase.ACTIVE and is_equal_approx(g.shift.session.remaining_seconds,776.6),"active clock restored without advancing while paused")
 check(not g.driving and not g.pushing_chalk and not g.watering.equipped and not g.tamper.equipped and g.mower.speed == 0,"load parks and stows equipment")
 var before := store.capture(g,g.shift.session)
 var bad := loaded.duplicate(true)
 bad.version = 999
 check(not store.restore(g,g.shift,bad) and store.capture(g,g.shift.session) == before,"unsupported version rejected before scene mutation")
 bad = loaded.duplicate(true)
 bad.layout = "different-field"
 check(not store.restore(g,g.shift,bad),"changed field layout rejected")
 bad = loaded.duplicate(true)
 bad.moisture[0] = NAN
 check(not store.restore(g,g.shift,bad),"nonfinite moisture rejected")
 bad = loaded.duplicate(true)
 bad.chalk.resize(1)
 check(not store.restore(g,g.shift,bad),"wrong mask size rejected")
 bad = loaded.duplicate(true)
 bad.grass[0] = 255
 check(not store.restore(g,g.shift,bad),"protected grass cells cannot gain saved credit")
 bad = loaded.duplicate(true)
 bad.session.elapsed = -1
 check(not store.restore(g,g.shift,bad),"invalid clock rejected")
 bad = loaded.duplicate(true)
 bad.strokes = [PackedVector3Array([Vector3.ZERO])]
 check(not store.restore(g,g.shift,bad),"invalid chalk geometry rejected")
 g.shift.end_shift()
 var result: Dictionary = g.shift.session.get_result()
 g.grass.paint(Vector3(0,0,-70),Vector3.RIGHT)
 check(store.write(g,g.shift.session),"finished result and later practice can be saved together")
 var result_save := store.read(g)
 check(store.restore(g,g.shift,result_save) and g.shift.session.get_result() == result,"frozen result survives later practice and load")
 bad = result_save.duplicate(true)
 bad.session.result.score = 100
 check(not store.restore(g,g.shift,bad),"inconsistent result score rejected")
 var file := FileAccess.open(store.path,FileAccess.READ_WRITE)
 file.seek(45)
 file.store_8(255)
 file.close()
 check(store.read(g).is_empty(),"checksum catches damaged payload before decoding")
 file = FileAccess.open(store.path,FileAccess.WRITE)
 file.store_buffer(PackedByteArray([0,1,2,3]))
 file.close()
 check(store.read(g).is_empty() and g.shift.session.get_result() == result,"truncated file leaves existing result intact")
 g.shift.session.phase = ShiftSession.Phase.PRACTICE
 g.shift.session.elapsed_seconds = 0
 g.shift.session._result.clear()
 check(store.write(g,g.shift.session) and store.restore(g,g.shift,store.read(g)) and g.shift.session.phase == ShiftSession.Phase.PRACTICE,"untimed practice work round trips")
 g.shift.session.start("full")
 g.shift.session.advance(1800)
 check(store.write(g,g.shift.session) and store.restore(g,g.shift,store.read(g)) and g.shift.session.get_result().reason == "time_up","timeout result round trips")
 g.shift.session.start("training")
 g.shift.session.set_progress([100,100,100,100,100],[true,true,true,true,true])
 g.shift.session.advance(1)
 check(store.write(g,g.shift.session) and store.restore(g,g.shift,store.read(g)) and g.shift.session.get_result().score == 100,"completed result fixture round trips")
 store.path = "user://missing-directory/slot.dat"
 check(not store.write(g,g.shift.session),"write failure is reported")
 DirAccess.remove_absolute("user://test-field-save.dat")
 paused = false
 g.queue_free()
 await create_timer(0.1).timeout
 print("Field save: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
