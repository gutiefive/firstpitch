extends Node3D
var player: Groundskeeper
var mower: RidingMower
var grass: MowingGrass
var camera: Camera3D
var pivot: Node3D
var boom: SpringArm3D
var yaw := PI/4
var pitch := -0.45
var camera_distance := 8.0
var mode_label: Label
var prompt: Label
var percent_label: Label
var progress: ProgressBar
var driving := false

func _ready() -> void:
 configure_input()
 add_child(preload("res://scenes/stadium/stadium.tscn").instantiate())
 grass = preload("res://scenes/environment/grass.tscn").instantiate()
 add_child(grass)
 player = preload("res://scenes/player/player.tscn").instantiate()
 player.position = Vector3(32,0.1,-12)
 add_child(player)
 mower = preload("res://scenes/vehicles/mower.tscn").instantiate()
 mower.position = Vector3(30,0.1,-19)
 mower.rotation.y = PI/4
 add_child(mower)
 mower.grass = grass
 pivot = Node3D.new()
 pivot.position = player.position+Vector3.UP*1.5
 add_child(pivot)
 boom = SpringArm3D.new()
 boom.spring_length = camera_distance
 boom.margin = 0.3
 boom.add_excluded_object(player.get_rid())
 boom.add_excluded_object(mower.get_rid())
 pivot.add_child(boom)
 camera = Camera3D.new()
 camera.current = true
 camera.far = 400
 boom.add_child(camera)
 create_hud()
 grass.completion_changed.connect(update_progress)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func configure_input() -> void:
 var keys := {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"interact":KEY_E,"brake":KEY_SPACE}
 for action in keys:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  var event := InputEventKey.new()
  event.physical_keycode = keys[action]
  InputMap.action_add_event(action,event)

func _unhandled_input(event: InputEvent) -> void:
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

func interact() -> void:
 if driving:
  if not mower.can_exit():
   return
  # Query each side before placing the player, so exiting cannot embed them in scenery.
  for side in [1.0,-1.0]:
   var exit_pos: Vector3 = mower.global_position + mower.global_basis.x*side*2.3 + Vector3.UP*0.2
   var query := PhysicsShapeQueryParameters3D.new()
   query.shape = player.get_child(0).shape
   query.transform = Transform3D(Basis.IDENTITY,exit_pos+Vector3.UP*0.9)
   query.exclude = [player.get_rid(),mower.get_rid()]
   if get_world_3d().direct_space_state.intersect_shape(query).is_empty():
    player.global_position = exit_pos
    player.set_seated(false)
    mower.set_occupied(false)
    driving = false
    return
 elif player.global_position.distance_to(mower.global_position) < 3.5:
  player.set_seated(true)
  mower.set_occupied(true)
  driving = true

func _process(delta: float) -> void:
 if player == null:
  return
 player.yaw = yaw
 var target := mower.global_position+Vector3.UP*1.8 if driving else player.global_position+Vector3.UP*1.5
 pivot.global_position = pivot.global_position.lerp(target,1-exp(-7*delta))
 pivot.rotation = Vector3(pitch,yaw,0)
 boom.spring_length = lerpf(boom.spring_length,camera_distance,1-exp(-8*delta))
 mode_label.text = "MOWING  •  Deck engaged" if driving else "ON FOOT"
 if driving:
  prompt.text = "WASD drive  •  Space brake  •  E exit" if mower.can_exit() else "WASD drive  •  Space brake  •  Stop to exit"
 elif player.global_position.distance_to(mower.global_position) < 3.5:
  prompt.text = "Press E to enter mower"
 else:
  prompt.text = "WASD walk  •  Shift sprint  •  Space jump  •  Find the mower beside the shed"

func create_hud() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var panel := PanelContainer.new()
 panel.position = Vector2(24,24)
 panel.custom_minimum_size = Vector2(390,0)
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.035,0.11,0.12,0.94)
 style.content_margin_left = 20
 style.content_margin_right = 20
 style.content_margin_top = 16
 style.content_margin_bottom = 16
 style.corner_radius_top_left = 12
 style.corner_radius_bottom_right = 12
 panel.add_theme_stylebox_override("panel",style)
 layer.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",8)
 panel.add_child(stack)
 var title := Label.new()
 title.text = "FIRST PITCH: GROUNDS CREW"
 title.add_theme_font_size_override("font_size",22)
 title.add_theme_color_override("font_color",Color("f1cc75"))
 stack.add_child(title)
 mode_label = Label.new()
 stack.add_child(mode_label)
 var objective := Label.new()
 objective.text = "PREPARE THE PARK  /  Mow the outfield"
 stack.add_child(objective)
 progress = ProgressBar.new()
 progress.custom_minimum_size = Vector2(350,16)
 progress.show_percentage = false
 stack.add_child(progress)
 percent_label = Label.new()
 stack.add_child(percent_label)
 update_progress(0)
 prompt = Label.new()
 prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 prompt.offset_top = -65
 prompt.offset_bottom = -30
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 prompt.add_theme_font_size_override("font_size",20)
 prompt.add_theme_color_override("font_shadow_color",Color.BLACK)
 prompt.add_theme_constant_override("shadow_outline_size",6)
 layer.add_child(prompt)
 var reminder := Label.new()
 reminder.text = "Mouse orbit  •  Wheel zoom  •  Esc cursor"
 reminder.position = Vector2(24,204)
 layer.add_child(reminder)

func update_progress(value: float) -> void:
 progress.value = value
 percent_label.text = "%.2f%% of mowable grass prepared" % value
 if value >= 99.99:
  percent_label.text = "FIELD READY — Beautiful work!"
