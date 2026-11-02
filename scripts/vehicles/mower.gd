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
var appearance: MowerVisual

func _ready() -> void:
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(1.7,1.35,2.5)
 collider.shape = shape
 collider.position.y = 0.8
 add_child(collider)
 appearance = MowerVisual.new()
 appearance.name = "MowerVisual"
 add_child(appearance)
 wheels = appearance.wheels
 steering = appearance.steering
 deck = appearance.deck
 cutting_audio = AudioStreamPlayer3D.new()
 cutting_audio.name = "CuttingAudioHook"
 add_child(cutting_audio)
 previous_deck = deck.global_position

func can_exit() -> bool:
 return absf(speed) < 0.5

func set_occupied(value: bool) -> void:
 occupied = value
 appearance.driver.visible = value
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
 steering.rotation.y = turn*0.4
 if grass != null and occupied and absf(speed) > 0.1:
  grass.mow_segment(previous_deck,deck.global_position,-global_basis.z)
 previous_deck = deck.global_position
