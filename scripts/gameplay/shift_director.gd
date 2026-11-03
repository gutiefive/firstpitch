class_name ShiftDirector
extends Node
var game: Node3D
var session: ShiftSession
var overlay: ShiftOverlay
var career := CareerProfile.new()
var career_message := ""
var standard_deck_width := 2.4
var standard_water_rate := 0.8
var save_store := FieldSave.new()
var mouse_before_board := Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
 standard_deck_width = game.grass.deck_width
 standard_water_rate = game.moisture.application_rate
 career.load_profile()
 career.changed.connect(apply_upgrades)
 apply_upgrades()
 session = ShiftSession.new()
 add_child(session)
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
 build_noticeboard()

func build_noticeboard() -> void:
 for x in [27.8,30.2]:
  ParkGeometry.box(game,Vector3(x,1,-3.4),Vector3(0.1,2,0.1),Color("28585a"))
 ParkGeometry.box(game,Vector3(29,1.65,-3.4),Vector3(2.8,1.25,0.15),Color("eee3c6"))
 var sign := ParkGeometry.label(game,"CEDAR GROVE\nPREPARATION SHIFTS\nTAB  SHIFT BOARD",Vector3(29,1.65,-3.3),36)
 sign.pixel_size = 0.005
 sign.modulate = Color("28585a")

func collect_progress() -> void:
 session.set_progress([game.grass.percentage(),game.infield.percentage(),game.chalk.percentage(),game.moisture.percentage(),game.mound.percentage()], [game.grass.total>0 and game.grass.cut_count==game.grass.total,game.infield.total>0 and game.infield.prepared_count==game.infield.total,game.chalk.valid_count>0 and game.chalk.covered_count==game.chalk.valid_count,game.moisture.total>0 and game.moisture.wet_count==game.moisture.total,game.mound.total_work>0 and game.mound.work_done==game.mound.total_work])

func _process(delta: float) -> void:
 collect_progress()
 session.advance(delta)

func toggle_board() -> void:
 if overlay.modal.visible:
  close_board()
 else:
  open_board()

func open_board() -> void:
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
 if session.phase == ShiftSession.Phase.ACTIVE or not ShiftSession.PROFILES.has(profile):
  return false
 if career.earned < int(ShiftSession.PROFILES[profile].get("minimum_earnings",0)):
  return false
 career_message = ""
 reset_field()
 session.start(profile)
 for i in range(session.goals().size()):
  if session.goals()[i] > 0:
   game.selected_task = i
   break
 game.update_progress(0)
 mouse_before_board = Input.MOUSE_MODE_CAPTURED
 close_board()
 return true

func reset_field() -> void:
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
 game.mower.position = Vector3(30,0.1,-19)
 game.mower.rotation = Vector3(0,PI/4,0)
 game.mower.set_tool(RidingMower.WorkTool.MOWER)
 game.mower.previous_deck = game.mower.deck.global_position
 game.mower.previous_drag = game.mower.drag.global_position
 game.chalk_marker.speed = 0
 game.chalk_marker.velocity = Vector3.ZERO
 game.chalk_marker.position = Vector3(38,0.05,-21)
 game.chalk_marker.rotation = Vector3.ZERO
 game.chalk_marker.last_nozzle = game.chalk_marker.nozzle.global_position
 game.player.set_seated(false)
 game.player.velocity = Vector3.ZERO
 game.player.position = Vector3(29,0.1,-11)
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
 game.grass.reset_state()
 game.infield.reset_state()
 game.moisture.reset_state()
 game.chalk.reset_state()
 game.mound.reset_state()
 if game.audio != null:
  game.audio.reset_tools()
 game.selected_task = 0
 game.update_progress(0)

func save_field() -> void:
 collect_progress()
 if save_store.write(game,session):
  overlay.save_message.text = "Saved snapshot. Save again after doing more work."
 else:
  overlay.save_message.text = save_store.error

func load_field() -> void:
 var data := save_store.read(game)
 if data.is_empty() or not save_store.restore(game,self,data):
  overlay.save_message.text = save_store.error
  return
 career_message = "Loaded result. Rewards can be checked from Crew career." if session.phase == ShiftSession.Phase.FINISHED else ""
 mouse_before_board = Input.MOUSE_MODE_CAPTURED
 overlay.refresh()
 overlay.save_message.text = "Loaded. Equipment parked at workshop. Resume when ready."

func apply_upgrades() -> void:
 var wide := career.owns("wide_deck")
 game.grass.deck_width = standard_deck_width*1.25 if wide else standard_deck_width
 game.mower.deck.scale.x = 1.25 if wide else 1.0
 game.tool_bay.spare_deck.scale.x = 1.25 if wide else 1.0
 game.moisture.application_rate = standard_water_rate*1.25 if career.owns("hose_nozzle") else standard_water_rate

func retry_career() -> void:
 if career.load_profile() and session.phase == ShiftSession.Phase.FINISHED:
  var receipt := career.claim(session.attempt_id,session.get_result())
  career_message = receipt.message
 overlay.refresh()
