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
 var key := str([state.active,state.buildings,crowd])
 if key == signature:
  return
 signature = key
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
 var sign := G.label(structures,"CEDAR GROVE OWLS\nLOW-A BASEBALL",Vector3(0,5.8,9),36)
 sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 sign.pixel_size = 0.012
 sign.modulate = Color("e1bb67")
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
  G.box(root,Vector3(0,y-0.14,z),Vector3(11,0.18,1.1),Color("b69b73"),true)
  for side in [-1,1]:
   G.box(root,Vector3(side*5.2,y*0.5,z),Vector3(0.10,y,0.10),Color("526569"))
  for i in range(20):
   var p := Vector3(-4.75+i*0.5,y+0.13,z-0.12)
   seats.append(p)
   backs.append(p+Vector3(0,0.28,0.27))
   world_seats.append(p+position)
 G.box_instances(root,seats,Vector3(0.43,0.12,0.46),Color("28585a"),"Seats")
 G.box_instances(root,backs,Vector3(0.43,0.42,0.08),Color("28585a"),"SeatBacks")
 if covered:
  G.box(root,Vector3(0,4.2,1.1),Vector3(11.8,0.16,4.4),Color("4b6e66"))
  for x in [-5.5,5.5]:
   for z in [-0.8,3]:
    G.box(root,Vector3(x,2.1,z),Vector3(0.12,4.2,0.12),Color("eee3c6"))
 return world_seats
func build_crowd(seats: PackedVector3Array,count: int) -> void:
 var palette := [Color("d4ac59"),Color("38695c"),Color("be6d4c"),Color("4b7994")]
 for color in range(4):
  var bodies := PackedVector3Array()
  for i in range(color,count,4):
   bodies.append(seats[i]+Vector3(0,0.27,0))
  if not bodies.is_empty():
   var fans := G.box_instances(structures,bodies,Vector3(0.30,0.42,0.25),palette[color],"Supporters")
   fans.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if count == 0:
  return
 var mesh := SphereMesh.new()
 mesh.radius = 0.13
 mesh.height = 0.26
 mesh.radial_segments = 8
 mesh.rings = 4
 var instances := MultiMesh.new()
 instances.transform_format = MultiMesh.TRANSFORM_3D
 instances.mesh = mesh
 instances.instance_count = count
 for i in range(count):
  instances.set_instance_transform(i,Transform3D(Basis.IDENTITY,seats[i]+Vector3(0,0.62,0)))
 var heads := MultiMeshInstance3D.new()
 heads.name = "SupporterHeads"
 heads.multimesh = instances
 heads.material_override = G.material(Color("d69e76"))
 heads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 structures.add_child(heads)
func build_snacks() -> void:
 var root := Node3D.new()
 root.name = "OwlsSnackShack"
 root.position = Vector3(31,0,20)
 structures.add_child(root)
 G.box(root,Vector3(0,0.04,0),Vector3(7,0.08,5),Color("c9b590"))
 G.box(root,Vector3(0,1.3,0),Vector3(5,2.6,3),Color("b46948"),true)
 G.box(root,Vector3(0,1.65,-1.53),Vector3(3.6,0.9,0.08),Color("eee3c6"))
 for i in range(10):
  G.box(root,Vector3(-2.7+i*0.6,2.8,-0.7),Vector3(0.6,0.12,3.6),Color("eee3c6") if i%2 == 0 else Color("28585a"))
 var label := G.label(root,"OWLS SNACK SHACK\nHOT DOGS · LEMONADE",Vector3(0,2.25,-1.60),32)
 label.rotation.y = PI
 label.pixel_size = 0.006
 label.modulate = Color("28585a")
