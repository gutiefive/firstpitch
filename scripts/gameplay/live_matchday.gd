class_name LiveMatchday
extends Node
const G = preload("res://scripts/gameplay/geometry.gd")
const LENGTH := 360.0
const FINAL := LENGTH*40.0/47.0
var game: Node
var active := false
var viewing := false
var visit_time := 0.0
var jobs: Array[Dictionary] = []
var job_root: Node3D
var hud: CanvasLayer
var panel: PanelContainer
var title: Label
var tasks: Label
var hint: Label
var feedback := "Explore the concourse, watch the game, or help the crew."
var carrying := false
var parcel: Node3D
var broom: Node3D
var on_foot_time := 0.0
var queue_seconds := 0.0
var event_spawned := false
var pending_input := {}
var pending_host := ""
var satisfaction: Label
var announcement: Label
var visit_buildings := PackedStringArray()
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 hud = CanvasLayer.new()
 hud.layer = 11
 add_child(hud)
 panel = PanelContainer.new()
 panel.theme = GameUI.theme()
 panel.position = Vector2(24,24)
 panel.custom_minimum_size.x = 400
 panel.add_theme_stylebox_override("panel",GameUI.box(GameUI.BG,16))
 hud.add_child(panel)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 panel.add_child(content)
 GameUI.label(content,"LIVE MATCHDAY / ON FOOT",12,GameUI.ACCENT)
 title = GameUI.label(content,"",21)
 tasks = GameUI.label(content,"",13)
 hint = GameUI.label(content,"",13,GameUI.GOLD)
 var controls := HBoxContainer.new()
 controls.add_theme_constant_override("separation",8)
 content.add_child(controls)
 var broadcast := GameUI.button(controls,"Broadcast · V / RS")
 var leave := GameUI.button(controls,"End visit · B")
 for button in [broadcast,leave]:
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 broadcast.pressed.connect(show_broadcast)
 leave.pressed.connect(end_visit)
 satisfaction = GameUI.label(content,"",12,GameUI.ACCENT)
 announcement = GameUI.label(content,"",12,GameUI.GOLD)
 GameUI.label(content,"E / X: help nearby · Tab: pause\nFinish the game and spend 30s on foot for a park review.",11,GameUI.MUTED)
 hud.visible = false
func start(at: float = 0) -> bool:
 if active:
  resume_walk(at)
  return true
 if not game.club.can_watch():
  return false
 visit_buildings = game.shift.career.club.buildings.duplicate()
 on_foot_time = 0
 queue_seconds = 0
 event_spawned = false
 active = true
 viewing = false
 visit_time = clampf(at/OpeningGates.DURATION*LENGTH,0,LENGTH)
 feedback = "Explore the concourse, watch the game, or help the crew."
 game.shift.reset_equipment()
 game.player.position = Vector3(4,0.1,25)
 game.pivot.global_position = game.player.position+Vector3.UP*1.5
 game.club.atmosphere.begin(int(game.shift.career.club.games))
 game.club.matchday.begin(game.shift.career.club.last)
 game.club.world.reserve_seats(game.club.matchday.agents.size())
 game.club.matchday.begin_routines()
 create_jobs()
 broom = Node3D.new()
 game.player.visual.add_child(broom)
 broom.position = Vector3(0.22,0,-0.55)
 G.cylinder(broom,Vector3(0,0.75,0),0.025,1.35,Color("a78a60"))
 G.box(broom,Vector3(0,0.1,0),Vector3(0.48,0.1,0.15),Color("416c64"))
 for i in range(10):
  G.box(broom,Vector3(-0.21+i*0.047,0.025,0),Vector3(0.025,0.09,0.12),Color("c1a56d"))
 broom.visible = false
 game.shift.close_board()
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 game.hud.visible = false
 game.shift.overlay.status_panel.visible = false
 hud.visible = true
 game.club.matchday.set_time(visit_time/LENGTH*OpeningGates.DURATION)
 refresh_hud()
 return true
func resume_walk(at: float) -> void:
 viewing = false
 hud.visible = true
 visit_time = maxf(visit_time,at/OpeningGates.DURATION*LENGTH)
 game.shift.close_board()
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 refresh_hud()
func show_broadcast() -> void:
 if not active or viewing:
  return
 viewing = true
 game.player.visual.cleaning_pose = false
 if broom != null:
  broom.visible = false
 hud.visible = false
 game.shift.open_board()
 game.shift.overlay.club_button.pressed.emit()
 game.shift.overlay.club_panel.show_section("results")
 game.club.opening.present(game.shift.career.club.last)
 game.club.opening.elapsed = minf(OpeningGates.DURATION-0.1,visit_time/LENGTH*OpeningGates.DURATION)
 game.club.opening.update_view(game.club.opening.elapsed/OpeningGates.DURATION)
func end_visit(show_results: bool = true) -> void:
 if not active:
  return
 if visit_time >= FINAL and on_foot_time >= 30:
  pending_host = game.shift.career.latest_host_id()
  var done := PackedStringArray()
  for job in jobs:
   if job.state == "done":
    done.append(job.id)
  pending_input = {"seconds":mini(3600,int(on_foot_time)),"queue":mini(mini(3600,int(on_foot_time)),int(queue_seconds)),"completed":done,"buildings":visit_buildings.duplicate()}
 game.club.atmosphere.end()
 var completed := 0
 for job in jobs:
  completed += int(job.state == "done")
 game.club.message = "Matchday crew: %d / %d optional jobs handled. Mara: Thanks for looking after our park." % [completed,jobs.size()]
 active = false
 viewing = false
 carrying = false
 game.player.visual.pushing_pose = false
 game.player.visual.carrying_pose = false
 game.player.visual.cleaning_pose = false
 if broom != null:
  broom.queue_free()
  broom = null
 if job_root != null:
  job_root.queue_free()
  job_root = null
 if parcel != null:
  parcel.queue_free()
  parcel = null
 hud.visible = false
 game.hud.visible = true
 game.shift.overlay.status_panel.visible = true
 game.club.world.reserve_seats(0)
 game.club.matchday.signature = ""
 game.club.matchday.sync(game.shift.career.club)
 game.club.matchday.complete()
 game.shift.overlay.club_panel.refresh()
 game.shift.overlay.refresh()
 if show_results:
  game.shift.open_board()
  game.shift.overlay.club_button.pressed.emit()
  game.shift.overlay.club_panel.show_section("results")
func create_jobs() -> void:
 jobs.clear()
 job_root = Node3D.new()
 job_root.name = "MatchdayServiceJobs"
 game.add_child(job_root)
 add_job("spill","Clean spilled drinks",Vector3(10,0.06,24),2)
 add_job("eli","Help Eli find his section",Vector3(-7,0.05,24),0)
 if "snack_shack" in game.shift.career.club.buildings or "grill_stand" in game.shift.career.club.buildings:
  add_job("supply","Deliver a concession supply crate",Vector3(4,0.05,24),0)
func add_job(id: String,label: String,point: Vector3,duration: float) -> void:
 var marker := Node3D.new()
 marker.position = point
 job_root.add_child(marker)
 if id in ["spill","litter"]:
  G.sphere(marker,Vector3(0,0.02,0),Vector3(1.5,0.03,0.85),Color("715640"))
  for x in [-0.35,0,0.4]:
   var cup := G.cylinder(marker,Vector3(x,0.07,0),0.07,0.14,Color("e0d0a1"))
   cup.rotation.z = 1.2
 elif id == "lost":
  game.club.matchday.person(marker,Color("829eaa"),1)
 elif id == "supply":
  G.box(marker,Vector3(0,0.3,0),Vector3(0.65,0.6,0.45),Color("a18b62"))
 var sign := G.label(marker,label,Vector3(0,2.3,0),24)
 sign.pixel_size = 0.008
 sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 jobs.append({"id":id,"title":label,"point":point,"progress":0.0,"duration":duration,"state":"available","marker":marker,"label":sign})
func near_job() -> int:
 for i in range(jobs.size()):
  if jobs[i].state in ["available","carrying"] and game.player.position.distance_to(jobs[i].point) < 2:
   return i
 return -1
func interact_job() -> void:
 var index := near_job()
 if index < 0:
  return
 var job: Dictionary = jobs[index]
 if job.id == "supply":
  if job.state == "available":
   carrying = true
   game.player.visual.carrying_pose = true
   job.state = "carrying"
   job.point = Vector3(30,0.05,16) if "snack_shack" in game.shift.career.club.buildings else Vector3(-31,0.05,15)
   for child in job.marker.get_children():
    if child is MeshInstance3D:
     child.visible = false
   job.marker.position = job.point
   parcel = G.box(game.player.visual,Vector3(0,1,-0.45),Vector3(0.55,0.4,0.35),Color("a18b62"))
   for side in [-1,1]:
    G.box(parcel,Vector3(side*0.28,0,0),Vector3(0.02,0.09,0.18),Color("4d5b54"))
   var stamp := G.label(parcel,"OWLS",Vector3(0,0,-0.18),22)
   stamp.pixel_size = 0.004
   stamp.rotation.y = PI
   feedback = "Crate collected. Carry it to the marked concession counter."
  else:
   carrying = false
   game.player.visual.carrying_pose = false
   if parcel != null:
    parcel.queue_free()
    parcel = null
   finish_job(job,"Leni: Just what we needed. Thanks for keeping service moving.")
 elif job.id == "eli":
  job.state = "escorting"
  job.trail = PackedVector3Array([game.club.matchday.regular.position])
  job.point = Vector3(-7,0.05,14.4)
  job.marker.position = job.point
  feedback = "Eli: Lead the way! Walk with him to the marked section behind the stands."
 elif job.id == "lost":
  finish_job(job,"Visitor: Found it! Thanks for pointing our family toward the right section.")
 elif job.id in ["spill","litter","rush"]:
  feedback = "Hold %s while standing beside the spill to clean it." % game.binding_text("interact")
 refresh_hud()
func finish_job(job: Dictionary,message: String) -> void:
 job.state = "done"
 if job.id == "lost":
  job.label.visible = false
 else:
  job.marker.visible = false
 feedback = message
func advance_jobs(delta: float) -> void:
 game.player.visual.cleaning_pose = false
 if broom != null:
  broom.visible = false
 for job in jobs:
  if job.state == "done":
   if job.id == "lost":
    job.marker.position = job.marker.position.move_toward(Vector3(7,0.05,24),delta)
   continue
  var distance: float = game.player.position.distance_to(job.point)
  if job.id in ["spill","litter","rush"] and Input.is_action_pressed("interact") and distance < 2 and Vector2(game.player.velocity.x,game.player.velocity.z).length() < 0.5:
   if job.id != "rush":
    game.player.visual.cleaning_pose = true
    broom.visible = true
    broom.rotation.y = sin(game.player.visual.work_phase*7)*0.22
   job.progress += delta
   if job.progress >= job.duration:
    game.player.visual.cleaning_pose = false
    if broom != null:
     broom.visible = false
    finish_job(job,"Leni: Rush handled. The line is moving again." if job.id == "rush" else "Crew: The walkway is clear. Thanks for looking after the families.")
  if job.state == "escorting":
   var regular: Node3D = game.club.matchday.regular
   var trail: PackedVector3Array = job.trail
   if trail.is_empty() or trail[-1].distance_to(game.player.position) > 0.8:
    trail.append(game.player.position)
   if trail.size() > 128:
    trail.remove_at(0)
   if not trail.is_empty() and regular.position.distance_to(trail[0]) < 0.5:
    trail.remove_at(0)
   if not trail.is_empty():
    var target: Vector3 = trail[0]
    regular.position = regular.position.move_toward(target,2.8*delta)
    if Vector2(regular.position.x-target.x,regular.position.z-target.z).length_squared() > 0.01:
     regular.look_at(Vector3(target.x,regular.position.y,target.z))
    regular.get_node("LegLeft").rotation.x = sin(visit_time*8)*0.3
    regular.get_node("LegRight").rotation.x = -sin(visit_time*8)*0.3
   job.trail = trail
   if distance < 1.5 and regular.position.distance_to(job.point) < 2:
    regular.get_node("LegLeft").rotation.x = 0
    regular.get_node("LegRight").rotation.x = 0
    finish_job(job,"Eli: There's my section. Best seat in town. Thank you!")
func _process(delta: float) -> void:
 if not active:
  return
 if viewing:
  visit_time = maxf(visit_time,game.club.opening.elapsed/OpeningGates.DURATION*LENGTH)
  return
 hud.visible = not game.shift.overlay.modal.visible
 if get_tree().paused:
  return
 visit_time += delta
 on_foot_time += delta
 var queued := 0
 for fan in game.club.matchday.agents:
  queued += int(fan.state == "queue")
 queue_seconds += delta*queued/maxi(1,game.club.matchday.agents.size())
 if visit_time >= 130 and visit_time < FINAL and not event_spawned:
  spawn_event()
 game.club.world.show_static_crowd(visit_time < FINAL+30)
 game.club.matchday.set_time(minf(47,visit_time/LENGTH*47))
 # Live-game visitors stay behind the field; they can use stands and public paths.
 if game.player.position.z < 6.5:
  game.player.position.z = 6.5
  game.player.velocity.z = maxf(0,game.player.velocity.z)
  feedback = "The game is live. Please stay in the stands and public concourse."
 advance_jobs(delta)
 refresh_hud()
func refresh_hud() -> void:
 if not active:
  return
 var park: MatchdayPark = game.club.matchday
 title.text = "Owls %d · %s %d\n%s" % [park.home_runs,park.fixture.get("opponent","Visitors"),park.away_runs,"FINAL" if visit_time >= FINAL else "Inning %d" % park.inning if park.inning > 0 else "First pitch in "+ShiftSession.clock_text(maxf(0,13.0/47*LENGTH-visit_time))]
 var lines := PackedStringArray()
 for job in jobs:
  lines.append(("✓ " if job.state == "done" else "· ")+String(job.title)+(" · %.0f%%" % (job.progress/job.duration*100) if job.duration > 0 and job.progress > 0 and job.state != "done" else ""))
 tasks.text = "OPTIONAL CREW JOBS\n"+"\n".join(lines)
 var preview := ParkSatisfaction.evaluate(game.shift.career.club,{"seconds":maxi(30,mini(3600,int(on_foot_time))),"queue":mini(mini(3600,int(on_foot_time)),int(queue_seconds)),"completed":completed_jobs(),"buildings":visit_buildings})
 satisfaction.text = "Fan satisfaction: %d / 100 · %d / 5 stars" % [preview.rating,preview.stars] if not preview.is_empty() else "Park review available after the final."
 announcement.text = "PA · "+game.club.atmosphere.caption
 var nearby := near_job()
 hint.text = ("Hold %s · %s" if jobs[nearby].id in ["spill","litter","rush"] else "Press %s · %s") % [game.binding_text("interact"),jobs[nearby].title] if nearby >= 0 else feedback
func _input(event: InputEvent) -> void:
 if not active or viewing or get_tree().paused or (event is InputEventKey and event.echo):
  return
 if (event is InputEventKey and event.pressed and event.physical_keycode == KEY_V) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_STICK):
  show_broadcast()
  get_viewport().set_input_as_handled()
 elif (event is InputEventKey and event.pressed and event.physical_keycode == KEY_B) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
  end_visit()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("interact"):
  interact_job()
  get_viewport().set_input_as_handled()

func completed_jobs() -> PackedStringArray:
 var done := PackedStringArray()
 for job in jobs:
  if job.state == "done":
   done.append(job.id)
 return done
func spawn_event() -> void:
 event_spawned = true
 var id := ParkSatisfaction.event_for(int(game.shift.career.club.games),visit_buildings)
 if id == "litter":
  add_job(id,"Clear the concourse litter",Vector3(-13,0.06,24),3)
 elif id == "rush":
  add_job(id,"Help serve the concession rush",Vector3(30,0.05,16) if "snack_shack" in game.shift.career.club.buildings else Vector3(-31,0.05,15),3)
 else:
  add_job(id,"Give a visiting family directions",Vector3(13,0.05,24),0)
 feedback = "MATCHDAY EVENT · "+String(jobs[-1].title)
 game.club.atmosphere.announce(feedback)
func queue_relief() -> bool:
 for job in jobs:
  if job.id == "rush" and job.state == "done":
   return true
 return false
func service_report() -> Dictionary:
 var career: CareerProfile = game.shift.career
 var id := career.latest_host_id()
 if career.club.services.has(id):
  return career.club.services[id]
 return ParkSatisfaction.evaluate(career.club,pending_input) if pending_host == id else {}
func claim_bonus() -> bool:
 if active or not game.club.available() or pending_host != game.shift.career.latest_host_id():
  return false
 var ok: bool = game.shift.career.claim_service(pending_host,pending_input)
 if ok:
  pending_input = {}
  game.club.message = "Mara: A good night at the park brings people back. Park bonus settled."
 game.club.sync()
 return ok
