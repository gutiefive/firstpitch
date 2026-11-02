class_name RidingMower
extends CharacterBody3D
signal occupied_changed(occupied: bool)
@export var max_speed := 8.0
@export var reverse_speed := 3.0
@export var acceleration := 4.0
@export var braking := 9.0
@export var steering_rate := 1.3
var occupied := false
var speed := 0.0
var wheels: Array[MeshInstance3D] = []
var steering: MeshInstance3D
var deck: Node3D
var grass: MowingGrass
var previous_deck := Vector3.ZERO
var cutting_audio: AudioStreamPlayer3D

func _ready() -> void:
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(1.7,1.35,2.5)
 collider.shape = shape
 collider.position.y = 0.8
 add_child(collider)
 ParkGeometry.box(self,Vector3(0,0.6,0),Vector3(1.5,0.5,2.2),Color("e6ad32"))
 ParkGeometry.box(self,Vector3(0,1,-0.65),Vector3(1.15,0.65,0.95),Color("e7bb40"))
 ParkGeometry.box(self,Vector3(0,1.15,0.5),Vector3(0.8,0.18,0.7),Color("293c42"))
 ParkGeometry.box(self,Vector3(0,1.5,0.85),Vector3(0.8,0.7,0.18),Color("293c42"))
 deck = ParkGeometry.box(self,Vector3(0,0.22,-0.3),Vector3(2.4,0.2,1.2),Color("e4c45e"))
 steering = ParkGeometry.cylinder(self,Vector3(0,1.5,-0.18),0.28,0.09,Color("263a3b"))
 steering.rotation.x = 0.5
 for x in [-0.88,0.88]:
  for z in [-0.85,0.8]:
   var wheel := ParkGeometry.cylinder(self,Vector3(x,0.4,z),0.4,0.3,Color("253033"))
   wheel.rotation.z = PI/2
   wheels.append(wheel)
 cutting_audio = AudioStreamPlayer3D.new()
 cutting_audio.name = "CuttingAudioHook"
 add_child(cutting_audio)
 previous_deck = deck.global_position

func can_exit() -> bool:
 return absf(speed) < 0.5

func set_occupied(value: bool) -> void:
 occupied = value
 occupied_changed.emit(value)

func _physics_process(delta: float) -> void:
 var throttle := Input.get_axis("back","forward") if occupied else 0.0
 var turn := Input.get_axis("right","left") if occupied else 0.0
 var target := throttle*(max_speed if throttle >= 0 else reverse_speed)
 var rate := acceleration if throttle != 0 else braking
 if occupied and Input.is_action_pressed("brake"):
  target = 0
  rate = braking
 speed = move_toward(speed,target,rate*delta)
 rotation.y += turn*steering_rate*clampf(speed/3,-1,1)*delta
 velocity.x = -sin(rotation.y)*speed
 velocity.z = -cos(rotation.y)*speed
 if not is_on_floor():
  velocity.y -= 22*delta
 else:
  velocity.y = -0.1
 move_and_slide()
 if get_slide_collision_count() > 0:
  for i in range(get_slide_collision_count()):
   if absf(get_slide_collision(i).get_normal().y) < 0.5:
    speed = 0
 for wheel in wheels:
  wheel.rotate_object_local(Vector3.UP,speed*delta/0.4)
 steering.rotation.z = turn*0.4
 if grass != null and occupied and absf(speed) > 0.1:
  grass.mow_segment(previous_deck,deck.global_position,-global_basis.z)
 previous_deck = deck.global_position
