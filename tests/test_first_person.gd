extends "res://tests/test_live_matchday.gd"


func view_capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.render_loop_enabled = true
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/firstpitch-fps-" + name + ".png")
	RenderingServer.render_loop_enabled = false


func aim(g: Node, point: Vector3) -> void:
	g.first_person.update_view()
	var direction: Vector3 = point - g.camera.global_position
	g.yaw = atan2(-direction.x, -direction.z)
	g.pitch = atan2(direction.y, Vector2(direction.x, direction.z).length())
	g.first_person.update_view()


func physics(count: int) -> void:
	for i in range(count):
		await physics_frame


func run() -> void:
	root.size = Vector2i(1280, 720)
	RenderingServer.render_loop_enabled = false
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://fps-career.dat"
	g.settings_save_path = "user://fps-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	root.add_child(g)
	await physics(12)
	var rig: FirstPersonView = g.first_person
	check(
		(
			g.camera.global_position.distance_to(
				g.player.global_position + Vector3.UP * FirstPersonView.EYE_HEIGHT
			)
			< 0.01
		),
		"walking camera sits inside the player's eye position"
	)
	check(
		(
			g.camera.get_parent() == g.pivot
			and g.camera.position.is_zero_approx()
			and g.camera.near < 0.1
			and g.camera.fov == 78
		),
		"gameplay has a close near plane and no third-person boom"
	)
	var hidden := true
	for mesh in g.player.visual.find_children("*", "MeshInstance3D", true, false):
		hidden = hidden and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	check(hidden, "local body casts shadows without blocking the eye camera")
	await view_capture("on-foot")
	g.input_device.last_input_device = "pad"
	g.input_device.device_changed.emit()
	Input.action_press("look_up")
	g.input_device._process(2)
	Input.action_release("look_up")
	check(
		g.pitch == FirstPersonView.MAX_PITCH,
		"controller can look above the horizon with the shared first-person limit"
	)
	Input.action_press("look_down")
	g.input_device._process(3)
	Input.action_release("look_down")
	check(g.pitch == FirstPersonView.MIN_PITCH, "controller can look down at nearby work")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	g._unhandled_input(wheel)
	rig.update_view()
	check(
		g.camera.get_parent() == g.pivot and g.camera.position.is_zero_approx(),
		"mouse wheel cannot restore an orbit camera"
	)
	g.player.position = Vector3(8, 0.1, -7)
	g.yaw = 0
	g.pitch = -0.55
	g.watering.capture_query = func() -> bool: return true
	g.watering.set_equipped(true)
	await physics(18)
	var wet: int = g.moisture.wet_count
	Input.action_press("spray_water")
	await physics(95)
	check(
		g.moisture.wet_count > wet and g.watering.spraying,
		"real eye-camera aim waters actual dirt through held input"
	)
	check(
		g.watering.nozzle.get_parent() == g.camera and g.watering.nozzle.position.z < 0,
		"nozzle is held ahead of the eye camera"
	)
	check(rig.hands[0].visible and rig.hands[1].visible, "watering has visible first-person glove grips")
	check(
		(
			not g.camera.is_position_behind(rig.hands[1].global_position)
			and Rect2(Vector2.ZERO, Vector2(root.size)).has_point(
				g.camera.unproject_position(rig.hands[1].global_position)
			)
		),
		"watering grip actually projects inside the first-person image"
	)
	check(
		(
			g.watering.stream.to_global(Vector3(0, 0.5, 0)).distance_to(g.watering.spray_end) < 0.02
			and (
				g.watering.stream.to_global(Vector3(0, -0.5, 0)).distance_to(
					g.watering.nozzle.global_position - g.watering.nozzle.global_basis.z * 0.28
				)
				< 0.02
			)
		),
		"visible water stream joins the actual nozzle tip to its clipped endpoint"
	)
	await view_capture("watering")
	Input.action_release("spray_water")
	g.watering.set_equipped(false)
	var point: Vector3 = g.mound.patch_world(0)
	g.player.position = point + Vector3(0, 0.1, 1)
	g.player.velocity = Vector3.ZERO
	g.tamper.capture_query = func() -> bool: return true
	g.tamper.set_equipped(true)
	await physics(30)
	aim(g, point)
	await physics(4)
	var hits: int = g.mound.hits[0]
	g.tamper.request_tamp()
	await physics(42)
	check(g.mound.hits[0] == hits + 1, "real first-person reticle can aim and complete a timed tamp")
	check(
		g.tamper.camera == g.camera and g.tamper.rest_query.is_valid(),
		"tamper uses the player eye camera and visible held rest position"
	)
	await physics(12)
	rig.update_view()
	check(
		(
			not g.camera.is_position_behind(rig.hands[1].global_position)
			and Rect2(Vector2.ZERO, Vector2(root.size)).has_point(
				g.camera.unproject_position(rig.hands[1].global_position)
			)
		),
		"resting tamper and grip remain visible when looking down"
	)
	aim(g, point)
	g.tamper.request_tamp()
	await physics(12)
	await view_capture("tamping")
	g.tamper.set_equipped(false)
	g.player.position = g.mower.global_position + Vector3(2, 0.1, 0)
	g.interact()
	rig.update_view()
	check(
		g.driving and g.camera.global_position.distance_to(g.mower.to_global(Vector3(0, 1.65, 0.4))) < 0.01,
		"tractor entry places the camera in the operator seat"
	)
	var yaw: float = g.yaw
	g.mower.rotation.y += 0.3
	rig.update_view()
	check(absf(angle_difference(g.yaw, yaw + 0.3)) < 0.001, "seat view follows tractor turns")
	g.yaw += 0.7
	g.mower.rotation.y += 0.2
	rig.update_view()
	check(
		absf(angle_difference(g.yaw, g.mower.rotation.y + 0.7)) < 0.001,
		"free look offset remains stable while steering"
	)
	var from: Vector3 = g.mower.position
	Input.action_press("forward")
	await physics(24)
	Input.action_release("forward")
	check(
		(
			g.mower.position.distance_to(from) > 0.15
			and g.camera.global_position.distance_to(g.mower.to_global(Vector3(0, 1.65, 0.4))) < 0.05
		),
		"actual driving keeps the eye attached to the moving seat"
	)
	g.yaw = g.mower.rotation.y
	g.pitch = -0.2
	await view_capture("mower")
	Input.action_press("brake")
	await physics(48)
	Input.action_release("brake")
	g.interact()
	rig.update_view()
	check(
		(
			not g.driving
			and (
				g.camera.global_position.distance_to(
					g.player.global_position + Vector3.UP * FirstPersonView.EYE_HEIGHT
				)
				< 0.01
			)
		),
		"tractor exit restores the standing eye without flying through space"
	)
	g.chalk_marker.position = Vector3(12, 0.1, -12)
	g.chalk_marker.rotation.y = -PI / 4
	g.player.position = g.chalk_marker.position + Vector3(0, 0.1, 1.5)
	await physics(12)
	g.interact()
	rig.update_view()
	check(
		(
			g.pushing_chalk
			and g.camera.global_position.distance_to(g.chalk_marker.to_global(Vector3(0, 1.6, 1.45))) < 0.01
		),
		"chalk view is behind the handle at operator eye level"
	)
	g.chalk_marker.toggle_gate()
	var covered: int = g.chalk.covered_count
	Input.action_press("forward")
	await physics(70)
	Input.action_release("forward")
	check(g.chalk.covered_count > covered, "first-person chalking retains actual guide coverage")
	await view_capture("chalking")
	Input.action_press("brake")
	await physics(30)
	Input.action_release("brake")
	g.interact()
	check(not g.pushing_chalk, "marker exit restores walking")
	g.club.join()
	prep(g)
	g.club.opening.finish()
	prep(g)
	g.club.opening.finish()
	check(g.club.build("snack_shack"), "real early earnings still unlock concession jobs")
	var live: LiveMatchday = g.club.live
	check(live.start(), "live park opens with the same first-person player")
	live.set_process(false)
	g.player.position = live.jobs[0].point
	g.player.velocity = Vector3.ZERO
	g.yaw = 0
	g.pitch = -0.9
	Input.action_press("interact")
	live.advance_jobs(0.5)
	rig.update_view()
	check(
		live.broom.visible and rig.hands[0].visible and rig.hands[1].visible,
		"sweeping keeps the broom and two grip hands visible in first person"
	)
	live.refresh_hud()
	await view_capture("sweeping")
	Input.action_release("interact")
	live.advance_jobs(0)
	g.player.position = live.jobs[2].point
	live.interact_job()
	g.pitch = -0.1
	rig.update_view()
	check(
		(
			live.carrying
			and live.parcel.global_position.distance_to(g.camera.to_global(Vector3(0, -0.4, -0.78))) < 0.01
		),
		"carried concession crate stays in the first-person hands"
	)
	await view_capture("carrying")
	live.show_broadcast()
	check(
		(g.club.opening.camera.cull_mask & FirstPersonView.VIEW_LAYER) == 0,
		"optional broadcast excludes local first-person meshes"
	)
	g.club.opening.walk_park()
	rig.update_view()
	check(
		(
			g.camera.global_position.distance_to(
				g.player.global_position + Vector3.UP * FirstPersonView.EYE_HEIGHT
			)
			< 0.01
		),
		"broadcast return restores the eye view"
	)
	live.end_visit(false)
	var store := FieldSave.new()
	check(
		store.validate(store.capture(g, g.shift.session), g),
		"first-person presentation preserves field-save compatibility"
	)
	paused = false
	g.queue_free()
	await process_frame
	RenderingServer.render_loop_enabled = true
	print("First person: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
