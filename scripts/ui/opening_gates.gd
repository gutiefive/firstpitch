class_name OpeningGates
extends CanvasLayer
var game: Node3D
var active := false
var elapsed := 0.0
var presentations := 0
var view: SubViewport
var camera: Camera3D
var heading: Label
var detail: Label
var gates: Array[Node3D] = []
var cheer: AudioStreamPlayer
var latch: AudioStreamPlayer
const DURATION := 3.2
const G = preload("res://scripts/gameplay/geometry.gd")
func _ready() -> void:
 layer = 12
 process_mode = Node.PROCESS_MODE_ALWAYS
 view = SubViewport.new()
 view.size = Vector2i(1280,720)
 view.world_3d = game.get_world_3d()
 view.gui_disable_input = true
 view.audio_listener_enable_3d = false
 view.render_target_update_mode = SubViewport.UPDATE_DISABLED
 add_child(view)
 camera = Camera3D.new()
 camera.fov = 58
 view.add_child(camera)
 camera.current = true
 var picture := TextureRect.new()
 picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 picture.texture = view.get_texture()
 picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(picture)
 var band := PanelContainer.new()
 band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 band.offset_top = -155
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.035,0.08,0.07,0.94)
 style.set_content_margin_all(24)
 band.add_theme_stylebox_override("panel",style)
 band.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(band)
 var stack := VBoxContainer.new()
 stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
 band.add_child(stack)
 heading = Label.new()
 heading.add_theme_font_size_override("font_size",28)
 heading.modulate = Color("e1bb67")
 heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(heading)
 detail = Label.new()
 detail.add_theme_font_size_override("font_size",17)
 detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(detail)
 var skip := Label.new()
 skip.text = "Enter / A / click to continue · Esc / B to skip"
 skip.modulate = Color("b7d0bc")
 skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(skip)
 for id in ["crowd_cheer","gate_open"]:
  var player := AudioStreamPlayer.new()
  player.stream = game.audio.stream(id)
  player.bus = "GroundsAmbience" if id == "crowd_cheer" else "GroundsEffects"
  player.volume_db = -8 if id == "crowd_cheer" else -13
  add_child(player)
  if id == "crowd_cheer":
   cheer = player
  else:
   latch = player
 var root := Node3D.new()
 root.name = "ArrivalGateLeaves"
 game.stadium.add_child(root)
 for side in [-1,1]:
  var hinge := Node3D.new()
  hinge.position = Vector3(side*8,0,33)
  root.add_child(hinge)
  for y in [0.25,1.35]:
   G.tube(hinge,Vector3(0,y,0),Vector3(-side*4.6,y,0),0.04,Color("526159"))
  for i in range(14):
   var x: float = -side*(0.1+i*0.34)
   G.tube(hinge,Vector3(x,0.25,0),Vector3(x,1.35,0),0.018,Color("526159"))
  gates.append(hinge)
 set_gate_fraction(1)
 visible = false
func set_gate_fraction(value: float) -> void:
 for i in range(gates.size()):
  gates[i].rotation.y = (-1 if i == 0 else 1)*PI*0.5*value
func present(receipt: Dictionary) -> void:
 elapsed = 0
 active = true
 visible = true
 presentations += 1
 heading.text = "OPEN THE GATES" if int(receipt.game)%6 != 0 else "HOME FINALE · SEASON COMPLETE"
 detail.text = "%d supporters arriving · %d seats · Your prep made this possible." % [receipt.attendance,receipt.capacity]
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 set_gate_fraction(0)
 cheer.play()
 latch.play()
 update_view(0)
func update_view(fraction: float) -> void:
 camera.position = Vector3(11,5.2,43).lerp(Vector3(8,4.2,37),fraction)
 camera.look_at(Vector3(0,1.8,17))
 set_gate_fraction(1-pow(1-minf(1,fraction*2),3))
func _process(delta: float) -> void:
 if not active:
  return
 elapsed += delta
 update_view(clampf(elapsed/DURATION,0,1))
 if elapsed >= DURATION:
  finish()
func _input(event: InputEvent) -> void:
 if not active:
  return
 if event is InputEventKey and event.echo:
  get_viewport().set_input_as_handled()
  return
 if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("cursor_menu") or event.is_action_pressed("shift_board") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
  finish()
 # The covered recap must not respond to navigation or pointer events underneath.
 get_viewport().set_input_as_handled()
func finish() -> void:
 active = false
 visible = false
 set_gate_fraction(1)
 view.render_target_update_mode = SubViewport.UPDATE_DISABLED
 cheer.stop()
 latch.stop()
