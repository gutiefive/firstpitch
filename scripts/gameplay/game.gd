extends Node3D
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
var player: Groundskeeper
var mower: RidingMower
var grass: MowingGrass
var camera: Camera3D
var pivot: Node3D
var boom: SpringArm3D
var yaw := 0.12
var pitch := -0.45
var camera_distance := 8.0
var mode_label: Label
var prompt: Label
var percent_label: Label
var progress: ProgressBar
var driving := false
var infield: InfieldSurface
var tool_bay: ToolBay
var hud: GroundsHUD
var chalk: ChalkSystem
var chalk_marker: ChalkMarker
var chalk_marker_sign: Label3D
var pushing_chalk := false
var selected_task := 0
var moisture: DirtMoisture
var watering: WateringTool
var mound: MoundSurface
var tamper: TampingTool
@export var career_save_path := "user://career.dat"
var audio: GroundsAudio
var shift: ShiftDirector
@export var settings_save_path := "user://settings.cfg"
@export var autosave_save_path := "user://field-autosave.dat"
@export var tutorial_enabled := true
@export var autosave_enabled := true
var settings := CrewSettings.new()
var stadium: Node3D
var club: ClubDirector
var input_device: CrewInput
var tutorial: CrewTutorial
var autosave: CrewAutosave
var inspection: CrewInspection
func binding_text(action: String) -> String:
 return input_device.binding_text(action)

func _ready() -> void:
 configure_input()
 settings.path = settings_save_path
 settings.load_settings()
 input_device = CrewInput.new()
 input_device.game = self
 stadium = preload("res://scenes/stadium/stadium.tscn").instantiate()
 stadium.layout = layout
 add_child(stadium)
 add_child(input_device)
 mound = preload("res://scenes/environment/mound_repairs.tscn").instantiate()
 mound.layout = layout
 add_child(mound)
 infield = preload("res://scenes/environment/infield.tscn").instantiate()
 infield.layout = layout
 add_child(infield)
 infield.apply_to(stadium.infield_surfaces)
 moisture = preload("res://scenes/environment/dirt_moisture.tscn").instantiate()
 add_child(moisture)
 moisture.bind_surface(infield)
 tool_bay = ToolBay.new()
 tool_bay.layout = layout
 add_child(tool_bay)
 grass = preload("res://scenes/environment/grass.tscn").instantiate()
 grass.layout = layout
 add_child(grass)
 player = preload("res://scenes/player/player.tscn").instantiate()
 player.position = layout.player_spawn
 add_child(player)
 mower = preload("res://scenes/vehicles/mower.tscn").instantiate()
 mower.position = layout.mower_spawn
 mower.rotation.y = layout.mower_yaw
 mower.layout = layout
 add_child(mower)
 mower.grass = grass
 mower.infield = infield
 chalk = ChalkSystem.new()
 chalk.layout = layout
 add_child(chalk)
 chalk_marker = preload("res://scenes/vehicles/chalk_marker.tscn").instantiate()
 chalk_marker.position = layout.chalk_marker_spawn
 add_child(chalk_marker)
 chalk_marker.chalk = chalk
 chalk_marker_sign = ParkGeometry.label(self,"CHALK MARKER\nUSE / GATE",layout.chalk_marker_sign,34)
 chalk_marker_sign.pixel_size = 0.005

 pivot = Node3D.new()
 pivot.position = player.position+Vector3.UP*1.5
 add_child(pivot)
 boom = SpringArm3D.new()
 boom.spring_length = camera_distance
 boom.margin = 0.3
 boom.add_excluded_object(player.get_rid())
 boom.add_excluded_object(mower.get_rid())
 boom.add_excluded_object(chalk_marker.get_rid())
 pivot.add_child(boom)
 camera = Camera3D.new()
 camera.current = true
 camera.fov = 65
 camera.near = 0.25
 camera.far = 400
 boom.add_child(camera)
 watering = preload("res://scenes/environment/water_station.tscn").instantiate()
 watering.player = player
 watering.camera = camera
 watering.moisture = moisture
 watering.surface_height = layout.ground_height
 watering.layout = layout
 add_child(watering)
 tamper = preload("res://scenes/environment/tamper_rack.tscn").instantiate()
 tamper.player = player
 tamper.camera = camera
 tamper.mound = mound
 tamper.layout = layout
 add_child(tamper)
 create_hud()
 grass.completion_changed.connect(update_progress)
 infield.completion_changed.connect(update_progress)
 chalk.completion_changed.connect(update_progress)
 moisture.completion_changed.connect(update_progress)
 watering.equipped_changed.connect(on_watering_changed)
 tamper.equipped_changed.connect(on_tamper_changed)
 mound.completion_changed.connect(update_progress)
 mower.tool_changed.connect(on_tool_changed)
 shift = ShiftDirector.new()
 shift.game = self
 shift.career.path = career_save_path
 add_child(shift)
 audio = GroundsAudio.new()
 audio.game = self
 add_child(audio)
 shift.overlay.attach_audio(audio)
 watering.binding_query = binding_text
 tamper.binding_query = binding_text
 input_device.device_changed.connect(refresh_bindings)
 refresh_bindings()
 watering.capture_query = input_device.aim_allowed
 tamper.capture_query = input_device.aim_allowed
 tutorial = CrewTutorial.new()
 tutorial.game = self
 add_child(tutorial)
 autosave = CrewAutosave.new()
 autosave.game = self
 autosave.store.path = autosave_save_path
 add_child(autosave)
 inspection = CrewInspection.new()
 inspection.game = self
 add_child(inspection)
 club = ClubDirector.new()
 club.game = self
 add_child(club)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func configure_input() -> void:
 CrewInput.configure_input()

func _input(event: InputEvent) -> void:
 # Captured tool clicks must not be swallowed by the noninteractive reticle HUD.
 if club != null and club.live != null and club.live.active:
  return
 if not get_tree().paused and tamper != null and tamper.equipped and event.is_action_pressed("tamp_mound"):
  tamper.request_tamp()


func _unhandled_input(event: InputEvent) -> void:
 if get_tree().paused:
  return
 if event is InputEventKey and event.echo:
  return
 if event.is_action_pressed("shift_board"):
  shift.toggle_board()
  return
 if event.is_action_pressed("cursor_menu"):
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  yaw -= event.relative.x*0.003
  pitch = clampf(pitch-event.relative.y*0.003,-1.1,0.1)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP:
   camera_distance = maxf(3,camera_distance-0.7)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   camera_distance = minf(18,camera_distance+0.7)
 if club != null and club.live != null and club.live.active:
  return
 if event.is_action_pressed("interact"):
  interact()
 if event.is_action_pressed("mound_tool") and not driving and not pushing_chalk:
  tamper.toggle_equipped()
 if event.is_action_pressed("water_tool") and not driving and not pushing_chalk:
  watering.toggle_equipped()
 if event.is_action_pressed("swap_tool"):
  swap_work_tool()
 if event.is_action_pressed("lift_drag"):
  if pushing_chalk:
   chalk_marker.toggle_gate()
  else:
   mower.toggle_drag()

func place_player_beside(actor: CharacterBody3D,clearance: float) -> bool:
 for side in [1.0,-1.0]:
  var exit_pos: Vector3 = actor.global_position+actor.global_basis.x*side*clearance+Vector3.UP*0.2
  var query := PhysicsShapeQueryParameters3D.new()
  query.shape = player.get_child(0).shape
  query.transform = Transform3D(Basis.IDENTITY,exit_pos+Vector3.UP*0.9)
  query.exclude = [player.get_rid(),actor.get_rid()]
  if get_world_3d().direct_space_state.intersect_shape(query).is_empty():
   player.global_position = exit_pos
   player.set_seated(false)
   return true
 return false

func near_chalk_marker() -> bool:
 var distance := player.global_position.distance_to(chalk_marker.global_position)
 return distance < 2.6 and distance < player.global_position.distance_to(mower.global_position)

func interact() -> void:
 if club != null and club.live != null and club.live.active:
  club.live.interact_job()
  return
 if pushing_chalk:
  if chalk_marker.can_exit() and place_player_beside(chalk_marker,1.3):
   chalk_marker.set_occupied(false)
   pushing_chalk = false
  return
 if driving:
  if mower.can_exit() and place_player_beside(mower,2.3):
   mower.set_occupied(false)
   driving = false
  return
 if near_chalk_marker():
  watering.set_equipped(false)
  tamper.set_equipped(false)
  player.set_seated(true)
  chalk_marker.set_occupied(true)
  pushing_chalk = true
  selected_task = 2
  update_progress(0)
 elif player.global_position.distance_to(mower.global_position) < 3.5:
  watering.set_equipped(false)
  tamper.set_equipped(false)
  player.set_seated(true)
  mower.set_occupied(true)
  driving = true
  selected_task = 1 if mower.active_tool == RidingMower.WorkTool.DRAG else 0
  update_progress(0)

func swap_work_tool() -> bool:
 if driving or pushing_chalk or watering.equipped or tamper.equipped or not mower.can_exit() or not tool_bay.contains(mower.global_position):
  return false
 if player.global_position.distance_to(mower.global_position) >= 3.5:
  return false
 var next_tool := RidingMower.WorkTool.DRAG if mower.active_tool == RidingMower.WorkTool.MOWER else RidingMower.WorkTool.MOWER
 return mower.set_tool(next_tool)

func on_watering_changed(equipped: bool) -> void:
 if equipped:
  selected_task = 3
  tamper.set_equipped(false)
 update_progress(0)

func on_tamper_changed(equipped: bool) -> void:
 if equipped:
  selected_task = 4
  watering.set_equipped(false)
 update_progress(0)

func refresh_mound_detail() -> void:
 var text := "PATCHES %d/%d REPAIRED" % [mound.repaired_count,mound.hits.size()]
 if tamper.equipped and tamper.target_index >= 0:
  text += "  /  AIM %d/%d" % [mound.hits[tamper.target_index],mound.hits_required]
 hud.detail_label.text = text

func on_tool_changed(_tool: int) -> void:
 selected_task = 1 if mower.active_tool == RidingMower.WorkTool.DRAG else 0
 tool_bay.show_equipped_drag(mower.active_tool == RidingMower.WorkTool.DRAG)
 update_progress(0)

func _process(delta: float) -> void:
 if player == null:
  return
 player.yaw = yaw
 var target := mower.global_position+Vector3.UP*1.8 if driving else player.global_position+Vector3.UP*1.5
 if pushing_chalk:
  target = chalk_marker.global_position+Vector3.UP*1.3
 if tamper.equipped:
  target = player.global_position+Vector3.UP*0.8
 pivot.global_position = pivot.global_position.lerp(target,1-exp(-7*delta))
 pivot.rotation = Vector3(pitch,yaw,0)
 boom.spring_length = lerpf(boom.spring_length,camera_distance,1-exp(-8*delta))
 var dragging := mower.active_tool == RidingMower.WorkTool.DRAG
 hud.reticle.visible = watering.equipped or tamper.equipped
 if tamper.equipped:
  mode_label.text = "MOUND REPAIR  /  " + tamper.feedback
  hud.reticle.modulate = Color("dfb862")
  if tamper.target_index >= 0 and mound.hits[tamper.target_index] >= mound.hits_required:
   hud.reticle.modulate = Color("83c4cf")
  refresh_mound_detail()
 elif watering.equipped:
  mode_label.text = "WATERING  /  " + watering.feedback
  if watering.target_valid and moisture.puddle_at(watering.target):
   mode_label.text = "OVERWATERING — LET PUDDLE DRY"
  hud.reticle.modulate = Color("c3b996")
  if watering.target_valid and moisture.is_workable(watering.target):
   hud.reticle.modulate = Color("83c4cf") if moisture.moisture_at(watering.target) >= moisture.target_moisture else Color("e1bb67")
 elif pushing_chalk:
  mode_label.text = "CHALKING  /  " + ("GATE OPEN" if chalk_marker.gate_open else "GATE CLOSED")
  if chalk_marker.gate_open and chalk.distance_to_guide(chalk_marker.nozzle.global_position) > chalk.chalk_width*0.5:
   mode_label.text = "CHALKING  /  OFF GUIDE — NO LINE CREDIT"
  if chalk_marker.guide_active:
   mode_label.text += " / GUIDE WHEEL"
 elif not driving:
  mode_label.text = "ON FOOT  /  " + ("TAMPER STOWED" if selected_task == 4 else ("HOSE STOWED" if selected_task == 3 else ("CHALK MARKER PARKED" if selected_task == 2 else ("DRAG EQUIPPED" if dragging else "MOWER EQUIPPED"))))
 elif dragging:
  mode_label.text = "DRAGGING  /  " + ("LOWERED" if mower.drag.lowered else "RAISED")
  if mower.drag.lowered and mower.speed > 0.15 and infield.wet_dragging:
   mode_label.text = "DRAGGING WET DIRT — RUTS"
  elif mower.drag.lowered and mower.speed > 0.15 and infield.blocked_puddles:
   mode_label.text = "PUDDLES — WAIT BEFORE DRAGGING"
  elif mower.drag.lowered and mower.speed < -0.15:
   mode_label.text = "DRAGGING  /  REVERSE — NO PREPARATION"
 else:
  mode_label.text = "MOWING  /  DECK ENGAGED"
 if tamper.equipped:
  prompt.text = "{move} walk  •  Aim worn clay  •  Stop + press {tamp} to tamp  •  {mound} stow tamper"
 elif watering.equipped:
  prompt.text = "{move} walk  •  Aim with {look}  •  Hold {spray} to water  •  {water} stow hose  •  {cursor} cursor"
 elif pushing_chalk:
  prompt.text = "{move} push / steer  •  {lift} chalk gate  •  {brake} brake  •  " + ("{interact} leave marker" if chalk_marker.can_exit() else "Stop to leave marker")
 elif driving and dragging:
  if mower.drag.lowered:
   prompt.text = "{move} drive  •  {lift} raise drag  •  {brake} brake  •  " + ("{interact} exit" if mower.can_exit() else "Stop to exit")
  else:
   prompt.text = "{move} drive  •  Stop + {lift} lower drag  •  {brake} brake  •  {interact} exit when stopped"
 elif driving:
  prompt.text = "{move} drive  •  {brake} brake  •  {interact} exit" if mower.can_exit() else "{move} drive  •  {brake} brake  •  Stop to exit"
 elif near_chalk_marker():
  prompt.text = "{interact} use chalk marker  •  Follow the dashed gold foul-line guides"
 elif player.global_position.distance_to(mower.global_position) < 3.5:
  prompt.text = "{interact} enter tractor  •  {swap} swap mower / drag" if tool_bay.contains(mower.global_position) else "{interact} enter tractor  •  Return to tool bay to swap equipment"
 elif player.global_position.distance_to(tamper.rack_position) <= tamper.pickup_distance:
  prompt.text = "{mound} take tamper  •  Repair worn clay patches on the pitcher’s mound"
 elif player.global_position.distance_to(watering.station_position) <= watering.pickup_distance:
  prompt.text = "{water} take hose  •  Water the workable infield dirt"
 else:
  prompt.text = "{move} walk  •  {sprint} sprint  •  {jump} jump  •  Find equipment beside the workshop"

 prompt.text = prompt.text.format({"move":binding_text("move"),"sprint":binding_text("sprint"),"brake":binding_text("brake"),"jump":binding_text("jump"),"tamp":binding_text("tamp_mound"),"spray":binding_text("spray_water"),"cursor":binding_text("cursor_menu"),"interact":binding_text("interact"),"swap":binding_text("swap_tool"),"lift":binding_text("lift_drag"),"water":binding_text("water_tool"),"mound":binding_text("mound_tool"),"look":"right stick" if input_device.last_input_device == "pad" else "mouse"})
 hud.reminder.text = "%s  Shift board / pause\n%s  Camera   %s  Cursor / back" % [binding_text("shift_board"),"Right stick" if input_device.last_input_device == "pad" else "Mouse / scroll",binding_text("cursor_menu")]
 hud.reminder.text += "\n%s Inspect field · %s / %s Jobs" % [binding_text("inspect_field"),binding_text("previous_job"),binding_text("next_job")]

func create_hud() -> void:
 hud = GroundsHUD.new()
 add_child(hud)
 mode_label = hud.mode_label
 prompt = hud.prompt
 percent_label = hud.percent_label
 progress = hud.progress
 update_progress(0)

func update_progress(_value: float) -> void:
 if inspection != null and inspection.is_node_ready():
  inspection.refresh_selection()
 var mowing := grass.percentage()
 var dirt := infield.percentage()
 var lining := chalk.percentage()
 var water := moisture.percentage()
 var repairs := mound.percentage()
 var completed := [grass.total > 0 and grass.cut_count == grass.total,infield.total > 0 and infield.prepared_count == infield.total,chalk.valid_count > 0 and chalk.covered_count == chalk.valid_count,moisture.total > 0 and moisture.wet_count == moisture.total,mound.total_work > 0 and mound.work_done == mound.total_work]
 var values := [mowing,dirt,lining,water,repairs]
 var objectives := ["Mow the outfield","Drag the infield dirt","Chalk both foul lines","Water the infield dirt","Repair the pitcher’s mound"]
 var value: float = values[selected_task]
 hud.objective_label.text = objectives[selected_task]
 hud.summary_label.text = "MOW %.0f%% / DRAG %.0f%% / CHALK %.0f%%\nWATER %.0f%% / MOUND %.0f%%" % [mowing,dirt,lining,water,repairs]
 if selected_task == 4:
  refresh_mound_detail()
 elif selected_task == 2:
  hud.detail_label.text = "LEFT %.1f%%  /  RIGHT %.1f%%" % [chalk.line_percentage(0),chalk.line_percentage(1)]
 elif selected_task == 3:
  hud.detail_label.text = "Hold to soak · %.0f m hose / %.0f m spray" % [watering.hose_reach,watering.spray_reach]
  if watering.equipped and watering.target_valid:
   hud.detail_label.text = "AIM %.0f%% / TARGET %.0f%% MOISTURE" % [moisture.moisture_at(watering.target)*100,moisture.target_moisture*100]
 else:
  hud.detail_label.text = ""
 progress.value = value
 percent_label.text = "%.2f%%" % minf(value,99.99)
 if completed[selected_task]:
  percent_label.text = "COMPLETE"
 if completed[0] and completed[1] and completed[2] and completed[3] and completed[4]:
  hud.objective_label.text = "PARK READY — All five tasks complete"

func refresh_bindings() -> void:
 chalk_marker_sign.text = "CHALK MARKER\n%s USE / %s GATE" % [binding_text("interact"),binding_text("lift_drag")]
 tool_bay.placard.text = "TOOL BAY\n%s SWAP MOWER / DRAG" % binding_text("swap_tool")
 watering.placard.text = "WATER STATION\n%s TAKE / STOW HOSE" % binding_text("water_tool")
 tamper.placard.text = "MOUND REPAIR\n%s TAKE / STOW TAMPER" % binding_text("mound_tool")
 shift.notice_sign.text = "CEDAR GROVE\nPREPARATION SHIFTS\n%s SHIFT BOARD" % binding_text("shift_board")
 shift.overlay.refresh()
