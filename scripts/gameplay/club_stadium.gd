class_name ClubStadium
extends Node3D
var game: Node
var structures: Node3D
var signature := ""
var seat_count := 0
var crowd_count := 0
var rebuilds := 0
const G = preload("res://scripts/gameplay/geometry.gd")
func sync(state: Dictionary) -> void:
 var crowd: int = state.last.get("attendance",0)
 var key := str([state.active,state.buildings,crowd,state.fans if "video_board" in state.buildings else 0])
 if key == signature:
  return
 signature = key
 var stock_board: Node3D = game.stadium.get_node("Scoreboard")
 var upgraded: bool = state.active and "scoreboard" in state.buildings
 stock_board.visible = not upgraded
 for shape in stock_board.find_children("*","CollisionShape3D",true,false):
  shape.set_deferred("disabled",upgraded)
 for stand in game.stadium.grandstands:
  stand.visible = not state.active
  for shape in stand.find_children("*","CollisionShape3D",true,false):
   shape.set_deferred("disabled",state.active)
 if structures != null:
  remove_child(structures)
  structures.queue_free()
 structures = Node3D.new()
 structures.name = "OwlsBallpark"
 add_child(structures)
 seat_count = 0
 crowd_count = 0
 if not state.active:
  return
 rebuilds += 1
 var locations := [Vector3(-7,0,10),Vector3(7,0,10),Vector3(-20,0,10),Vector3(20,0,10),Vector3(-7,0,17.5),Vector3(7,0,17.5),Vector3(-20,0,17.5),Vector3(20,0,17.5)]
 var banks: Array[PackedVector3Array] = []
 for i in range(int(state.capacity)/60):
  banks.append(build_bank(locations[i],"grandstand" in state.buildings))
 var seats := PackedVector3Array()
 for i in range(60):
  for bank in banks:
   seats.append(bank[i])
 seat_count = seats.size()
 crowd_count = mini(crowd,seats.size())
 build_crowd(seats,crowd_count)
 if "snack_shack" in state.buildings:
  build_snacks()
 if "grill_stand" in state.buildings:
  build_grill()
 if upgraded:
  build_scoreboard("video_board" in state.buildings,state)
 var sign := G.label(structures,"CEDAR GROVE OWLS\nLOW-A BASEBALL",Vector3(0,5.8,9),36)
 sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 sign.pixel_size = 0.012
 sign.modulate = Color("bca977")
func build_bank(position: Vector3,covered: bool) -> PackedVector3Array:
 var root := Node3D.new()
 root.name = "CoveredStand" if covered else "CommunityBleachers"
 root.position = position
 structures.add_child(root)
 var seats := PackedVector3Array()
 var backs := PackedVector3Array()
 var world_seats := PackedVector3Array()
 for row in range(3):
  var y := 0.55+row*0.55
  var z := row*1.1
  G.timber(root,Vector3(0,y-0.14,z),Vector3(11,0.18,1.1),Color("9e8c70"),true)
  for side in [-1,1]:
   G.box(root,Vector3(side*5.2,y*0.5,z),Vector3(0.10,y,0.10),Color("526569"))
  for i in range(20):
   var p := Vector3(-4.75+i*0.5,y+0.13,z-0.12)
   seats.append(p)
   backs.append(p+Vector3(0,0.28,0.27))
   world_seats.append(p+position)
 G.seat_instances(root,seats,Vector3(0.43,0.12,0.46),Color("28585a"),"Seats")
 G.seat_instances(root,backs,Vector3(0.43,0.42,0.065),Color("28585a"),"SeatBacks",true)
 # Side rails and tread nosings frame the existing platforms and seat count.
 for side in [-1,1]:
  var x: float = side*5.35
  G.tube(root,Vector3(x,1.52,-0.4),Vector3(x,2.65,2.5),0.035,Color("89918b"))
  for row in range(3):
   var y: float = 0.55+row*0.55
   G.tube(root,Vector3(x,y,row*1.1),Vector3(x,y+0.98,row*1.1),0.025,Color("89918b"))
   G.box(root,Vector3(side*5.03,y-0.035,row*1.1-0.53),Vector3(0.65,0.025,0.055),Color("c1b38e"))
 if covered:
  var roof := G.soft_box(root,Vector3(0,4.2,1.1),Vector3(11.8,0.10,4.4),Color("46574e"))
  roof.rotation.x = -0.08
  for rib in range(13):
   var seam := G.box(root,Vector3(-5.5+rib*0.92,4.27,1.1),Vector3(0.026,0.025,4.4),Color("647267"))
   seam.rotation.x = -0.08
  G.box(root,Vector3(0,4.03,-1.10),Vector3(11.8,0.18,0.09),Color("35443e"))
  for x in [-5.5,5.5]:
   G.beam(root,Vector3(x,3.25,-0.8),Vector3(x,4.05,0.2),0.085,Color("526569"))
  for x in [-5.5,5.5]:
   for z in [-0.8,3]:
    G.box(root,Vector3(x,2.1,z),Vector3(0.12,4.2,0.12),Color("d0c9b6"))
 return world_seats
func build_crowd(seats: PackedVector3Array,count: int) -> void:
 var palette := [Color("a28f68"),Color("50644e"),Color("936b58"),Color("526873")]
 for color in range(4):
  var bodies := PackedVector3Array()
  for i in range(count):
   if posmod(i*17+int(i/8)*7,4) == color:
    bodies.append(seats[i]+Vector3(0,0.27,0))
  if not bodies.is_empty():
   var fans := G.box_instances(structures,bodies,Vector3(0.30,0.42,0.25),palette[color],"Supporters")
   var body_mesh := CapsuleMesh.new()
   body_mesh.radius = 0.14
   body_mesh.height = 0.43
   body_mesh.radial_segments = 12
   body_mesh.rings = 4
   body_mesh.material = G.surface_material(palette[color],3)
   fans.multimesh.mesh = body_mesh
   fans.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if count == 0:
  return
 var detail := Node3D.new()
 detail.name = "CrowdDetails"
 structures.add_child(detail)
 var eyes := PackedVector3Array()
 var hair := PackedVector3Array()
 var noses := PackedVector3Array()
 var legs := PackedVector3Array()
 for i in range(count):
  var head := seats[i]+Vector3(0,0.59,0)
  for side in [-1,1]:
   eyes.append(head+Vector3(side*0.032,0.01,-0.091))
   legs.append(seats[i]+Vector3(side*0.075,-0.02,-0.15))
  hair.append(head+Vector3(0,0.085,0.018))
  noses.append(head+Vector3(0,-0.015,-0.098))
 G.box_instances(detail,eyes,Vector3(0.014,0.014,0.012),Color("30352f"),"Eyes")
 var hair_batch := G.box_instances(detail,hair,Vector3.ONE,Color("514a3c"),"Hair")
 var hair_mesh := SphereMesh.new()
 hair_mesh.radius = 0.103
 hair_mesh.height = 0.08
 hair_mesh.radial_segments = 12
 hair_mesh.rings = 6
 hair_batch.multimesh.mesh = hair_mesh
 hair_batch.material_override = G.material(Color("514a3c"))
 G.seat_instances(detail,noses,Vector3(0.025,0.035,0.03),Color("bd9279"),"Noses")
 var leg_batch := G.box_instances(detail,legs,Vector3.ONE,Color("414b50"),"SeatedLegs")
 var leg_mesh := CapsuleMesh.new()
 leg_mesh.radius = 0.047
 leg_mesh.height = 0.27
 leg_mesh.radial_segments = 12
 leg_mesh.rings = 4
 leg_batch.multimesh.mesh = leg_mesh
 leg_batch.material_override = G.surface_material(Color("414b50"),3)
 var mesh := SphereMesh.new()
 mesh.radius = 0.095
 mesh.height = 0.21
 mesh.radial_segments = 16
 mesh.rings = 8
 var instances := MultiMesh.new()
 instances.transform_format = MultiMesh.TRANSFORM_3D
 instances.mesh = mesh
 instances.instance_count = count
 for i in range(count):
  instances.set_instance_transform(i,Transform3D(Basis.IDENTITY,seats[i]+Vector3(0,0.59,0)))
 var heads := MultiMeshInstance3D.new()
 heads.name = "SupporterHeads"
 heads.multimesh = instances
 heads.material_override = G.material(Color("bd9279"))
 heads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 structures.add_child(heads)
func build_snacks() -> void:
 var root := Node3D.new()
 root.name = "OwlsSnackShack"
 root.position = Vector3(31,0,20)
 structures.add_child(root)
 G.box(root,Vector3(0,0.04,0),Vector3(7,0.08,5),Color("ada18a"))
 G.box(root,Vector3(0,1.3,0),Vector3(5,2.6,3),Color("966a52"),true)
 G.cladding(root,5,2.6,3,Color("805d49"))
 var roof := G.soft_box(root,Vector3(0,2.95,0),Vector3(5.7,0.13,3.6),Color("4b534b"))
 roof.rotation.x = -0.08
 serving_window(root,3.6,1.65,-1.60)
 G.timber(root,Vector3(0,1.15,-1.86),Vector3(4.1,0.10,0.65),Color("aa9473"))
 for i in range(10):
  var awning := G.box(root,Vector3(-2.7+i*0.6,2.72,-1.9),Vector3(0.6,0.045,1.8),Color("bdb49b") if i%2 == 0 else Color("52695f"))
  awning.rotation.x = 0.15
 G.box(root,Vector3(0,2.49,-2.78),Vector3(6,0.16,0.045),Color("52695f"))
 var label := G.label(root,"OWLS SNACK SHACK",Vector3(0,2.34,-1.74),32)
 label.rotation.y = PI
 label.pixel_size = 0.006
 label.modulate = Color("28585a")

func build_grill() -> void:
 var root := Node3D.new()
 root.name = "OwlsGrillStand"
 root.position = Vector3(-32,0,20)
 structures.add_child(root)
 G.box(root,Vector3(0,0.04,0),Vector3(8,0.08,6),Color("ada18a"))
 G.box(root,Vector3(0,1.4,0),Vector3(6,2.8,3.5),Color("28585a"),true)
 G.cladding(root,6,2.8,3.5,Color("354b49"))
 var roof := G.soft_box(root,Vector3(0,3.1,0),Vector3(6.6,0.12,4),Color("4b534b"))
 roof.rotation.x = -0.08
 serving_window(root,4.8,1.8,-1.88)
 G.box(root,Vector3(0,1.2,-2.05),Vector3(5.2,0.16,0.75),Color("d0c9b6"),true)
 for i in range(12):
  var awning := G.box(root,Vector3(-3.3+i*0.6,2.95,-2.3),Vector3(0.6,0.045,2.1),Color("b5a783") if i%2 else Color("8c6653"))
  awning.rotation.x = 0.16
 G.box(root,Vector3(0,2.68,-3.34),Vector3(7.2,0.18,0.045),Color("8c6653"))
 var menu := G.soft_box(root,Vector3(2.2,1.9,-1.94),Vector3(0.8,1,0.06),Color("303c34"))
 var lettering := G.label(menu,"GRILL\nBURGERS\nFRIES",Vector3(0,0,-0.04),24)
 lettering.rotation.y = PI
 lettering.pixel_size = 0.003
 G.box(root,Vector3(1.8,3.6,0.6),Vector3(0.65,1.2,0.65),Color("526569"))
 var sign := G.label(root,"OWLS GRILL",Vector3(0,2.54,-1.97),36)
 sign.rotation.y = PI
 sign.pixel_size = 0.007
 sign.modulate = Color("bca977")
 for x in [-2,2]:
  G.box(root,Vector3(x,0.8,-4),Vector3(2.4,0.15,1.1),Color("9e8c70"),true)
  for z in [-4.8,-3.2]:
   G.box(root,Vector3(x,0.45,z),Vector3(2.4,0.15,0.4),Color("9e8c70"),true)
func build_scoreboard(video: bool,state: Dictionary) -> void:
 var root := Node3D.new()
 root.name = "OwlsVideoBoard" if video else "OwlsElectronicScoreboard"
 root.position = game.layout.point3(game.layout.plate_position+Vector2(0,-game.layout.fence_radius-2))
 structures.add_child(root)
 for x in [-7,7]:
  G.box(root,Vector3(x,5,0),Vector3(0.7,10,0.7),Color("526569"),true)
 G.box(root,Vector3(0,9,0),Vector3(23,10,0.8),Color("bca977"),true)
 G.box(root,Vector3(0,9,0.5),Vector3(22,9,0.3),Color("172b30"))
 var content := "CEDAR GROVE OWLS\nELECTRONIC SCOREBOARD\nHOME   —     VISITORS   —\nREADY FOR FIRST PITCH"
 if video:
  content = "CEDAR GROVE OWLS\nWELCOME TO THE NEST\n%d SUPPORTERS · %d SEATS\nTHANK YOU, CEDAR GROVE!" % [state.fans,state.capacity]
 var display := G.label(root,content,Vector3(0,9,0.7),64)
 display.pixel_size = 0.018
 display.modulate = Color("bca977") if not video else Color("b7e4ce")
 if video:
  # A framed screen and pixel owl distinguish the video tier at field distance.
  G.box(root,Vector3(-8,9,0.68),Vector3(4.4,6.7,0.12),Color("28585a"))
  for x in [-9,-7]:
   G.box(root,Vector3(x,9.8,0.78),Vector3(1.4,1.4,0.08),Color("bca977"))
   G.box(root,Vector3(x,9.8,0.84),Vector3(0.5,0.7,0.06),Color("172b30"))
  G.box(root,Vector3(-8,8.5,0.78),Vector3(0.6,0.7,0.08),Color("966a52"))
  display.position.x = 2.1
  display.pixel_size = 0.015
 G.box(root,Vector3(0,14.2,0),Vector3(24,0.2,1.2),Color("28585a"))

func serving_window(root: Node3D,width: float,y: float,z: float) -> void:
 # Shallow display recess: trim, shelf, equipment and menu, all visual only.
 G.soft_box(root,Vector3(0,y,z),Vector3(width+0.18,1.10,0.12),Color("c0b59a"))
 G.box(root,Vector3(0,y,z-0.075),Vector3(width,0.92,0.045),Color("4c4435"))
 G.timber(root,Vector3(0,y-0.28,z-0.13),Vector3(width-0.15,0.065,0.22),Color("8c7759"))
 for side in [-1,1]:
  G.box(root,Vector3(side*width*0.5,y,z-0.13),Vector3(0.055,1.03,0.08),Color("d0c9b6"))
 for i in range(5):
  G.cylinder(root,Vector3(-width*0.29+i*0.17,y-0.14,z-0.18),0.045,0.22,Color("ccbba0"))
 var till := G.soft_box(root,Vector3(width*0.24,y-0.12,z-0.19),Vector3(0.32,0.20,0.19),Color("53615c"))
 G.soft_box(till,Vector3(0,0.13,0),Vector3(0.26,0.12,0.04),Color("263c38"))
 var menu := G.soft_box(root,Vector3(-width*0.34,y+0.12,z-0.14),Vector3(0.65,0.55,0.035),Color("2b3932"))
 var words := G.label(menu,"FRESH DAILY\nLOCAL FAVORITES",Vector3(0,0,-0.025),22)
 words.rotation.y = PI
 words.pixel_size = 0.002
 var lamp := G.soft_box(root,Vector3(0,y+0.43,z-0.16),Vector3(width*0.65,0.035,0.04),Color("ead7af"))
 var glow := G.material(Color("ead7af")).duplicate() as StandardMaterial3D
 glow.emission_enabled = true
 glow.emission = Color("b79a68").srgb_to_linear()
 glow.emission_energy_multiplier = 0.45
 lamp.material_override = glow
