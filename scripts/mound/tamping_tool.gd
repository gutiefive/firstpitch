class_name TampingTool
extends Node3D
signal impact(point: Vector3)
signal equipped_changed(equipped: bool)
@export var layout: FieldLayout = preload("res://resources/layouts/cedar_grove.tres")
var rack_position: Vector3:
	get:
		return layout.tamper_rack_position
@export var pickup_distance := 3.0
@export var working_reach := 2.2
@export var stroke_duration := 0.65
@export var contact_time := 0.36
var player: Groundskeeper
var camera: Camera3D
var mound: MoundSurface
var binding_query: Callable
var placard: Label3D
var capture_query: Callable
var rest_query: Callable
var view_rotation_query: Callable
var equipped := false
var busy := false
var requested := false
var swing_time := 0.0
var impact_checked := false
var swing_failed := false
var locked_index := -1
var target_index := -1
var feedback := "AIM AT WORN CLAY"
var held: TamperVisual
var stored: TamperVisual
var ring: MeshInstance3D
var dust: MultiMeshInstance3D
var dust_time := 1.0
var dust_origin := Vector3.ZERO


func _ready() -> void:
	build_rack()
	if player == null or mound == null:
		return
	held = TamperVisual.new()
	add_child(held)
	held.visible = false
	ring = ParkGeometry.ring(
		self, Vector3.ZERO, mound.patch_radius - 0.02, mound.patch_radius, Color("dfb862")
	)
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var crumb := BoxMesh.new()
	crumb.size = Vector3.ONE * 0.055
	batch.mesh = crumb
	batch.instance_count = 10
	dust = MultiMeshInstance3D.new()
	dust.multimesh = batch
	dust.material_override = ParkGeometry.material(Color("bc8655"))
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dust.visible = false
	add_child(dust)


func build_rack() -> void:
	ParkGeometry.box(self, rack_position + Vector3.UP * 0.1, Vector3(1.5, 0.2, 0.7), Color("b18a57"), true)
	for side in [-1, 1]:
		ParkGeometry.box(
			self, rack_position + Vector3(side * 0.65, 0.9, -0.25), Vector3(0.08, 1.8, 0.08), Color("28585a")
		)
	ParkGeometry.box(self, rack_position + Vector3(0, 1.65, -0.25), Vector3(2, 0.5, 0.12), Color("eee3c6"))
	placard = ParkGeometry.label(
		self, "MOUND REPAIR\nTAKE / STOW TAMPER", rack_position + Vector3(0, 1.65, -0.17), 34
	)
	placard.pixel_size = 0.004
	placard.modulate = Color("28585a")
	stored = TamperVisual.new()
	stored.position = rack_position + Vector3.UP * 0.2
	add_child(stored)


func cursor_is_captured() -> bool:
	return (
		bool(capture_query.call())
		if capture_query.is_valid()
		else Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)


func toggle_equipped() -> bool:
	if player == null or player.seated:
		return false
	if not equipped and player.global_position.distance_to(rack_position) > pickup_distance:
		return false
	set_equipped(not equipped)
	return true


func set_equipped(value: bool) -> void:
	equipped = value
	held.visible = value
	stored.visible = not value
	(player.visual as CrewVisual).tamping_pose = value
	if not value:
		cancel_swing()
		ring.visible = false
		target_index = -1
	equipped_changed.emit(value)


func request_tamp() -> void:
	if equipped and not busy:
		requested = true


func cancel_swing() -> void:
	busy = false
	requested = false
	swing_time = 0
	(player.visual as CrewVisual).tamp_lift = 0


func update_aim() -> void:
	target_index = -1
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + camera.project_ray_normal(center) * 100, 1, [player.get_rid()]
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and (hit.normal as Vector3).y > 0.9:
		if absf((hit.position as Vector3).y - (mound.global_position.y + mound.top_height)) < 0.1:
			target_index = mound.patch_at(hit.position)
	feedback = "MOUND REPAIRED" if mound.work_done == mound.total_work else "AIM AT WORN CLAY"
	if target_index >= 0:
		if mound.hits[target_index] >= mound.hits_required:
			feedback = "PATCH REPAIRED"
		elif not within_reach(target_index):
			feedback = "MOVE CLOSER"
		elif Vector2(player.velocity.x, player.velocity.z).length() > 0.35:
			feedback = "STOP BEFORE TAMPING"
		else:
			feedback = (
				"PRESS %s TO TAMP" % binding_query.call("tamp_mound")
				if binding_query.is_valid()
				else "PRESS TO TAMP"
			)


func within_reach(index: int) -> bool:
	if index < 0 or index >= mound.hits.size():
		return false
	var point := mound.patch_world(index)
	return (
		Vector2(point.x - player.global_position.x, point.z - player.global_position.z).length()
		<= working_reach
	)


func can_work(index: int) -> bool:
	if (
		not equipped
		or player.seated
		or not cursor_is_captured()
		or not player.is_on_floor()
		or not within_reach(index)
	):
		return false
	if (
		Vector2(player.velocity.x, player.velocity.z).length() > 0.35
		or mound.hits[index] >= mound.hits_required
	):
		return false
	var point := mound.patch_world(index)
	var hand := player.visual.to_global(Vector3(0, 1, -0.4))
	var query := PhysicsRayQueryParameters3D.create(hand, point + Vector3.UP * 0.02, 1, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (hit.position as Vector3).distance_to(point) < 0.15


func _physics_process(delta: float) -> void:
	if held == null:
		return
	if not equipped or player.seated:
		if busy:
			cancel_swing()
		return
	update_aim()
	if not cursor_is_captured():
		cancel_swing()
		feedback = (
			"%s TO RECAPTURE CURSOR" % binding_query.call("cursor_menu")
			if binding_query.is_valid()
			else "RECAPTURE CURSOR TO TAMP"
		)
	elif requested:
		requested = false
		if can_work(target_index):
			locked_index = target_index
			busy = true
			swing_time = 0
			impact_checked = false
			swing_failed = false
	if busy:
		swing_time += delta
		feedback = "MISSED — STOP AND HOLD AIM" if swing_failed else "TAMPING — HOLD AIM"
		if swing_time >= contact_time and not impact_checked:
			impact_checked = true
			if target_index == locked_index and can_work(locked_index):
				if mound.apply_tamp(locked_index):
					impact.emit(mound.patch_world(locked_index))
					dust_time = 0
					dust_origin = mound.patch_world(locked_index)
			else:
				swing_failed = true
				feedback = "MISSED — STOP AND HOLD AIM"
		if swing_time >= stroke_duration:
			busy = false
	player.visual.rotation.y = lerp_angle(player.visual.rotation.y, player.yaw, 1 - exp(-12 * delta))


func _process(delta: float) -> void:
	if held == null:
		return
	if equipped:
		var rest: Vector3 = (
			rest_query.call() if rest_query.is_valid() else player.visual.to_global(Vector3(0, 0.08, -0.6))
		)
		var work_position := rest
		if busy:
			var impact_point := mound.patch_world(locked_index) + Vector3.UP * 0.045
			var raised := impact_point + Vector3.UP * 0.75
			if swing_time < 0.22:
				work_position = rest.lerp(raised, smoothstep(0, 0.22, swing_time))
			elif swing_time < contact_time:
				work_position = raised.lerp(impact_point, smoothstep(0.22, contact_time, swing_time))
			else:
				work_position = impact_point.lerp(rest, smoothstep(contact_time, stroke_duration, swing_time))
		held.global_position = work_position
		var desired: Vector3 = (
			view_rotation_query.call()
			if view_rotation_query.is_valid()
			else Vector3(0, player.visual.global_rotation.y, 0)
		)
		held.rotation.x = lerp_angle(held.rotation.x, desired.x, minf(1, delta * 16))
		held.rotation.y = desired.y
		(player.visual as CrewVisual).tamp_lift = clampf(work_position.y - rest.y, 0, 1)
		ring.visible = target_index >= 0
		if ring.visible:
			ring.global_position = mound.patch_world(target_index) + Vector3.UP * 0.035
			ring.material_override = ParkGeometry.material(
				Color("83c4cf") if mound.hits[target_index] >= mound.hits_required else Color("dfb862")
			)
	dust_time += delta
	dust.visible = dust_time < 0.3
	if dust.visible:
		for i in range(10):
			var angle := i * TAU / 10
			var point := (
				dust_origin
				+ Vector3(
					sin(angle) * dust_time,
					0.08 + dust_time - 2 * dust_time * dust_time,
					cos(angle) * dust_time
				)
			)
			var work_basis := Basis(Vector3.UP, angle).scaled(Vector3.ONE * (1 - dust_time / 0.3))
			dust.multimesh.set_instance_transform(i, Transform3D(work_basis, point))
