extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func complete(g: Node) -> void:
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless":
  return
 for i in range(5):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-payoff-%s.png" % name)
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://stadium-life-career.dat"
 g.settings_save_path = "user://stadium-life-settings.cfg"
 g.autosave_enabled = false
 g.tutorial_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 var club: ClubDirector = g.club
 var c: CareerProfile = g.shift.career
 check(not club.opening.active and not club.life.loops.crowd.playing,"new park has no crowd sound or replayed gates presentation")
 club.join()
 check(g.mower.drag.working_width == 2.4 and g.moisture.application_rate == 0.65 and g.grass.deck_width == 1.8,"balanced starter kit remains weaker than purchased equipment")
 g.player.global_position = Vector3(8,0.05,-7)
 g.watering.set_equipped(true)
 for i in range(25):
  await physics_frame
 var first_wet := 0
 while g.moisture.wet_count == 0 and first_wet < 100:
  g.watering.apply_spray(Vector3(10,0,-10),1.0/60)
  first_wet += 1
 check(first_wet >= 55 and first_wet < 80,"starter hose can actually qualify a patch in roughly one second")
 club.prepare()
 complete(g)
 var original_path := c.path
 c.path = "user://missing-payoff-folder/career.dat"
 check(not club.host() and club.opening.presentations == 0 and c.balance == 160,"failed settlement never starts a celebration or changes earned wages")
 c.path = original_path
 check(club.host() and c.balance == 244,"balance pass leaves original opener payout exact")
 check(club.opening.active and paused and club.opening.presentations == 1,"successful hosting starts one presentation while the world stays paused")
 check(club.opening.cheer.playing and club.opening.latch.playing and not club.opening.cheer.stream_paused and not club.opening.latch.stream_paused,"opening cheer and gate cue play during paused presentation")
 check(club.opening.cheer.bus == "GroundsAmbience" and club.opening.latch.bus == "GroundsEffects","new sounds use existing independent volume buses")
 check(g.camera.current and club.opening.camera.current and club.opening.gates.size() == 2,"presentation uses its own viewport camera and two decorative gate leaves")
 var money := c.balance
 var opening := club.opening
 opening.set_process(false)
 opening.update_view(0.35)
 await capture("gates")
 opening.set_process(true)
 for pressed in [true,false]:
  var navigation := InputEventKey.new()
  navigation.keycode = KEY_DOWN
  navigation.physical_keycode = KEY_DOWN
  navigation.pressed = pressed
  Input.parse_input_event(navigation)
  for i in range(2):
   await process_frame
 var covered_focus: bool = g.shift.overlay.club_panel.recap_continue.has_focus()
 for pressed in [true,false]:
  var event := InputEventJoypadButton.new()
  event.device = 7
  event.button_index = JOY_BUTTON_A
  event.pressed = pressed
  Input.parse_input_event(event)
  for i in range(2):
   await process_frame
 check(not opening.active and c.balance == money and covered_focus and g.shift.overlay.club_panel.recap_continue.has_focus(),"native A skips presentation without spending money or advancing underlying UI")
 check(absf(opening.gates[0].rotation.y) > 1.5 and opening.view.render_target_update_mode == SubViewport.UPDATE_DISABLED,"skip leaves gates open and stops extra rendering")
 check(not club.host() and opening.presentations == 1,"duplicate hosting cannot replay cheer or gates")
 check(c.purchase("hose_nozzle") and g.moisture.application_rate == 1.0,"first home income still buys a meaningful hose upgrade")
 g.shift.close_board()
 g.player.global_position = Vector3(8,0.05,-7)
 g.moisture.reset_state()
 g.watering.set_equipped(true)
 for i in range(25):
  await physics_frame
 var upgraded_wet := 0
 while g.moisture.wet_count == 0 and upgraded_wet < 100:
  g.watering.apply_spray(Vector3(10,0,-10),1.0/60)
  upgraded_wet += 1
 check(upgraded_wet < first_wet*0.8,"purchased nozzle still reduces actual soak time by more than twenty percent")
 g.watering.set_equipped(false)
 g.moisture.fill_valid(0.8)
 club.life._process(1)
 check(club.life.targets.crowd and club.life.loops.crowd.playing,"postgame field has crowd ambience")
 check(not club.life.targets.snacks and not club.life.targets.grill,"unbuilt concessions remain silent")
 club.life.reaction_time = 17.9
 club.life._process(0.2)
 check(club.life.reactions == 1 and club.life.reaction.playing,"postgame crowd reacts periodically")
 for i in range(2):
  club.prepare()
  complete(g)
  club.host()
 club.opening.finish()
 check(club.build("snack_shack"),"early stadium investment remains affordable")
 g.shift.close_board()
 club.life._process(1)
 check(club.life.targets.snacks and club.life.loops.snacks.playing,"built snack shack gets localized concession ambience")
 g.audio.settings.set_level("ambience",0)
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("GroundsAmbience")),"ambience slider mutes crowd, reactions and concessions")
 g.audio.settings.set_level("ambience",0.4)
 club.prepare()
 club.life._process(1)
 check(not club.life.targets.crowd and not club.life.reaction.playing,"paid prep suppresses spectators' sounds and reactions")
 var heads: Node3D = club.world.structures.get_node("SupporterHeads")
 check(not heads.visible,"spectators are hidden while the crew prepares the next date")
 complete(g)
 club.host()
 while c.club.games < 6:
  club.prepare()
  complete(g)
  club.host()
 check(club.ownership.season == 1 and g.shift.overlay.club_panel.ownership_review.text.contains("Season 2 objective"),"sixth hosted date produces Mara's next-season ownership objective")
 check(opening.heading.text.contains("SEASON COMPLETE"),"home finale receives a season-complete presentation")
 opening._process(OpeningGates.DURATION+0.1)
 check(not opening.active and paused,"automatic presentation completion keeps postgame recap paused")
 await capture("ownership")
 var frozen_goal: Dictionary = club.ownership.objective.duplicate(true)
 club.prepare()
 var rollover_profile: String = g.shift.session.profile_id
 complete(g)
 club.host()
 opening.finish()
 check(c.club.games == 7 and rollover_profile == GameDay.profile(6) and club.ownership.season == 1 and club.ownership.objective == frozen_goal,"next-season prep and hosting retain the prior finale's concrete objective")
 var copy := CareerProfile.new()
 copy.path = c.path
 copy.load_profile()
 check(ClubOwnership.review(copy) == club.ownership,"ownership milestone and objective survive career reload")
 var store := FieldSave.new()
 check(store.validate(store.capture(g,g.shift.session),g),"presentation and sound changes preserve saved-field compatibility")
 var path := c.path
 var expected := club.ownership.duplicate(true)
 paused = false
 g.queue_free()
 await process_frame
 var fresh = load("res://scenes/main/main.tscn").instantiate()
 fresh.career_save_path = path
 fresh.settings_save_path = "user://stadium-life-settings.cfg"
 fresh.autosave_enabled = false
 fresh.tutorial_enabled = false
 root.add_child(fresh)
 await process_frame
 check(not fresh.club.opening.active and fresh.club.opening.presentations == 0 and fresh.club.ownership == expected,"scene relaunch restores ownership without replaying gates or cheer")
 DirAccess.remove_absolute(path)
 fresh.queue_free()
 await process_frame
 print("Stadium life: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
