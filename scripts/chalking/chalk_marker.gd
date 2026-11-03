class_name ChalkMarker
extends CharacterBody3D
signal occupied_changed(occupied: bool)
@export var push_speed := 2.4
@export var reverse_speed := 1.3
@export var steering_rate := 1.7
@export var stroke_spacing := 0.08
var guide_wheel_owned := false
var guide_active := false
var guide_visual: Node3D
var guide_roller: MeshInstance3D
var occupied := false
var gate_open := false
var speed := 0.0
var chalk: ChalkSystem
var last_nozzle := Vector3.ZERO
var nozzle: Node3D
var pusher: CrewVisual
var wheels: Array[MeshInstance3D] = []
const G = preload("res://scripts/gameplay/geometry.gd")

func _ready() -> void:
 var shape := BoxShape3D.new()
 shape.size = Vector3(0.8,1.85,2.2)
 var collider := CollisionShape3D.new()
 collider.shape = shape
 collider.position = Vector3(0,0.925,0.55)
 add_child(collider)
 build_visual()
 last_nozzle = nozzle.global_position

func build_visual() -> void:
 var red := Color("b46948")
 var steel := Color("4d6965")
 G.box(self,Vector3(0,0.57,0),Vector3(0.56,0.5,0.55),red)
 G.box(self,Vector3(0,0.84,0),Vector3(0.62,0.07,0.61),Color("eee3c6"))
 G.box(self,Vector3(0,0.9,0.04),Vector3(0.17,0.05,0.05),steel)
 G.box(self,Vector3(0,0.28,0),Vector3(0.65,0.1,0.75),steel)
 var badge := G.label(self,"FIELD\nLINE",Vector3(0,0.6,-0.285),40)
 badge.pixel_size = 0.003
 for side in [-1,1]:
  var wheel := G.cylinder(self,Vector3(side*0.36,0.23,0.1),0.23,0.12,Color("2b3c37"))
  wheel.rotation.z = PI/2
  wheels.append(wheel)
  G.cylinder(wheel,Vector3(0,-side*0.075,0),0.1,0.025,Color("eee3c6"))
  G.beam(self,Vector3(side*0.25,0.3,0.2),Vector3(side*0.28,1,0.85),0.04,steel)
 G.box(self,Vector3(0,1,0.85),Vector3(0.65,0.045,0.045),steel)
 G.box(self,Vector3(0,0.10,-0.45),Vector3(0.22,0.08,0.12),Color("eee3c6"))
 nozzle = Node3D.new()
 nozzle.position = Vector3(0,0,-0.45)
 add_child(nozzle)
 pusher = CrewVisual.new()
 pusher.pushing_pose = true
 pusher.position = Vector3(0,0,1.22)
 add_child(pusher)
 pusher.visible = false
 guide_visual = Node3D.new()
 guide_visual.name = "GuideWheel"
 add_child(guide_visual)
 G.beam(guide_visual,Vector3(0,0.28,-0.25),Vector3(0,0.12,-0.75),0.045,Color("d8b35e"))
 guide_roller = G.cylinder(guide_visual,Vector3(0,0.12,-0.75),0.11,0.07,Color("314e47"))
 guide_roller.rotation.z = PI/2
 guide_visual.visible = false

func set_occupied(value: bool) -> void:
 occupied = value
 guide_active = false
 pusher.visible = value
 if not value:
  gate_open = false
 last_nozzle = nozzle.global_position
 occupied_changed.emit(value)

func can_exit() -> bool:
 return absf(speed) < 0.15

func toggle_gate() -> bool:
 if not occupied:
  return false
 gate_open = not gate_open
 if not gate_open:
  guide_active = false
 last_nozzle = nozzle.global_position
 return true

func _physics_process(delta: float) -> void:
 var throttle := Input.get_axis("back","forward") if occupied else 0.0
 var turn := Input.get_axis("right","left") if occupied else 0.0
 var target := throttle*(push_speed if throttle >= 0 else reverse_speed)
 if occupied and Input.is_action_pressed("brake"):
  target = 0
 speed = move_toward(speed,target,5*delta)
 rotation.y += turn*steering_rate*clampf(speed/0.8,-1,1)*delta
 update_guide(turn,delta)
 velocity.x = -sin(rotation.y)*speed
 velocity.z = -cos(rotation.y)*speed
 velocity.y = -0.1 if is_on_floor() else velocity.y-22*delta
 var before := global_position
 move_and_slide()
 var travel := Vector2(global_position.x-before.x,global_position.z-before.z).length()
 # Floor recovery can suppress a wall slide report while horizontal travel is zero.
 if absf(speed) > 0.001 and travel < absf(speed)*delta*0.1:
  speed = 0
 for index in range(get_slide_collision_count()):
  if absf(get_slide_collision(index).get_normal().y) < 0.5:
   speed = 0
 if speed <= 0.05:
  guide_active = false
 for wheel in wheels:
  wheel.rotate_object_local(Vector3.UP,speed*delta/0.23)
 pusher.animate_walk(absf(speed),delta)
 if guide_wheel_owned:
  guide_roller.rotate_object_local(Vector3.UP,speed*delta/0.11)
 var current := nozzle.global_position
 if occupied and gate_open and speed > 0.05 and is_on_floor() and chalk != null:
  if current.distance_to(last_nozzle) >= stroke_spacing:
   chalk.paint_segment(last_nozzle,current)
   last_nozzle = current
 else:
  last_nozzle = current

func set_guide_wheel(value: bool) -> void:
 guide_wheel_owned = value
 guide_visual.visible = value
 if not value:
  guide_active = false

func update_guide(turn: float,delta: float) -> void:
 guide_active = false
 if not guide_wheel_owned or not occupied or not gate_open or speed <= 0.05 or not is_zero_approx(turn) or not is_on_floor() or Input.is_action_pressed("brake") or chalk == null:
  return
 var rules: Dictionary = CareerProfile.UPGRADES.guide_wheel
 var p := Vector2(nozzle.global_position.x,nozzle.global_position.z)
 var forward := Vector2(-sin(rotation.y),-cos(rotation.y))
 for side in range(2):
  var line := chalk.line_direction(side)
  var along := (p-chalk.layout.plate_position).dot(line)
  if along < chalk.line_start or along > chalk.line_end:
   continue
  var nearest := chalk.layout.plate_position+line*along
  if p.distance_to(nearest) > float(rules.capture_distance):
   continue
  var direction := line if forward.dot(line) >= 0 else -line
  var heading := atan2(-direction.x,-direction.y)
  if absf(angle_difference(rotation.y,heading)) > deg_to_rad(float(rules.capture_angle)):
   continue
  var target := nearest+direction*float(rules.lookahead)-p
  rotation.y = rotate_toward(rotation.y,atan2(-target.x,-target.y),float(rules.correction_rate)*delta)
  guide_active = true
  return
