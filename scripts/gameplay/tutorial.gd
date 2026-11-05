class_name CrewTutorial
extends Node
var game: Node
var active := false
var step := 0
var baseline := [0, 0, 0, 0, 0]
var repaired_before := 0
var entered_tractor := false
var board_seen := false
var marker: Node3D
var marker_label: Label3D
const TITLES := [
	"Meet the shift board",
	"Mow a strip",
	"Prepare the dirt",
	"Chalk a guide",
	"Water a patch",
	"Repair one mound patch",
	"Plan your next shift"
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	marker = Node3D.new()
	game.add_child(marker)
	ParkGeometry.ring(marker, Vector3.ZERO, 0.55, 0.7, Color("e1bb67"))
	ParkGeometry.cylinder(marker, Vector3.UP * 1.7, 0.08, 0.7, Color("e1bb67"))
	marker_label = ParkGeometry.label(marker, "CREW GUIDE", Vector3.UP * 2.3, 28)
	marker_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	step = game.settings.tutorial_step
	active = game.tutorial_enabled and not game.settings.tutorial_done
	capture_baseline()
	marker.visible = false
	if active and step == 0:
		face_board()


func face_board() -> void:
	var offset: Vector3 = game.layout.noticeboard_position - game.player.global_position
	game.yaw = atan2(-offset.x, -offset.z)


func can_run() -> bool:
	return (
		active
		and game.shift.session.phase == ShiftSession.Phase.PRACTICE
		and (game.autosave == null or game.autosave.candidate.is_empty())
	)


func capture_baseline() -> void:
	baseline = game.shift.counts()
	repaired_before = game.mound.repaired_count
	entered_tractor = false
	board_seen = false


func target() -> Vector3:
	match step:
		0, 6:
			return game.layout.noticeboard_position
		1:
			return Vector3(0, 0, -60) if game.driving else game.mower.global_position
		2:
			return (
				Vector3(10, 0, -10)
				if game.mower.active_tool == RidingMower.WorkTool.DRAG
				else game.layout.tool_bay_position
			)
		3:
			return (
				game.layout.point3(game.chalk.section_center(0, 30))
				if game.pushing_chalk
				else game.chalk_marker.global_position
			)
		4:
			if game.pushing_chalk:
				return game.chalk_marker.global_position
			if game.driving:
				return game.mower.global_position
			return Vector3(10, 0, -10) if game.watering.equipped else game.watering.station_position
		5:
			if game.tamper.equipped:
				for i in range(game.mound.hits.size()):
					if game.mound.hits[i] < game.mound.hits_required:
						return game.mound.patch_world(i)
			return game.tamper.rack_position
	return Vector3.ZERO


func instruction() -> String:
	var b: Callable = game.binding_text
	match step:
		0:
			return "Walk to the gold marker at the shift noticeboard."
		1:
			return "%s enter tractor. Drive onto the outfield and mow any amount." % b.call("interact")
		2:
			return (
				(
					"Stop and exit. At the bay, %s swap to drag. Enter, drive onto dirt, stop, %s lower; "
					+ "drive forward a strip."
				)
				% [b.call("swap_tool"), b.call("lift_drag")]
			)
		3:
			return (
				"%s use chalk marker. %s open gate, then push along a dashed gold guide."
				% [b.call("interact"), b.call("lift_drag")]
			)
		4:
			if game.pushing_chalk:
				return "Stop the chalk cart, then %s release it before taking the hose." % b.call("interact")
			if game.driving:
				return "Stop the tractor, then %s exit before taking the hose." % b.call("interact")
			if not game.watering.equipped:
				return (
					"Walk to the water station's gold marker, then %s take the hose." % b.call("water_tool")
				)
			return (
				(
					"Walk onto the dirt near the gold marker. Look down at the ground reticle and hold %s "
					+ "steady until AIM reaches TARGET moisture."
				)
				% b.call("spray_water")
			)
		5:
			return (
				(
					"%s take tamper at rack. Aim at one worn mound patch; stop and press %s three times, "
					+ "holding aim through each impact."
				)
				% [b.call("mound_tool"), b.call("tamp_mound")]
			)
		6:
			return (
				(
					"%s open the board: shifts set goals, Clubhouse starts the Owls story, Contracts offer "
					+ "side work, and Crew career holds pay/upgrades. Close the board to finish; tutorial work "
					+ "will be cleared."
				)
				% b.call("shift_board")
			)
	return ""


func step_complete() -> bool:
	match step:
		0:
			return (
				Vector2(game.player.global_position.x, game.player.global_position.z).distance_to(
					Vector2(game.layout.noticeboard_position.x, game.layout.noticeboard_position.z)
				)
				< 4
			)
		1:
			return entered_tractor and game.grass.cut_count > int(baseline[0])
		2:
			return (
				game.driving
				and game.mower.active_tool == RidingMower.WorkTool.DRAG
				and game.infield.prepared_count > int(baseline[1])
			)
		3:
			return game.pushing_chalk and game.chalk.covered_count > int(baseline[2])
		4:
			return game.watering.equipped and game.moisture.wet_count > int(baseline[3])
		5:
			return game.tamper.equipped and game.mound.repaired_count > repaired_before
		6:
			return board_seen and not game.shift.overlay.modal.visible
	return false


func _process(_delta: float) -> void:
	var running := can_run()
	game.hud.tutorial_panel.visible = running
	marker.visible = running and not game.get_tree().paused
	if not running:
		return
	entered_tractor = entered_tractor or game.driving
	if step == 6 and game.shift.overlay.modal.visible:
		board_seen = true
	marker.global_position = target() + Vector3.UP * 0.08
	game.hud.tutorial_title.text = "CREW GUIDE · %d/7 · %s" % [step + 1, TITLES[step]]
	game.hud.tutorial_instruction.text = instruction()
	# The live prompt owns all contextual blockers; the guide reuses it verbatim.
	game.hud.tutorial_reason.text = game.prompt.text
	if step == 4:
		if game.pushing_chalk or game.driving:
			game.hud.tutorial_reason.text = (
				"Hose pickup is unavailable until you are on foot. Stop first; then release the cart or "
				+ "exit the tractor."
			)
		elif game.watering.equipped:
			game.hud.tutorial_reason.text = game.watering.feedback
			if game.watering.target_valid and game.moisture.is_workable(game.watering.target):
				game.hud.tutorial_reason.text += (
					" · AIM %.0f%% / TARGET %.0f%%"
					% [
						game.moisture.moisture_at(game.watering.target) * 100,
						game.moisture.target_moisture * 100
					]
				)
			elif game.watering.feedback == "NO WORKABLE DIRT":
				game.hud.tutorial_reason.text += " · Aim at brown basepath dirt, not grass or the mound."
	game.hud.tutorial_skip.text = "Skip guide (%s)" % game.binding_text("tutorial_skip")
	if step_complete():
		if step == 6:
			finish()
		else:
			step += 1
			game.settings.tutorial_step = step
			game.settings.save()
			capture_baseline()


func _unhandled_input(event: InputEvent) -> void:
	if can_run() and event.is_action_pressed("tutorial_skip"):
		finish()
		get_viewport().set_input_as_handled()


func finish() -> bool:
	if not can_run():
		return false
	active = false
	game.settings.tutorial_done = true
	game.settings.tutorial_step = 0
	game.settings.save()
	game.shift.enter_practice()
	marker.visible = false
	game.hud.tutorial_panel.visible = false
	return true


func replay() -> bool:
	if game.shift.session.phase == ShiftSession.Phase.ACTIVE or not game.autosave.candidate.is_empty():
		return false
	game.shift.enter_practice()
	step = 0
	active = true
	game.settings.tutorial_done = false
	game.settings.tutorial_step = 0
	game.settings.save()
	capture_baseline()
	face_board()
	game.shift.close_board()
	return true
