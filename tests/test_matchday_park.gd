extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func idle(n: int = 3) -> void:
 for i in range(n):
  await process_frame
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless":
  return
 await idle()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-alive-"+name+".png")
func complete(g: Node) -> void:
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
func host(g: Node) -> void:
 g.club.prepare()
 complete(g)
 g.club.host()
func run() -> void:
 root.size = Vector2i(1280,720)
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://matchday-park-career.dat"
 g.settings_save_path = "user://matchday-park-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await idle(15)
 var park: MatchdayPark = g.club.matchday
 check(park.agents.is_empty() and not park.actors.visible,"new park has no invented matchday crowd or players")
 g.club.join()
 check(not "Six home dates" in " ".join(park.story_lines),"new club story never claims an unplayed season is complete")
 host(g)
 g.club.opening.set_process(false)
 park.set_process(false)
 g.club.life._process(0.1)
 check(g.club.life.targets.crowd and not g.club.life.loops.crowd.stream_paused,"crowd ambience remains active during the paused matchday show")
 check(g.club.opening.active and park.hosted and park.stage == "arrivals","committed hosting begins arrivals")
 check(park.agents.size() == 16 and park.agents.size() <= 28,"opening crowd uses bounded representative moving fans")
 var career: Dictionary = g.shift.career.data.duplicate(true)
 var money: int = g.shift.career.balance
 var first: Vector3 = park.agents[0].node.position
 for i in range(180):
  park.advance(1.0/60)
 check(park.agents[0].node.position.distance_to(first) > 2,"fans actually walk along arrival route")
 check(absf(park.agents[0].node.get_node("LegLeft").rotation.x) > 0.01,"walking supporters animate their legs")
 var clear := true
 for a in park.agents:
  for point in a.route:
   clear = clear and not (absf(point.x) < 2.6 and point.z > 27 and point.z < 31)
 check(clear,"arrival waypoints route around the solid ticket booth")
 check(park.find_children("*","CollisionShape3D",true,false).is_empty(),"decorative supporters do not block players or tool physics")
 await capture("arrival")
 g.club.opening.update_view(9.0/OpeningGates.DURATION)
 check(park.stage == "concourse" and not park.actors.visible,"concourse stage precedes baseball action")
 g.club.opening.update_view(20.0/OpeningGates.DURATION)
 check(park.stage == "game" and park.inning == 3 and park.actors.visible,"condensed game advances into third inning with visible players")
 var ball: Vector3 = park.ball.position
 var runner: Vector3 = park.runner.position
 park.set_time(20.4)
 check(park.ball.position != ball and park.runner.position != runner,"pitch, batted ball and baserunner move")
 var score := [park.home_runs,park.away_runs]
 park.set_time(20.4)
 check(score == [park.home_runs,park.away_runs],"same committed date and inning produce stable score")
 await capture("game")
 g.club.opening.update_view(41.0/OpeningGates.DURATION)
 check(park.inning == 9 and park.stage == "stories" and not park.actors.visible,"ninth inning resolves to final and town story beat")
 check(park.story_lines.size() >= 4 and park.story_lines[2].contains("Someday"),"unbuilt snack stand has an appropriate Leni story")
 check(g.shift.career.data == career and g.shift.career.balance == money,"match simulation never changes committed finances or records")
 g.club.opening.finish()
 check(not g.club.opening.active and not park.actors.visible and park.stage == "stories","skip safely resolves presentation and stops baseball actors")
 g.club.life._process(0.1)
 check(not g.club.life.targets.crowd and (not g.club.life.loops.crowd.playing or g.club.life.loops.crowd.stream_paused),"ordinary paused recap restores quiet ambience")
 var paused_position: Vector3 = park.agents[0].node.position
 park._process(1)
 check(park.agents[0].node.position == paused_position,"ordinary paused menus freeze walking supporters")
 g.shift.close_board()
 park._process(0.1)
 check(park.agents[0].node.position != paused_position,"moving park life continues when player returns to field")
 g.club.prepare()
 park._process(0.1)
 check(not park.agents[0].node.visible and not park.actors.visible,"next prep hides public game activity and baseball actors")
 complete(g)
 g.club.host()
 g.club.opening.finish()
 host(g)
 g.club.opening.finish()
 host(g)
 g.club.opening.finish()
 for i in range(4):
  var shift := ShiftSession.new()
  shift.start("full")
  shift.set_progress([100,100,100,100,100],[true,true,true,true,true])
  shift.advance(1)
  g.shift.career.claim(shift.attempt_id,shift.get_result())
  shift.free()
 check(g.club.build("bleachers") and g.club.build("snack_shack") and g.club.build("scoreboard"),"real ledger-funded stadium upgrades still build")
 await idle()
 check(park.staff_count == 1 and park.agents.size() <= 28,"built concessions gain a worker with bounded fan population")
 check(park.story_lines[1].contains("neighbors") and park.story_lines[2].contains("first order"),"regular and vendor story lines respond to owned buildings")
 var queue := false
 for a in park.agents:
  for point in a.route:
   queue = queue or (point.x > 29 and point.z == 16)
 check(queue,"snack upgrade creates a routed concession queue destination")
 var waiting := 0
 for a in park.agents:
  waiting += int(a.node.position.x > 29 and a.node.position.z == 16)
 check(waiting > 0,"early regulars visibly occupy built concession queues during arrivals")
 park.set_time(25)
 check(park.scoreboards.size() == 1 and park.scoreboards[0].text.contains("INNING 5"),"purchased scoreboard displays live inning and score")
 g.club.opening.present(g.shift.career.club.last)
 g.club.opening.set_process(false)
 g.club.opening.update_view(9.0/OpeningGates.DURATION)
 for i in range(360):
  park.advance(1.0/60)
 await capture("concessions")
 g.club.opening.update_view(42.0/OpeningGates.DURATION)
 await capture("stories")
 check(g.shift.overlay.club_panel.town_voices.text.contains("Leni"),"town conversations remain readable in the Clubhouse")
 var presentations: int = g.club.opening.presentations
 g.club.opening.finish()
 check(not g.club.host() and g.club.opening.presentations == presentations,"duplicate settlement cannot replay or pay a matchday")
 var saved: Dictionary = g.shift.career.data.duplicate(true)
 g.queue_free()
 await idle(4)
 var profile := CareerProfile.new()
 profile.path = "user://matchday-park-career.dat"
 check(profile.load_profile() and profile.data == saved,"matchday leaves saved career ledger fully compatible")
 DirAccess.remove_absolute("user://matchday-park-career.dat")
 DirAccess.remove_absolute("user://matchday-park-settings.cfg")
 print("Matchday park: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
