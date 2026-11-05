class_name MatchdayPark
extends Node3D
# Decorative matchday simulation. Settlement remains owned by CareerProfile.
const G = preload("res://scripts/gameplay/geometry.gd")
var game: Node
var agents: Array[Dictionary] = []
var fielders: Array[Dictionary] = []
var actors: Node3D
var ball: MeshInstance3D
var runner: Node3D
var bat: Node3D
var score_sign: Label3D
var identity: Node3D
var signature := ""
var fixture := {}
var receipt := {}
var inning := 0
var home_runs := 0
var away_runs := 0
var stage := "quiet"
var clock := 0.0
var hosted := false
var story_lines := PackedStringArray()
var staff_count := 0
var workers: Array[Node3D] = []
var ambient_time := 0.0
var scoreboards: Array[Label3D] = []
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 identity = Node3D.new()
 add_child(identity)
 actors = Node3D.new()
 actors.name = "MatchdayPlayers"
 add_child(actors)
 for p in [Vector3(0,0.35,-18),Vector3(0,0,-1),Vector3(-18,0,-20),Vector3(18,0,-20),Vector3(-10,0,-30),Vector3(10,0,-30),Vector3(-25,0,-49),Vector3(0,0,-58),Vector3(25,0,-49)]:
  var player := person(actors,Color("e0d7bd"),2)
  player.position = p
  fielders.append({"node":player,"origin":p})
 var batter := actors.get_child(1) as Node3D
 bat = Node3D.new()
 bat.position = Vector3(0.32,1.05,-0.15)
 batter.add_child(bat)
 G.cylinder(bat,Vector3(0,0.4,0),0.04,0.8,Color("b89769"))
 runner = person(actors,Color("4e7f80"),1)
 ball = G.sphere(actors,Vector3(0,1,-18),Vector3.ONE*0.15,Color("f5eedc"))
 actors.visible = false
 score_sign = G.label(self,"",Vector3(-14,3.5,25),30)
 score_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 score_sign.pixel_size = 0.009
 score_sign.modulate = Color("f1db9f")
 score_sign.visible = false
func person(parent: Node3D,shirt: Color,index: int) -> Node3D:
 var root := Node3D.new()
 parent.add_child(root)
 var skin: Color = [Color("bd9279"),Color("8e6450"),Color("d2aa87")][posmod(index,3)]
 G.tailored_body(root,Vector3(0,1.08,0),shirt)
 G.sphere(root,Vector3(0,1.62,0),Vector3(0.30,0.36,0.29),skin)
 G.sphere(root,Vector3(0,1.77,0.02),Vector3(0.34,0.12,0.33),Color("244e53"))
 G.soft_box(root,Vector3(0,1.77,-0.13),Vector3(0.33,0.025,0.21),Color("244e53"))
 for x in [-0.06,0.06]:
  G.sphere(root,Vector3(x,1.65,-0.14),Vector3.ONE*0.023,Color("282f30"))
 for side in [-1,1]:
  var leg := Node3D.new()
  leg.name = "LegLeft" if side == -1 else "LegRight"
  leg.position = Vector3(side*0.12,0.79,0)
  root.add_child(leg)
  G.capsule(leg,Vector3(0,-0.31,0),0.085,0.66,Color("45535b"))
  G.soft_box(leg,Vector3(0,-0.67,-0.05),Vector3(0.19,0.12,0.28),Color("393c39"))
  var arm := G.capsule(root,Vector3(side*0.27,0.99,0),0.065,0.50,skin)
  arm.name = "ArmLeft" if side == -1 else "ArmRight"
 return root
func sync(state: Dictionary) -> void:
 var key := str([state.active,state.games,state.buildings])
 if key == signature:
  return
 signature = key
 for a in agents:
  a.node.queue_free()
 agents.clear()
 for node in identity.get_children():
  node.queue_free()
 staff_count = 0
 workers.clear()
 hosted = state.active and not state.last.is_empty()
 visible = state.active
 if not state.active:
  return
 fixture = ClubSchedule.fixture(maxi(0,int(state.games)-1))
 var count := mini(28,maxi(8,int(state.last.get("attendance",0))/3)) if hosted else 0
 var colors := [Color("c09e69"),Color("6f8580"),Color("9d6e5d"),Color("587186"),Color("b9bbaa")]
 for i in range(count):
  var fan := person(self,colors[i%colors.size()],i)
  fan.name = "MovingSupporter%d" % i
  fan.scale = Vector3.ONE*(0.80 if i%7 == 0 else 0.95+float(i%3)*0.04)
  var side := -1.0 if i%2 == 0 else 1.0
  # Routes pass either side of the solid ticket booth, then behind the stands.
  var lane: float = side*(4.0+float(i%3)*0.55)
  var destination := Vector3(side*(9+float(i%5)*3.8),0.05,24+float(i%3)*0.5)
  var route := PackedVector3Array([Vector3(lane,0.05,39+float(i%5)*1.4),Vector3(lane,0.05,33),Vector3(lane,0.05,25.2),destination])
  if "snack_shack" in state.buildings and side > 0:
   route.append(Vector3(27.9,0.05,24))
   route.append(Vector3(27.9,0.05,16))
   route.append(Vector3(30.5-float(i%3)*0.5,0.05,16))
  if "grill_stand" in state.buildings and side < 0:
   route.append(Vector3(-27.9,0.05,24))
   route.append(Vector3(-27.9,0.05,15))
   route.append(Vector3(-31+float(i%3)*0.5,0.05,15))
  # Walk back along the same clear approach rather than cutting through buildings.
  for j in range(route.size()-2,1,-1):
   route.append(route[j])
  fan.position = route[0]
  var target := 1
  var wait := float(i)*0.22
  # Early regulars already at service keep the concourse alive while arrivals enter.
  if route.size() > 8 and i >= 5 and (i%4 == 1 if side > 0 else i%4 == 0):
   fan.position = route[6]
   fan.rotation.y = PI
   target = 7
   wait = 8+float(i%5)
  agents.append({"node":fan,"route":route,"target":target,"wait":wait,"phase":float(i),"speed":1.1+float(i%4)*0.17})
 scoreboards.clear()
 for id in ["OwlsElectronicScoreboard","OwlsVideoBoard"]:
  var board: Node = game.club.world.structures.get_node_or_null(id)
  if board != null:
   for label in board.find_children("*","Label3D",true,false):
    scoreboards.append(label)
 build_identity(state)
 story_lines = stories(state)
func build_identity(state: Dictionary) -> void:
 var regular := person(identity,Color("6c8b7c"),1)
 regular.position = Vector3(-7,0.05,24)
 regular.rotation.y = PI
 var regular_name := G.label(identity,"ELI · SEASON-TICKET REGULAR",Vector3(-7,2.1,24),24)
 regular_name.pixel_size = 0.008
 regular_name.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 var items := {"bleachers":[Vector3(-15,0,24),"THE TOWN'S SECTION"],"grandstand":[Vector3(15,0,24),"COVERED SEATS · OWLS COUNTRY"],"snack_shack":[Vector3(28.5,0,16.5),"LENI'S LOCAL FAVORITES"],"grill_stand":[Vector3(-29,0,15),"HOT OFF THE GRILL"],"scoreboard":[Vector3(12,0,25),"FOLLOW EVERY INNING"],"video_board":[Vector3(-12,0,25),"MAKE SOME NOISE, CEDAR GROVE!"]}
 for id in state.buildings:
  var p: Vector3 = items[id][0]
  G.cylinder(identity,p+Vector3(0,1.1,0),0.045,2.2,Color("536362"))
  var sign := G.label(identity,items[id][1],p+Vector3(0,2.4,0),28)
  sign.pixel_size = 0.009
  sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  sign.modulate = Color("edcf8b")
  if id in ["snack_shack","grill_stand"]:
   var worker := person(identity,Color("c1aa81"),staff_count)
   workers.append(worker)
   worker.position = Vector3(33.25 if id == "snack_shack" else -34.6,0.05,17)
   var nameplate := G.label(identity,"LENI · CONCESSIONS" if id == "snack_shack" else "GRILL CREW",worker.position+Vector3(0,2.2,0),22)
   nameplate.pixel_size = 0.008
   nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   staff_count += 1
   var lamp := OmniLight3D.new()
   lamp.position = p+Vector3(0,2.6,0)
   lamp.light_color = Color("ffdb97")
   lamp.light_energy = 0.7
   lamp.omni_range = 5
   identity.add_child(lamp)
func stories(state: Dictionary) -> PackedStringArray:
 var lines := PackedStringArray()
 lines.append("Mara · Opening Day starts with your prep. Let’s give this town a reason to come back." if state.last.is_empty() else ("Mara · Look at that line at the gates. That field is something to be proud of." if float(state.last.score) >= 85 else "Mara · The field still needs work, but they showed up for us. We keep improving, one home date at a time."))
 lines.append("Eli, season-ticket regular · "+("I brought my neighbors. We finally have room to sit together." if "bleachers" in state.buildings else "Same seat, every summer. Keep this little park ours."))
 lines.append("Leni, concessions · "+("The stand is open and the first order is up. A good crowd keeps this place going." if "snack_shack" in state.buildings else "Someday we'll have our own snack stand. Right now, keep bringing people back."))
 if "grandstand" in state.buildings:
  lines.append("Mara · Covered seats, families staying longer. This is becoming a place the town can count on.")
 if int(state.games) > 0 and int(state.games)%6 == 0:
  lines.append("Mara · Six home dates in the books. Your ownership review is waiting in the Clubhouse.")
 else:
  lines.append("Mara · Next comes "+String(ClubSchedule.fixture(state.games).event)+". Take a breath, then let's get ready.")
 return lines
func begin(value: Dictionary) -> void:
 receipt = value.duplicate(true)
 clock = 0
 set_time(0)
func set_time(seconds: float) -> void:
 clock = seconds
 stage = "arrivals" if seconds < 7 else ("concourse" if seconds < 13 else ("game" if seconds < 40 else "stories"))
 inning = clampi(1+int((seconds-13)/3),1,9) if seconds >= 13 else 0
 home_runs = 0
 away_runs = 0
 for n in range(inning):
  home_runs += int(posmod(int(receipt.get("game",1))*5+n*5,7) < 2)
  away_runs += int(posmod(int(receipt.get("game",1))*3+n*4,9) < 2)
 if inning == 9 and home_runs == away_runs:
  if int(receipt.get("game",1))%2 == 0:
   home_runs += 1
  else:
   away_runs += 1
 score_sign.text = "OWLS %d  ·  %s %d\n%s" % [home_runs,String(fixture.get("opponent","VISITORS")).to_upper(),away_runs,"INNING %d / 9" % inning if stage == "game" else ("FINAL · THANK YOU, CEDAR GROVE" if stage == "stories" else "GATES OPEN · FIND YOUR SEAT")]
 for display in scoreboards:
  if is_instance_valid(display):
   display.text = "CEDAR GROVE OWLS\n"+score_sign.text
 score_sign.visible = hosted and not game.club.opening.active and stage in ["game","stories"]
 actors.visible = stage == "game"
 if actors.visible:
  var phase := fposmod(seconds-13,3.0)/3.0
  bat.rotation.z = -0.8
  bat.rotation.y = -1.5+clampf((phase-0.25)*8,0,3.5)
  if phase < 0.35:
   ball.position = Vector3(0,1.2,-18).lerp(Vector3(0,1,0),phase/0.35)
  else:
   var t := (phase-0.35)/0.65
   ball.position = Vector3(0,1,0).lerp(Vector3(20,0.2,-40),t)+Vector3.UP*sin(t*PI)*12
  var bases := [Vector3(0,0,0),Vector3(19,0,-19),Vector3(0,0,-38),Vector3(-19,0,-19),Vector3(0,0,0)]
  var leg := mini(3,int(phase*4))
  runner.position = bases[leg].lerp(bases[leg+1],fposmod(phase*4,1))
  runner.look_at(bases[leg+1])
  runner.get_node("LegLeft").rotation.x = sin(phase*PI*24)*0.5
  runner.get_node("LegRight").rotation.x = -sin(phase*PI*24)*0.5
  for i in range(2,fielders.size()):
   var fielder: Node3D = fielders[i].node
   var origin: Vector3 = fielders[i].origin
   var target := Vector3(ball.position.x,0,ball.position.z)
   fielder.position = origin.move_toward(target,maxf(0,sin(phase*PI))*1.2)
   if fielder.position.distance_squared_to(target) > 0.1:
    fielder.look_at(target)
   fielder.get_node("LegLeft").rotation.x = sin(phase*PI*12)*0.25
   fielder.get_node("LegRight").rotation.x = -sin(phase*PI*12)*0.25
func complete() -> void:
 if not receipt.is_empty():
  set_time(40)
 actors.visible = false
func _process(delta: float) -> void:
 var showing: bool = game.club.opening != null and game.club.opening.active
 var allowed: bool = hosted and game.shift.session.phase == ShiftSession.Phase.PRACTICE
 visible = game.shift.career.club.active
 for a in agents:
  a.node.visible = allowed
 actors.visible = allowed and showing and stage == "game"
 score_sign.visible = allowed and hosted and not showing and stage in ["game","stories"]
 if not allowed or (get_tree().paused and not showing):
  return
 advance(minf(delta,0.1))
func advance(delta: float) -> void:
 ambient_time += delta
 for worker in workers:
  worker.get_node("ArmRight").rotation.x = 0.5+sin(ambient_time*2)*0.2
 for a in agents:
  var fan: Node3D = a.node
  if a.wait > 0:
   a.wait -= delta
   continue
  var goal: Vector3 = a.route[a.target]
  var distance := fan.position.distance_to(goal)
  if distance < 0.08:
   if a.route.size() > 8 and a.target == 6:
    fan.rotation.y = PI
   a.target = 2 if a.target == a.route.size()-1 else a.target+1
   a.wait = 1.5+float(a.target%3)*0.7
  else:
   var direction := (goal-fan.position).normalized()
   fan.position = fan.position.move_toward(goal,a.speed*delta)
   fan.rotation.y = atan2(-direction.x,-direction.z)
   a.phase += delta*6
   fan.get_node("LegLeft").rotation.x = sin(a.phase)*0.32
   fan.get_node("LegRight").rotation.x = -sin(a.phase)*0.32
   fan.get_node("ArmLeft").rotation.x = -sin(a.phase)*0.22
   fan.get_node("ArmRight").rotation.x = sin(a.phase)*0.22
