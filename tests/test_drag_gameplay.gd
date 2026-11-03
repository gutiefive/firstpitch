extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error(message)
  failures += 1
func press_key(game: Node,key: Key) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = key
 event.keycode = key
 event.pressed = true
 game._unhandled_input(event)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 for i in range(60):
  await physics_frame
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 press_key(game,KEY_Q)
 check(game.mower.active_tool == RidingMower.WorkTool.DRAG,"Q equips drag on foot near the tool bay")
 check(not game.mower.drag.lowered and not game.mower.deck.visible,"drag starts raised and mower deck is removed")
 check(game.tool_bay.spare_deck.visible and not game.tool_bay.parked_drag.visible,"rack displays the unequipped mower deck")
 check(game.hud.objective_label.text == "Drag the infield dirt","HUD selects the dirt objective")
 game.interact()
 press_key(game,KEY_Q)
 check(game.mower.active_tool == RidingMower.WorkTool.DRAG,"cannot swap equipment while seated")
 game.mower.global_position = Vector3(7,0.05,-7)
 game.mower.rotation.y = -PI/4
 game.mower.previous_drag = game.mower.drag.global_position
 Input.action_press("forward")
 for i in range(75):
  await physics_frame
 check(game.infield.prepared_count == 0,"raised drag does not prepare dirt")
 press_key(game,KEY_R)
 check(not game.mower.drag.lowered,"cannot lower drag while moving")
 Input.action_release("forward")
 Input.action_press("brake")
 for i in range(75):
  await physics_frame
 Input.action_release("brake")
 # Reposition to the start of the right basepath for a controlled dragging pass.
 game.mower.global_position = Vector3(7,0.05,-7)
 game.mower.rotation.y = -PI/4
 game.mower.speed = 0
 game.mower.previous_drag = game.mower.drag.global_position
 press_key(game,KEY_R)
 check(game.mower.drag.lowered,"R lowers stationary drag")
 Input.action_press("forward")
 for i in range(150):
  await physics_frame
 check(game.infield.prepared_count > 200,"forward driving actually smooths dirt")
 check(game.audio.loops.drag.playing,"actual lowered forward dragging plays friction sound")
 check(game.mower.speed <= game.mower.dragging_speed+0.01,"lowered drag limits working speed")
 check(game.grass.cut_count == 0,"dragging cannot mow grass")
 check(game.progress.value > 0,"HUD receives actual dirt progress")
 press_key(game,KEY_R)
 check(not game.mower.drag.lowered,"drag can be raised while moving")
 Input.action_release("forward")
 for i in range(75):
  await physics_frame
 var count: int = game.infield.prepared_count
 # A lowered drag on untouched outfield must affect neither task.
 game.mower.global_position = Vector3(0,0.05,-60)
 game.mower.rotation.y = 0
 game.mower.previous_drag = game.mower.drag.global_position
 press_key(game,KEY_R)
 Input.action_press("forward")
 for i in range(60):
  await physics_frame
 Input.action_release("forward")
 check(game.grass.cut_count == 0,"lowered drag on actual grass cannot mow it")
 check(game.infield.prepared_count == count,"grass cannot inflate dirt progress")
 press_key(game,KEY_R)
 for i in range(60):
  await physics_frame
 # Reverse over previously untouched dirt, so overlap cannot hide a scoring bug.
 game.mower.global_position = Vector3(-10,0.05,-10)
 game.mower.rotation.y = PI/4
 game.mower.speed = 0
 game.mower.previous_drag = game.mower.drag.global_position
 press_key(game,KEY_R)
 Input.action_press("back")
 for i in range(60):
  await physics_frame
 Input.action_release("back")
 check(count == game.infield.prepared_count,"reversing cannot prepare new dirt")
 for i in range(60):
  await physics_frame
 game.interact()
 check(not game.driving and not game.player.seated,"exit restores walking with drag attached")
 check(count == game.infield.prepared_count,"prepared dirt persists after exit")
 check(not game.swap_work_tool(),"tool swaps are blocked away from the bay")
 game.mower.global_position = Vector3(30,0.05,-19)
 game.mower.speed = 0
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 check(game.swap_work_tool(),"can return to bay and re-equip mower")
 check(game.mower.active_tool == RidingMower.WorkTool.MOWER and game.mower.deck.visible,"mowing deck is restored")
 check(count == game.infield.prepared_count,"swapping equipment preserves dirt progress")
 print("Drag gameplay failures: ",failures)
 game.queue_free()
 await create_timer(0.1).timeout
 quit(1 if failures else 0)
