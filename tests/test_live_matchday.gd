extends "res://tests/test_matchday_ui.gd"
func prep(g: Node) -> void:
 g.club.prepare()
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
 g.club.host()
func run() -> void:
 root.size = Vector2i(1280,720)
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://live-matchday-career.dat"
 g.settings_save_path = "user://live-matchday-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await idle(12)
 var live: LiveMatchday = g.club.live
 var park: MatchdayPark = g.club.matchday
 var show: OpeningGates = g.club.opening
 live.set_process(false)
 park.set_process(false)
 check(not live.start(),"unhosted park cannot enter live visit")
 g.club.join()
 prep(g)
 show.set_process(false)
 await click(show.walk_button)
 check(live.active and not show.active and not paused and not live.viewing,"broadcast Walk button enters playable park")
 check(not g.hud.visible and live.hud.visible and not g.driving and not g.watering.equipped,"visit uses its own HUD and stows work equipment")
 check(live.jobs.size() == 2,"starter park offers cleanup and guiding without inventing concessions")
 var from: Vector3 = g.player.position
 Input.action_press("forward")
 for i in range(20):
  await physics_frame
 Input.action_release("forward")
 check(g.player.position.distance_to(from) > 0.4,"real player controller walks during live matchday")
 g.player.velocity = Vector3.ZERO
 var money: int = g.shift.career.balance
 var ledger: Dictionary = g.shift.career.data.duplicate(true)
 var time := live.visit_time
 live._process(2)
 check(live.visit_time == time+2,"innings clock advances while walking")
 g.shift.open_board()
 live._process(2)
 check(live.visit_time == time+2,"ordinary pause board freezes live game")
 await click(g.shift.overlay.contracts_button)
 check(g.shift.overlay.contracts_panel.buttons.quick_mow.disabled,"paid contracts clearly lock while visiting")
 check(not g.shift.start_shift("training") and not g.club.prepare() and not g.club.build("snack_shack"),"live visit prevents conflicting prep and stadium construction")
 g.shift.close_board()
 g.player.position.z = 0
 live._process(0.01)
 check(g.player.position.z >= 6.5,"player cannot enter the live playing field")
 await pad(JOY_BUTTON_RIGHT_STICK)
 check(live.viewing and show.active and paused,"RS switches walking visit to broadcast")
 var clock := live.visit_time
 show.elapsed += 2
 live._process(0.1)
 check(live.visit_time > clock,"broadcast and walking share the same advancing match clock")
 await click(show.walk_button)
 check(live.active and not live.viewing and not paused,"Walk returns from broadcast without ending visit")
 g.player.position = Vector3(10,0.06,24)
 g.player.velocity = Vector3.ZERO
 var spill: Dictionary = live.jobs[0]
 live.advance_jobs(3)
 check(spill.state == "available" and spill.progress == 0,"standing near a spill without held interaction does not clean it")
 Input.action_press("interact")
 g.player.velocity.x = 2
 live.advance_jobs(3)
 check(spill.progress == 0,"cleanup requires stopping")
 g.player.velocity = Vector3.ZERO
 live.advance_jobs(1)
 check(spill.progress == 1 and spill.state == "available","cleanup tracks actual held work over time")
 live.refresh_hud()
 await capture("live-cleanup")
 live.advance_jobs(1.1)
 Input.action_release("interact")
 check(spill.state == "done" and not spill.marker.visible,"held cleanup removes spill and completes optional job")
 g.player.position = Vector3(-7,0.05,24)
 live.interact_job()
 var escort: Dictionary = live.jobs[1]
 check(escort.state == "escorting","Eli interaction begins escort instead of instantly completing")
 g.player.position = escort.point
 for i in range(160):
  live.advance_jobs(0.05)
 check(escort.state == "done" and park.regular.position.distance_to(escort.point) < 2,"Eli follows to the correct section and thanks the player")
 live.visit_time = 160
 park.set_time(live.visit_time/LiveMatchday.LENGTH*47)
 for i in range(1200):
  park.advance_routines(0.1)
 var seated := 0
 for a in park.agents:
  seated += int(a.state == "seated")
 print("SEATED ",seated," / ",park.agents.size())
 check(seated >= park.agents.size()/2,"supporters find reserved seats instead of endlessly circling")
 var seated_agent: Dictionary = {}
 for a in park.agents:
  if a.state == "seated":
   seated_agent = a
   break
 if not seated_agent.is_empty():
  seated_agent.last_inning = 0
  park.advance_routines(0.1)
 check(not seated_agent.is_empty() and seated_agent.node.get_node("ArmLeft").rotation.x < -1,"seated fans react when inning changes")
 live.refresh_hud()
 await capture("live-seating")
 live.visit_time = LiveMatchday.FINAL+1
 park.set_time(41)
 for i in range(2200):
  park.advance_routines(0.1)
 var departed := 0
 for a in park.agents:
  departed += int(a.state == "departed")
 print("DEPARTED ",departed," / ",park.agents.size())
 check(departed == park.agents.size(),"fans leave through gates after the final")
 live.visit_time = LiveMatchday.FINAL+40
 live._process(0)
 var static_visible := false
 for node in g.club.world.structures.get_children():
  if node.get_meta("club_crowd",false):
   static_visible = static_visible or node.visible
 check(not static_visible,"batched seated crowd clears after the final as walkers exit")
 await capture("live-final")
 check(g.shift.career.data == ledger and g.shift.career.balance == money,"walking, optional jobs and departure create no financial mutations")
 g.shift.open_board()
 live._process(0)
 await click(g.shift.overlay.end_button)
 check(not live.active and paused and g.hud.visible and g.shift.overlay.club_panel.selected_section == "results","end visit restores normal recap and HUD")
 prep(g)
 show.finish()
 check(g.club.build("snack_shack"),"second real gate income unlocks concession for delivery job")
 ledger = g.shift.career.data.duplicate(true)
 money = g.shift.career.balance
 check(live.start(),"a later visit starts from Results")
 var supply: Dictionary = live.jobs[2]
 var reserved := {}
 var visible_crowd := park.agents.size()
 for a in park.agents:
  reserved[a.seat] = true
 for node in g.club.world.structures.get_children():
  if node is MultiMeshInstance3D and node.get_meta("crowd_body",false):
   visible_crowd += node.multimesh.instance_count
 check(reserved.size() == park.agents.size(),"each walking supporter has a distinct reserved seat")
 check(visible_crowd == g.club.world.crowd_count,"reserved seats prevent duplicate seated and walking attendance")
 check(live.jobs.size() == 3 and supply.id == "supply","built concession unlocks optional supply delivery")
 g.player.position = supply.point
 live.interact_job()
 check(live.carrying and supply.state == "carrying" and live.parcel != null,"supply pickup equips visible carried crate")
 live.interact_job()
 check(supply.state == "carrying","delivery cannot complete at pickup point")
 g.player.position = supply.point
 live.interact_job()
 check(supply.state == "done" and not live.carrying,"carrying crate to correct counter completes delivery")
 live.visit_time = 150
 live._process(0.01)
 for i in range(1200):
  park.advance_routines(0.1)
 var concession_seated := 0
 for a in park.agents:
  concession_seated += int(a.state == "seated")
 check(concession_seated > 0,"concession trips also return supporters to their sections")
 g.player.position = Vector3(23,0.1,15)
 g.yaw = -0.9
 g.pitch = -0.25
 await idle(8)
 await capture("live-jobs")
 check(g.shift.career.data == ledger and g.shift.career.balance == money,"delivery never pays the settled game a second time")
 live.show_broadcast()
 show.finish()
 check(not live.active and not show.active and paused and g.shift.overlay.club_panel.recap_continue.has_focus(),"Results from broadcast fully ends visit and restores actionable focus")
 check(not g.shift.overlay.club_panel.walk_button.disabled,"another explicit visit is available after cleanup")
 live.start()
 g.player.position = live.jobs[2].point
 live.interact_job()
 live.end_visit()
 check(live.parcel == null and not g.player.visual.pushing_pose,"ending a visit while carrying safely removes crate and carry pose")
 check(live.start(),"a fresh visit can start after aborting a delivery")
 live.end_visit()
 g.queue_free()
 await idle(4)
 DirAccess.remove_absolute("user://live-matchday-career.dat")
 DirAccess.remove_absolute("user://live-matchday-settings.cfg")
 print("Live matchday: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
