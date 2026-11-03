extends SceneTree
var checks := 0
var failures := 0
const CAREER := "user://test-club-gameplay-career.dat"
const AUTO := "user://test-club-gameplay-auto.dat"
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func scene() -> Node:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = CAREER
 g.autosave_save_path = AUTO
 g.settings_save_path = "user://test-club-gameplay-settings.cfg"
 g.tutorial_enabled = false
 root.add_child(g)
 g.autosave.set_process(false)
 return g
func dispose(g: Node) -> void:
 paused = false
 g.queue_free()
 await create_timer(0.15).timeout
func finish_home(g: Node) -> void:
 g.club.prepare()
 # Full surface fixtures exercise the real director/result/claim path; human tools
 # are covered by the existing gameplay suites rather than a full park route here.
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
func fund(g: Node) -> void:
 var s := ShiftSession.new()
 s.start("full")
 s.set_progress([100,100,100,100,100],[true,true,true,true,true])
 s.advance(1)
 g.shift.career.claim(s.attempt_id,s.get_result())
 s.free()
func run() -> void:
 for path in [CAREER,AUTO,"user://test-club-gameplay-settings.cfg"]:
  DirAccess.remove_absolute(path)
 var g := scene()
 await process_frame
 var layout_hash: String = g.shift.save_store.layout(g)
 check(not g.shift.start_shift("home_game") and not g.shift.career.club_started(),"home-game prep is locked until the groundskeeper job is accepted")
 check(g.grass.deck_width == 2.4 and g.club.world.seat_count == 0 and g.stadium.grandstands[0].visible,"sandbox equipment and park remain unchanged before enrollment")
 g.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 var original_cut: int = g.grass.cut_count
 g.shift.open_board()
 g.shift.overlay.club_button.pressed.emit()
 for pressed in [true,false]:
  var event := InputEventJoypadButton.new()
  event.button_index = JOY_BUTTON_A
  event.pressed = pressed
  Input.parse_input_event(event)
  await process_frame
 check(g.shift.career.club_started(),"taking the job through controller confirmation starts the saved Owls story")
 check(g.shift.overlay.club_panel.prep_button.has_focus(),"controller focus moves to home prep after accepting the job")
 g.shift.close_board()
 await process_frame
 check(g.grass.deck_width == 1.8 and g.mower.deck.scale.x == 0.75 and g.mower.drag.working_width == 2.2 and g.moisture.application_rate == 0.55,"unowned equipment becomes the weaker starter kit")
 g.grass.reset_state()
 g.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 check(g.grass.cut_count < original_cut,"starter deck actually cuts less area")
 check(g.club.world.seat_count == 120 and g.club.world.crowd_count == 0 and not g.stadium.grandstands[0].visible,"club starts with two small empty bleacher banks instead of built-out stands")
 var disabled := true
 for stand in g.stadium.grandstands:
  for shape in stand.find_children("*","CollisionShape3D",true,false):
   disabled = disabled and shape.disabled
 check(disabled,"hidden legacy grandstands have no ghost colliders")
 check(g.shift.save_store.layout(g) == layout_hash,"stadium story visuals do not change the field-save layout signature")
 check(g.hud.park_label.text.contains("48 fans") and g.shift.overlay.club_panel.chapter.text.contains("Chapter 1"),"HUD and manager dialogue reflect the starting club")
 g.tutorial.active = true
 check(g.club.prepare() and g.shift.session.profile_id == "home_game" and g.shift.session.start_mode == "game_day","Clubhouse starts its dedicated worn-field prep checklist")
 check(not g.tutorial.active and g.settings.tutorial_done,"starting story work cleanly ends the practice guide before any paid prep")
 check(not g.club.join() and not g.club.host() and not g.club.build("bleachers"),"active paid work blocks story transitions and construction")
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
 var id: String = g.shift.session.attempt_id
 check(paused and g.shift.session.phase == ShiftSession.Phase.FINISHED and g.shift.career.balance == 160,"completed home prep earns the normal once-only 160-credit wage")
 check(g.shift.overlay.heading.text == "HOME GAME PREPARED" and not g.shift.overlay.club_panel.host_button.disabled,"results direct the player to host the pending home game")
 check(not g.club.prepare(),"another home prep cannot replace an unhosted completed date")
 g.autosave.since_write = 1
 check(g.autosave.write_now(),"paid-but-unhosted home prep autosaves")
 var saved: Dictionary = g.autosave.store.read(g)
 await dispose(g)
 g = scene()
 await process_frame
 check(paused and g.shift.overlay.resume_card.visible and not g.autosave.candidate.is_empty(),"startup offers paid home prep that still needs its game hosted")
 check(g.autosave.resume() and g.shift.career.balance == 160,"resuming pending club prep does not repay its wage")
 check(g.club.host() and g.shift.career.balance == 244 and g.shift.career.club.fans == 68,"hosting converts finished prep into gate profit and new supporters")
 check(paused and g.shift.session.phase == ShiftSession.Phase.PRACTICE and g.shift.counts() == g.shift.totals(),"volunteers finish routine work only after paid prep has ended, with world still paused")
 var budget: int = g.shift.career.balance
 g.shift.session.advance(600)
 check(g.shift.career.balance == budget,"volunteer work creates no extra paid attempt or coverage reward")
 check(g.club.world.crowd_count == 48 and g.club.world.seat_count == 120,"the first actual crowd appears in the starter bleachers")
 check(g.club.world.structures.get_child_count() < 20,"supporters use batches rather than a scene node for every person")
 check(g.shift.save_store.validate(g.shift.save_store.capture(g,g.shift.session),g),"post-game volunteer field remains a valid snapshot")
 check(g.shift.career.host_game(id).status == "recorded" and g.shift.career.balance == budget,"old field rewind cannot settle the home date again")
 var rebuilt: int = g.club.world.rebuilds
 check(g.shift.career.purchase("hose_nozzle") and g.moisture.application_rate == 1.0,"game income can replace a weak tool with its better version")
 g.shift.apply_upgrades()
 g.club.sync()
 check(g.club.world.rebuilds == rebuilt,"tool and budget changes do not rebuild unchanged spectator geometry")
 for i in range(2):
  finish_home(g)
  g.club.host()
 check(g.shift.career.club.fans == 108 and g.club.build("bleachers"),"repeated home dates unlock an affordable seating expansion")
 check(g.club.world.seat_count == 240 and g.shift.career.club.capacity == 240,"bought seats physically appear and match economic capacity")
 fund(g)
 check(g.club.build("snack_shack") and g.club.world.structures.has_node("OwlsSnackShack"),"amenity purchase creates a real snack shack")
 fund(g)
 check(g.shift.career.purchase("wide_deck") and g.grass.deck_width == 3.0 and g.mower.deck.scale.x == 1.25,"starter deck upgrades to the full 3.0 m working footprint")
 while g.shift.career.club.fans < 200:
  finish_home(g)
  g.club.host()
 check(g.club.build("grandstand") and g.club.world.seat_count == 480,"later story investment adds the covered 480-seat layout")
 check(g.club.world.structures.find_children("CoveredStand","Node3D",false,false).size() > 0,"grandstand investment visibly adds roofs")
 check(g.shift.save_store.layout(g) == layout_hash,"all stadium tiers preserve masks, protected areas and old field compatibility")
 var final_budget: int = g.shift.career.balance
 var final_fans: int = g.shift.career.club.fans
 # Leave the old pre-host autosave on disk; the career ledger proves it was settled.
 await dispose(g)
 g = scene()
 await process_frame
 check(not paused and not g.shift.overlay.resume_card.visible,"an already hosted saved result is not offered or paid again on startup")
 check(g.shift.career.balance == final_budget and g.shift.career.club.fans == final_fans and g.club.world.seat_count == 480 and g.moisture.application_rate == 1.0 and g.grass.deck_width == 3.0,"relaunch restores the club, its built park and better tools")
 check(g.shift.save_store.restore(g,g.shift,saved) and g.shift.career.balance == final_budget and g.club.world.seat_count == 480,"loading an old field cannot roll back club finances or construction")
 await dispose(g)
 for path in [CAREER,AUTO,"user://test-club-gameplay-settings.cfg"]:
  DirAccess.remove_absolute(path)
 print("Club gameplay: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
