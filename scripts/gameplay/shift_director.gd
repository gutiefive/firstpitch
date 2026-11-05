class_name ShiftDirector
extends Node
var game: Node3D
var session: ShiftSession
var overlay: ShiftOverlay
var career := CareerProfile.new()
var career_message := ""
var standard_deck_width := 2.4
var standard_water_rate := 0.8
var standard_drag_width := 2.8
var wear := FieldWear.new()
var save_store := FieldSave.new()
var notice_sign: Label3D
var mouse_before_board := Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
 standard_deck_width = game.grass.deck_width
 standard_water_rate = game.moisture.application_rate
 standard_drag_width = game.mower.drag.working_width
 career.load_profile()
 career.changed.connect(apply_upgrades)
 apply_upgrades()
 session = ShiftSession.new()
 add_child(session)
 session.configure_work([0,0,0,0,0],totals())
 wear.prepare(game)
 overlay = ShiftOverlay.new()
 overlay.session = session
 overlay.director = self
 overlay.process_mode = Node.PROCESS_MODE_ALWAYS
 add_child(overlay)
 overlay.close_requested.connect(close_board)
 overlay.start_requested.connect(start_shift)
 overlay.end_requested.connect(end_shift)
 overlay.save_requested.connect(save_field)
 overlay.load_requested.connect(load_field)
 session.finished.connect(on_finished)
 session.changed.connect(refresh_condition)
 build_noticeboard()

func build_noticeboard() -> void:
 for x in [-1.2,1.2]:
  ParkGeometry.box(game,game.layout.noticeboard_position+Vector3(x,-0.65,0),Vector3(0.1,2,0.1),Color("28585a"))
 ParkGeometry.box(game,game.layout.noticeboard_position,Vector3(2.8,1.25,0.15),Color("eee3c6"))
 notice_sign = ParkGeometry.label(game,"CEDAR GROVE\nPREPARATION SHIFTS\nSHIFT BOARD",game.layout.noticeboard_position+Vector3(0,0,0.1),36)
 notice_sign.pixel_size = 0.005
 notice_sign.modulate = Color("28585a")

func counts() -> Array:
 return [game.grass.cut_count,game.infield.prepared_count,game.chalk.covered_count,game.moisture.wet_count,game.mound.work_done]

func totals() -> Array:
 return [game.grass.total,game.infield.total,game.chalk.valid_count,game.moisture.total,game.mound.total_work]

func configure_quality() -> void:
 var rules := ShiftSession.quality_rules(session.profile_id)
 game.grass.quality_rules = rules
 game.infield.quality_rules = rules
 game.moisture.quality_rules = rules

func collect_progress() -> void:
 var current := counts()
 var sizes := totals()
 var complete := []
 for i in range(5):
  complete.append(sizes[i] > 0 and current[i] == sizes[i])
 session.set_counts(current,complete)
 if not session.quality_enabled:
  session.set_quality([1.0,1.0,1.0,1.0,1.0])
  return
 var rules := ShiftSession.quality_rules(session.profile_id)
 var qualities := [1.0,1.0,1.0,1.0,1.0]
 var dragged := maxi(1,int(current[1])-session.starting_counts[1])
 var watered := maxi(1,int(current[3])-session.starting_counts[3])
 qualities[1] = maxf(float(rules.minimum),1-clampf(float(game.infield.rut_count)/dragged,0,1)*float(rules.rut_penalty))
 qualities[2] = maxf(float(rules.minimum),1-game.chalk.offguide_metres*float(rules.chalk_per_metre))
 qualities[3] = maxf(float(rules.minimum),1-clampf(float(game.moisture.overwatered_count)/watered,0,1)*float(rules.water_penalty))
 var bonus := 0.0
 if game.grass.stripe_samples >= int(rules.stripe_min_samples):
  bonus = float(rules.stripe_bonus)*game.grass.stripe_matches/maxi(1,game.grass.stripe_samples)
 session.set_quality(qualities,clampf(bonus,0,float(rules.stripe_bonus)))

func refresh_condition() -> void:
 game.hud.condition_label.visible = session.phase == ShiftSession.Phase.ACTIVE and bool(ShiftSession.PROFILES[session.profile_id].get("club",false))
 if game.hud.condition_label.visible:
  var brief: String = GameDay.info(session.profile_id).brief
  if session.profile_id == "home_rain":
   brief = "Standing water has drained. The dirt is ready to drag; no watering needed." if game.moisture.active_puddles.is_empty() else "Standing water is draining. Wait before dragging to avoid ruts."
  game.hud.condition_label.text = GameDay.info(session.profile_id).title+"\n"+brief+"\n"+GameDay.request_text(session.profile_id)

func _process(delta: float) -> void:
 refresh_condition()
 collect_progress()
 session.advance(delta)

func toggle_board() -> void:
 if overlay.modal.visible:
  close_board()
 else:
  open_board()

func open_board() -> void:
 if game.autosave != null:
  game.autosave.request()
 if not overlay.modal.visible:
  mouse_before_board = Input.mouse_mode
 collect_progress()
 game.tamper.cancel_swing()
 game.watering.spraying = false
 game.watering.droplets.visible = false
 Input.action_release("spray_water")
 Input.action_release("tamp_mound")
 overlay.refresh()
 overlay.modal.visible = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 get_tree().paused = true
 overlay.focus_current()

func close_board() -> void:
 if not overlay.modal.visible:
  return
 overlay.show_board()
 overlay.modal.visible = false
 Input.action_release("spray_water")
 Input.action_release("tamp_mound")
 get_tree().paused = false
 Input.mouse_mode = mouse_before_board

func end_shift() -> void:
 collect_progress()
 session.end_early()

func on_finished(result: Dictionary) -> void:
 var receipt := career.claim(session.attempt_id,result)
 career_message = receipt.message
 open_board()

func start_shift(profile: String) -> bool:
 if game.club != null and game.club.live != null and game.club.live.active:
  return false
 if game.autosave != null and not game.autosave.candidate.is_empty():
  return false
 if session.phase == ShiftSession.Phase.ACTIVE or not ShiftSession.PROFILES.has(profile):
  return false
 if ShiftSession.PROFILES[profile].get("club",false) and (not career.club_started() or not String(career.club.pending).is_empty()):
  return false
 if career.earned < int(ShiftSession.PROFILES[profile].get("minimum_earnings",0)):
  return false
 career_message = ""
 session.start(profile)
 configure_quality()
 var config: Dictionary = ShiftSession.PROFILES[profile]
 var mode: String = config.get("start","fresh")
 if mode == "game_day":
  reset_equipment()
  if wear.is_blank(game):
   wear.bootstrap(game,profile)
  var wear_seed_value := session.attempt_id.sha256_buffer().decode_u32(0)
  wear.apply(game,wear_seed_value,float(config.wear),profile)
  GameDay.apply_conditions(game,profile)
  game.infield.reset_quality()
  game.moisture.reset_quality()
  game.chalk.reset_quality()
  session.configure_work(counts(),totals(),mode,wear_seed_value)
 else:
  reset_field()
  session.configure_work([0,0,0,0,0],totals())
 collect_progress()
 if game.autosave != null:
  game.autosave.interval = 0
  game.autosave.request()
 for i in range(session.goals().size()):
  if session.goals()[i] > 0:
   game.selected_task = i
   break
 game.update_progress(0)
 mouse_before_board = Input.MOUSE_MODE_CAPTURED
 close_board()
 return true

func reset_equipment() -> void:
 if game.inspection != null:
  game.inspection.set_enabled(false)
 game.watering.set_equipped(false)
 game.tamper.set_equipped(false)
 game.tamper.dust_time = 1
 game.tamper.dust.visible = false
 game.mower.set_occupied(false)
 game.chalk_marker.set_occupied(false)
 game.driving = false
 game.pushing_chalk = false
 game.mower.speed = 0
 game.mower.velocity = Vector3.ZERO
 game.mower.position = game.layout.mower_spawn
 game.mower.rotation = Vector3(0,game.layout.mower_yaw,0)
 game.mower.set_tool(RidingMower.WorkTool.MOWER)
 game.mower.previous_deck = game.mower.deck.global_position
 game.mower.previous_drag = game.mower.drag.global_position
 game.chalk_marker.speed = 0
 game.chalk_marker.velocity = Vector3.ZERO
 game.chalk_marker.position = game.layout.chalk_marker_spawn
 game.chalk_marker.rotation = Vector3.ZERO
 game.chalk_marker.last_nozzle = game.chalk_marker.nozzle.global_position
 game.player.set_seated(false)
 game.player.velocity = Vector3.ZERO
 game.player.position = game.layout.player_spawn
 game.player.visual.rotation = Vector3.ZERO
 game.yaw = 0.12
 game.pitch = -0.45
 game.camera_distance = 8
 game.camera.current = true
 game.watering.camera = game.camera
 game.tamper.camera = game.camera
 game.pivot.global_position = game.player.global_position+Vector3.UP*1.5
 for action in ["forward","back","left","right","sprint","jump","brake","spray_water","tamp_mound"]:
  Input.action_release(action)
 if game.audio != null:
  game.audio.reset_tools()
 game.selected_task = 0

func reset_field() -> void:
 reset_equipment()
 game.grass.reset_state()
 game.infield.reset_state()
 game.moisture.reset_state()
 game.chalk.reset_state()
 game.mound.reset_state()
 game.update_progress(0)

func save_field() -> void:
 collect_progress()
 if save_store.write(game,session):
  overlay.save_message.text = "Saved snapshot. Save again after doing more work."
 else:
  overlay.save_message.text = save_store.error

func load_field() -> void:
 var data := save_store.read(game)
 var recovery_notice := save_store.error
 if data.is_empty() or not save_store.restore(game,self,data):
  overlay.save_message.text = save_store.error
  return
 career_message = "Loaded result. Rewards can be checked from Crew career." if session.phase == ShiftSession.Phase.FINISHED else ""
 mouse_before_board = Input.MOUSE_MODE_CAPTURED
 overlay.refresh()
 overlay.save_message.text = recovery_notice+" " if not recovery_notice.is_empty() else ""
 overlay.save_message.text += "Loaded. Equipment parked at workshop. Resume when ready."

func apply_upgrades() -> void:
 var wide := career.owns("wide_deck")
 var starter := career.club_started()
 game.grass.deck_width = standard_deck_width*1.25 if wide else (ClubProgress.STARTER_DECK if starter else standard_deck_width)
 game.mower.deck.scale.x = game.grass.deck_width/standard_deck_width
 game.tool_bay.spare_deck.scale.x = game.grass.deck_width/standard_deck_width
 game.moisture.application_rate = standard_water_rate*1.25 if career.owns("hose_nozzle") else (ClubProgress.STARTER_WATER if starter else standard_water_rate)
 var drag_width := standard_drag_width*float(CareerProfile.UPGRADES.wide_drag.width_multiplier) if career.owns("wide_drag") else (ClubProgress.STARTER_DRAG if starter else standard_drag_width)
 game.mower.drag.set_working_width(drag_width)
 game.tool_bay.parked_drag.set_working_width(drag_width)
 game.chalk_marker.set_guide_wheel(career.owns("guide_wheel"))

func retry_career() -> void:
 if career.load_profile() and session.phase == ShiftSession.Phase.FINISHED:
  var receipt := career.claim(session.attempt_id,session.get_result())
  career_message = receipt.message
 overlay.refresh()

func enter_practice() -> void:
 reset_field()
 session.phase = ShiftSession.Phase.PRACTICE
 session.attempt_id = ""
 session.elapsed_seconds = 0
 session.remaining_seconds = session.duration_seconds
 session._result.clear()
 session.quality_enabled = true
 session.configure_work([0,0,0,0,0],totals())
 collect_progress()
 session.changed.emit()
 if game.autosave != null:
  game.autosave.request()
