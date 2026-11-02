extends Node3D
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
var pushing_chalk := false
var selected_task := 0

func _ready() -> void:
 configure_input()
 var stadium = preload("res://scenes/stadium/stadium.tscn").instantiate()
 add_child(stadium)
 infield = preload("res://scenes/environment/infield.tscn").instantiate()
 add_child(infield)
 infield.apply_to(stadium.infield_surfaces)
 tool_bay = ToolBay.new()
 add_child(tool_bay)
 grass = preload("res://scenes/environment/grass.tscn").instantiate()
 add_child(grass)
 player = preload("res://scenes/player/player.tscn").instantiate()
 player.position = Vector3(29,0.1,-11)
 add_child(player)
 mower = preload("res://scenes/vehicles/mower.tscn").instantiate()
 mower.position = Vector3(30,0.1,-19)
 mower.rotation.y = PI/4
 add_child(mower)
 mower.grass = grass
 mower.infield = infield
 chalk = ChalkSystem.new()
 add_child(chalk)
 chalk_marker = preload("res://scenes/vehicles/chalk_marker.tscn").instantiate()
 chalk_marker.position = Vector3(38,0.05,-21)
 add_child(chalk_marker)
 chalk_marker.chalk = chalk
 var marker_sign := ParkGeometry.label(self,"CHALK MARKER\nE  USE  /  R  GATE",Vector3(38,1.8,-22),34)
 marker_sign.pixel_size = 0.005

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
 create_hud()
 grass.completion_changed.connect(update_progress)
 infield.completion_changed.connect(update_progress)
 chalk.completion_changed.connect(update_progress)
 mower.tool_changed.connect(on_tool_changed)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func configure_input() -> void:
 var keys := {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"interact":KEY_E,"brake":KEY_SPACE,"swap_tool":KEY_Q,"lift_drag":KEY_R}
 for action in keys:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  var event := InputEventKey.new()
  event.physical_keycode = keys[action]
  InputMap.action_add_event(action,event)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.echo:
  return
 if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  yaw -= event.relative.x*0.003
  pitch = clampf(pitch-event.relative.y*0.003,-1.1,0.1)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP:
   camera_distance = maxf(3,camera_distance-0.7)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   camera_distance = minf(18,camera_distance+0.7)
 if event.is_action_pressed("interact"):
  interact()
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
  player.set_seated(true)
  chalk_marker.set_occupied(true)
  pushing_chalk = true
  selected_task = 2
  update_progress(0)
 elif player.global_position.distance_to(mower.global_position) < 3.5:
  player.set_seated(true)
  mower.set_occupied(true)
  driving = true
  selected_task = 1 if mower.active_tool == RidingMower.WorkTool.DRAG else 0
  update_progress(0)

func swap_work_tool() -> bool:
 if driving or pushing_chalk or not mower.can_exit() or not tool_bay.contains(mower.global_position):
  return false
 if player.global_position.distance_to(mower.global_position) >= 3.5:
  return false
 var next_tool := RidingMower.WorkTool.DRAG if mower.active_tool == RidingMower.WorkTool.MOWER else RidingMower.WorkTool.MOWER
 return mower.set_tool(next_tool)

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
 pivot.global_position = pivot.global_position.lerp(target,1-exp(-7*delta))
 pivot.rotation = Vector3(pitch,yaw,0)
 boom.spring_length = lerpf(boom.spring_length,camera_distance,1-exp(-8*delta))
 var dragging := mower.active_tool == RidingMower.WorkTool.DRAG
 if pushing_chalk:
  mode_label.text = "CHALKING  /  " + ("GATE OPEN" if chalk_marker.gate_open else "GATE CLOSED")
  if chalk_marker.gate_open and chalk.distance_to_guide(chalk_marker.nozzle.global_position) > chalk.chalk_width*0.5:
   mode_label.text = "CHALKING  /  OFF GUIDE — NO LINE CREDIT"
 elif not driving:
  mode_label.text = "ON FOOT  /  " + ("CHALK MARKER PARKED" if selected_task == 2 else ("DRAG EQUIPPED" if dragging else "MOWER EQUIPPED"))
 elif dragging:
  mode_label.text = "DRAGGING  /  " + ("LOWERED" if mower.drag.lowered else "RAISED")
  if mower.drag.lowered and mower.speed < -0.15:
   mode_label.text = "DRAGGING  /  REVERSE — NO PREPARATION"
 else:
  mode_label.text = "MOWING  /  DECK ENGAGED"
 if pushing_chalk:
  prompt.text = "WASD push / steer  •  R chalk gate  •  Space brake  •  " + ("E leave marker" if chalk_marker.can_exit() else "Stop to leave marker")
 elif driving and dragging:
  if mower.drag.lowered:
   prompt.text = "WASD drive  •  R raise drag  •  Space brake  •  " + ("E exit" if mower.can_exit() else "Stop to exit")
  else:
   prompt.text = "WASD drive  •  Stop + R lower drag  •  Space brake  •  E exit when stopped"
 elif driving:
  prompt.text = "WASD drive  •  Space brake  •  E exit" if mower.can_exit() else "WASD drive  •  Space brake  •  Stop to exit"
 elif near_chalk_marker():
  prompt.text = "E use chalk marker  •  Follow the dashed gold foul-line guides"
 elif player.global_position.distance_to(mower.global_position) < 3.5:
  prompt.text = "E enter tractor  •  Q swap mower / drag" if tool_bay.contains(mower.global_position) else "E enter tractor  •  Return to tool bay to swap equipment"
 else:
  prompt.text = "WASD walk  •  Shift sprint  •  Space jump  •  Find equipment beside the workshop"

func create_hud() -> void:
 hud = GroundsHUD.new()
 add_child(hud)
 mode_label = hud.mode_label
 prompt = hud.prompt
 percent_label = hud.percent_label
 progress = hud.progress
 update_progress(0)

func update_progress(_value: float) -> void:
 var mowing := grass.percentage()
 var dirt := infield.percentage()
 var lining := chalk.percentage()
 var completed := [grass.total > 0 and grass.cut_count == grass.total,infield.total > 0 and infield.prepared_count == infield.total,chalk.valid_count > 0 and chalk.covered_count == chalk.valid_count]
 var values := [mowing,dirt,lining]
 var objectives := ["Mow the outfield","Drag the infield dirt","Chalk both foul lines"]
 var value: float = values[selected_task]
 hud.objective_label.text = objectives[selected_task]
 hud.summary_label.text = "MOW %.1f%%  /  DRAG %.1f%%  /  CHALK %.1f%%" % [mowing,dirt,lining]
 if selected_task == 2:
  hud.detail_label.text = "LEFT %.1f%%  /  RIGHT %.1f%%" % [chalk.line_percentage(0),chalk.line_percentage(1)]
 else:
  hud.detail_label.text = ""
 progress.value = value
 percent_label.text = "%.2f%%" % minf(value,99.99)
 if completed[selected_task]:
  percent_label.text = "TASK COMPLETE"
 if completed[0] and completed[1] and completed[2]:
  hud.objective_label.text = "PARK READY — All three tasks complete"
