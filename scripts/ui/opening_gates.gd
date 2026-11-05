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
var moment: Label
var timeline: ProgressBar
var gates: Array[Node3D] = []
var cheer: AudioStreamPlayer
var latch: AudioStreamPlayer
const DURATION := 47.0
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
 band.grow_vertical = Control.GROW_DIRECTION_BEGIN
 var style := StyleBoxFlat.new()
 style.bg_color = GameUI.BG
 style.set_content_margin_all(24)
 band.add_theme_stylebox_override("panel",style)
 band.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(band)
 var stack := VBoxContainer.new()
 stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
 band.add_child(stack)
 heading = Label.new()
 heading.add_theme_font_size_override("font_size",28)
 heading.modulate = GameUI.ACCENT
 heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(heading)
 detail = Label.new()
 detail.add_theme_font_size_override("font_size",15)
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stack.add_child(detail)
 moment = GameUI.label(stack,"",14,GameUI.TEXT)
 timeline = GameUI.meter(stack)
 timeline.theme = GameUI.theme()
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
 game.club.matchday.begin(receipt)
 active = true
 visible = true
 presentations += 1
 heading.text = "OPEN THE GATES" if int(receipt.game)%6 != 0 else "HOME FINALE · SEASON COMPLETE"
 detail.text = "%d supporters · %d seats · Your prep made this possible." % [receipt.attendance,receipt.capacity]
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 set_gate_fraction(0)
 cheer.play()
 latch.play()
 update_view(0)
func update_view(fraction: float) -> void:
 var seconds := fraction*DURATION
 var park: MatchdayPark = game.club.matchday
 park.set_time(seconds)
 if seconds < 7:
  heading.text = "HOME FINALE · SEASON COMPLETE" if int(park.receipt.get("game",1))%6 == 0 else "MATCHDAY · THE GATES ARE OPEN"
  camera.position = Vector3(10,4.5,42).lerp(Vector3(7,3.5,35),seconds/7)
  camera.look_at(Vector3(3,1.1,29))
  moment.text = park.story_lines[0] if not park.story_lines.is_empty() else "Welcome to Cedar Grove."
 elif seconds < 13:
  heading.text = "MATCHDAY · A PARK FULL OF LIFE"
  var side := 1.0 if "snack_shack" in game.shift.career.club.buildings else -1.0
  camera.position = Vector3(side*24,3.5,12).lerp(Vector3(side*27,2.8,13),(seconds-7)/6)
  camera.look_at(Vector3(side*31,1.4,18))
  moment.text = park.story_lines[2]
 elif seconds < 40:
  heading.text = "OWLS %d  ·  %s %d  /  INNING %d" % [park.home_runs,String(park.fixture.opponent).to_upper(),park.away_runs,park.inning]
  var t := (seconds-13)/27
  camera.position = Vector3(27,19,18).lerp(Vector3(-17,15,12),t)
  camera.look_at(Vector3(0,0,-22))
  moment.text = "Condensed game · Pitch, contact, runners and the crowd. Your prep and gate earnings are already settled."
 else:
  heading.text = "FINAL · OWLS %d  /  VISITORS %d" % [park.home_runs,park.away_runs]
  camera.position = Vector3(-3,3,28)
  camera.look_at(Vector3(-7,1.4,24))
  var index := mini(park.story_lines.size()-1,1+int((seconds-40)/2.4))
  moment.text = park.story_lines[index]
 timeline.value = fraction*100
 set_gate_fraction(1-pow(1-minf(1,seconds/3),3))
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
 if game.club.matchday != null:
  game.club.matchday.complete()
 set_gate_fraction(1)
 view.render_target_update_mode = SubViewport.UPDATE_DISABLED
 cheer.stop()
 latch.stop()
