extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-wear-career.dat"
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 var wear: FieldWear = g.shift.wear
 wear.bootstrap(g,"full")
 g.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 var store := FieldSave.new()
 var pristine := store.capture(g,g.shift.session)
 check(wear.apply(g,27,0) == 0 and pristine == store.capture(g,g.shift.session),"zero intensity preserves every field and quality value")
 var ms := wear.apply(g,27,0.55)
 print("WEAR_GENERATION_MS=",ms)
 check(ms < 50,"seeded wear generation finishes below 50 ms")
 var first := store.capture(g,g.shift.session)
 var heavy_lost := 0
 var light_lost := 0
 var heavy_total := 0
 var light_total := 0
 for n in range(wear.dirt_indices.size()):
  var lost := int(g.infield.prepared[wear.dirt_indices[n]] == 0)
  if wear.dirt_heavy[n] == 1:
   heavy_total += 1
   heavy_lost += lost
  else:
   light_total += 1
   light_lost += lost
 check(float(heavy_lost)/heavy_total > float(light_lost)/light_total*3,"dirt damage concentrates in base lanes, batter area and middle-infield holes")
 check(g.grass.cut_count == 0 and g.grass.stripe_samples == 0,"game wear regrows grass and clears stripes")
 check(g.moisture.wet_count == 0 and g.moisture.moisture_at(Vector3(10,0,-10)) > 0,"drying recounts qualified flags while retaining dampness")
 check(g.chalk.covered_count < g.chalk.valid_count and g.chalk.stroke_archive.size() < pristine.strokes.size(),"chalk wear removes coverage and its visible quads together")
 check(g.mound.work_done < g.mound.total_work,"wear removes mound preparation hits")
 check(store.restore(g,g.shift,pristine),"prepared baseline restores before repeatability check")
 wear.apply(g,27,0.55)
 check(first == store.capture(g,g.shift.session),"identical seed and starting state produce identical wear")
 store.restore(g,g.shift,pristine)
 wear.apply(g,28,0.55)
 check(first.dirt != g.infield.image.get_data(),"different seeds produce different damage")
 store.restore(g,g.shift,pristine)
 check(g.shift.start_shift("full") and g.shift.session.start_mode == "game_day","full prep selects game-day mode")
 check(Array(g.shift.session.starting_counts) == g.shift.counts() and g.shift.session.values == PackedFloat64Array([0,0,0,0,0]),"game-day goals start at zero repair progress against worn counts")
 check(g.shift.session.wear_seed == g.shift.session.attempt_id.sha256_buffer().decode_u32(0),"wear seed derives from stable attempt identity")
 var point := Vector3(10,0,-10)
 var before: int = g.infield.prepared_count
 g.infield.paint(point,Vector3.FORWARD,4,4)
 var repaired: int = g.infield.prepared_count
 g.infield.paint(point,Vector3.FORWARD,4,4)
 check(repaired > before and g.infield.prepared_count == repaired,"worn cells can be reworked and count only once per attempt")
 g.moisture.spray_at(point,5)
 g.shift.collect_progress()
 var snapshot := store.capture(g,g.shift.session)
 check(store.validate(snapshot,g),"worn active field with puddles validates")
 store.path = "user://test-wear-field.dat"
 check(store.write(g,g.shift.session),"worn active field saves to disk")
 var disk := store.read(g)
 check(store.restore(g,g.shift,disk) and store.capture(g,g.shift.session) == snapshot,"round trip preserves seed, baselines, puddle timers and quality state without rerolling")
 var bad := snapshot.duplicate(true)
 bad.session.wear_seed += 1
 check(not store.validate(bad,g),"mismatched attempt seed is rejected")
 bad = snapshot.duplicate(true)
 bad.puddles[wear.dirt_indices[0]] = NAN
 check(not store.validate(bad,g),"nonfinite puddle state is rejected")
 # A version-2 snapshot has exactly the old keys; migration supplies neutral quality.
 var v2 := pristine.duplicate(true)
 v2.version = 2
 for key in ["puddles","overwatered","ruts","offguide","stripe_samples","stripe_matches"]:
  v2.erase(key)
 for key in ["start_mode","wear_seed","starting_counts","work_totals","quality_enabled"]:
  v2.session.erase(key)
 var migrated := store.migrate(v2,g)
 check(not migrated.is_empty() and migrated.version == 3 and not migrated.session.quality_enabled and migrated.session.start_mode == "fresh","v2 slot migrates as fresh with neutral quality")
 check(store.restore(g,g.shift,migrated) and g.infield.prepared_count == g.infield.total,"v2 migration preserves existing field work")
 g.shift.close_board()
 g.queue_free()
 await create_timer(0.15).timeout
 DirAccess.remove_absolute("user://test-wear-field.dat")
 DirAccess.remove_absolute("user://test-wear-career.dat")
 print("Field wear: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
