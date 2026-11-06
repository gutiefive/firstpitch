class_name FirstPersonView
extends Node
const EYE_HEIGHT := 1.65
const MIN_PITCH := -1.35
const MAX_PITCH := 1.35
const VIEW_LAYER := 1 << 19
const G = preload("res://scripts/gameplay/geometry.gd")
var game: Node3D
var mounted: Node3D
var last_mount_yaw := 0.0
var hands: Array[Node3D] = []
var marked_parcel: Node3D


func _ready() -> void:
	game.camera.near = 0.045
	game.camera.fov = 78
	shadow_body(game.player.visual)
	shadow_body(game.mower.appearance.driver)
	shadow_body(game.chalk_marker.pusher)
	for side in [-1, 1]:
		var hand := Node3D.new()
		hand.name = "LeftGlove" if side < 0 else "RightGlove"
		game.camera.add_child(hand)
		G.soft_box(hand, Vector3.ZERO, Vector3(0.095, 0.07, 0.12), Color("c5b79b"))
		for finger in range(4):
			G.soft_box(
				hand,
				Vector3(-0.034 + finger * 0.022, -0.005, -0.065),
				Vector3(0.018, 0.045, 0.035),
				Color("b4a68b")
			)
		var forearm := G.capsule(hand, Vector3(0, -0.26, 0.4), 0.052, 0.88, Color("b58a6c"))
		forearm.rotation.x = 2.16
		var sleeve := G.capsule(hand, Vector3(0, -0.43, 0.66), 0.064, 0.38, Color("8a8158"))
		sleeve.rotation.x = 2.16
		view_meshes(hand)
		hands.append(hand)
	update_view()


func shadow_body(root: Node) -> void:
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func view_meshes(root: Node) -> void:
	if root is MeshInstance3D or root is Label3D:
		root.layers = VIEW_LAYER
		root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in root.get_children():
		view_meshes(child)


func attach_tools() -> void:
	game.watering.nozzle.reparent(game.camera, false)
	game.watering.nozzle.position = Vector3(0.23, -0.15, -0.58)
	view_meshes(game.watering.nozzle)
	view_meshes(game.tamper.held)
	game.tamper.rest_query = tamper_rest
	game.tamper.view_rotation_query = tamper_rotation


func tamper_rest() -> Vector3:
	return game.camera.to_global(Vector3(0.27, -0.95, -0.78))


func _physics_process(_delta: float) -> void:
	update_view()


func update_view() -> void:
	var actor: Node3D = null
	var eye: Vector3 = game.player.global_position + Vector3.UP * EYE_HEIGHT
	if game.driving:
		actor = game.mower
		eye = actor.to_global(Vector3(0, 1.65, 0.4))
	elif game.pushing_chalk:
		actor = game.chalk_marker
		eye = actor.to_global(Vector3(0, 1.6, 1.45))
	if actor != mounted:
		mounted = actor
		if mounted != null:
			game.yaw = mounted.global_rotation.y
			game.pitch = -0.2
			last_mount_yaw = mounted.global_rotation.y
	elif mounted != null:
		var heading := mounted.global_rotation.y
		game.yaw += angle_difference(last_mount_yaw, heading)
		last_mount_yaw = heading
	game.pitch = clampf(game.pitch, MIN_PITCH, MAX_PITCH)
	game.pivot.global_position = eye
	game.pivot.rotation = Vector3(game.pitch, game.yaw, 0)
	game.camera.position = Vector3.ZERO
	game.player.yaw = game.yaw
	game.player.visual.rotation.y = game.yaw
	update_hands()


func grip(index: int, point: Vector3) -> void:
	hands[index].visible = true
	hands[index].global_position = point
	hands[index].global_basis = game.camera.global_basis


func update_hands() -> void:
	for hand in hands:
		hand.visible = false
	if game.watering == null or game.tamper == null:
		return
	if game.driving:
		var wheel: Node3D = game.mower.appearance.steering
		grip(0, wheel.to_global(Vector3(-0.23, 0, 0)))
		grip(1, wheel.to_global(Vector3(0.23, 0, 0)))
	elif game.pushing_chalk:
		grip(0, game.chalk_marker.to_global(Vector3(-0.27, 1, 0.85)))
		grip(1, game.chalk_marker.to_global(Vector3(0.27, 1, 0.85)))
	elif game.tamper.equipped:
		grip(0, game.tamper.held.to_global(Vector3(0, 0.7, 0)))
		grip(1, game.tamper.held.to_global(Vector3(0, 1.02, 0)))
	elif game.watering.equipped:
		grip(1, game.watering.nozzle.to_global(Vector3(0, -0.09, 0.04)))
		grip(0, game.watering.nozzle.to_global(Vector3(-0.12, -0.13, 0.23)))
	elif game.club != null and game.club.live != null and game.club.live.active:
		var live: LiveMatchday = game.club.live
		if live.carrying and is_instance_valid(live.parcel):
			if marked_parcel != live.parcel:
				var label := G.label(live.parcel, "OWLS", Vector3(0, 0.02, 0.181), 22)
				label.pixel_size = 0.004
				view_meshes(live.parcel)
				marked_parcel = live.parcel
			live.parcel.global_transform = (
				game.camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, -0.4, -0.78))
			)
			grip(0, live.parcel.to_global(Vector3(-0.29, -0.02, 0.05)))
			grip(1, live.parcel.to_global(Vector3(0.29, -0.02, 0.05)))
		elif is_instance_valid(live.broom) and live.broom.visible:
			grip(0, live.broom.to_global(Vector3(0, 0.75, 0)))
			grip(1, live.broom.to_global(Vector3(0, 1.15, 0)))


func tamper_rotation() -> Vector3:
	return Vector3(0 if game.tamper.busy else game.pitch, game.yaw, 0)
