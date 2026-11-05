class_name Groundskeeper
extends CharacterBody3D
@export var walk_speed := 4.5
@export var sprint_speed := 7.5
var seated := false
var yaw := 0.0
var visual: Node3D


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	visual = CrewVisual.new()
	add_child(visual)


func set_seated(value: bool) -> void:
	seated = value
	visible = not value
	velocity = Vector3.ZERO
	set_collision_layer_value(1, not value)
	set_collision_mask_value(1, not value)


func _physics_process(delta: float) -> void:
	if seated:
		return
	var input := Input.get_vector("left", "right", "forward", "back")
	var direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, 25 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 25 * delta)
	if not is_on_floor():
		velocity.y -= 22 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 7
	if direction.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), delta * 12)
	(visual as CrewVisual).animate_walk(Vector2(velocity.x, velocity.z).length(), delta)
	move_and_slide()
