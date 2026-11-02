class_name ParkProps
extends RefCounted
const G = preload("res://scripts/gameplay/geometry.gd")
const TEAL := Color("28585a")
const CREAM := Color("eee3c6")
const WOOD := Color("b78754")
const STEEL := Color("526569")

static func group(parent: Node3D, title: String, pos: Vector3) -> Node3D:
 var root := Node3D.new()
 root.name = title
 root.position = pos
 parent.add_child(root)
 return root

static func shed(parent: Node3D) -> void:
 var root := group(parent,"GroundsWorkshop",Vector3(38,0,-11))
 G.box(root,Vector3(0,1.8,0),Vector3(8,3.6,7),TEAL,true)
 # Siding, corners, fascia, and a pitched standing-seam roof.
 for height in range(12):
  G.box(root,Vector3(0,0.2+height*0.28,3.515),Vector3(7.9,0.035,0.045),Color("367071"))
 for x in [-4.04,4.04]:
  for z in [-3.53,3.53]:
   G.box(root,Vector3(x,1.8,z),Vector3(0.15,3.65,0.15),CREAM)
  for height in range(12):
   G.box(root,Vector3(x,0.2+height*0.28,0),Vector3(0.045,0.035,7),Color("367071"))
 for side in [-1,1]:
  var roof := G.box(root,Vector3(side*2.1,3.97,0),Vector3(4.5,0.18,8),Color("374c4b"))
  roof.rotation.z = -side*0.18
  for z in range(-4,5):
   var seam := G.box(root,Vector3(side*2.1,4.08,z*0.88),Vector3(4.5,0.045,0.045),Color("50645e"))
   seam.rotation.z = -side*0.18
 G.box(root,Vector3(0,4.4,0),Vector3(0.18,0.15,8.1),CREAM)
 # Broad front door and a framed blue window face the concourse.
 G.box(root,Vector3(-1,1.3,3.56),Vector3(2.2,2.6,0.13),CREAM)
 G.box(root,Vector3(-1,1.28,3.65),Vector3(1.95,2.4,0.08),Color("98764d"))
 G.beam(root,Vector3(-1.9,0.2,3.72),Vector3(-0.1,2.35,3.72),0.09,CREAM)
 G.sphere(root,Vector3(-0.3,1.3,3.74),Vector3.ONE*0.12,Color("353e3b"))
 G.box(root,Vector3(2,1.9,3.6),Vector3(1.7,1.25,0.14),CREAM)
 G.box(root,Vector3(2,1.9,3.69),Vector3(1.45,1.0,0.05),Color("587f89"))
 G.box(root,Vector3(2,1.9,3.74),Vector3(0.07,1.05,0.04),CREAM)
 G.box(root,Vector3(2,1.9,3.74),Vector3(1.5,0.07,0.04),CREAM)
 G.box(root,Vector3(0,3.1,3.66),Vector3(5.8,0.55,0.15),CREAM)
 var sign := G.label(root,"GROUNDS & FIELD",Vector3(0,3.1,3.76),42)
 sign.pixel_size = 0.008
 sign.modulate = TEAL
 # Service-side window and wall-mounted tools are visible at the player spawn.
 G.box(root,Vector3(-4.09,2,0.5),Vector3(0.1,1.2,1.5),CREAM)
 G.box(root,Vector3(-4.15,2,0.5),Vector3(0.03,0.98,1.25),Color("587f89"))
 for z in [-2.0,-1.5]:
  G.beam(root,Vector3(-4.2,0.2,z),Vector3(-4.2,2.2,z+0.1),0.05,WOOD)
  G.box(root,Vector3(-4.2,0.18,z),Vector3(0.15,0.12,0.55),STEEL)
 G.box(root,Vector3(0,0.06,4.1),Vector3(8.7,0.12,1),Color("b6b5a0"))
 barrel(root,Vector3(4.9,0,2.5))
 barrel(root,Vector3(4.9,0,1.4))
 # Coiled field tarp on its dolly, out of the driving lane.
 var tarp := G.cylinder(root,Vector3(6,0.7,-4.5),0.55,5.0,Color("82a490"))
 tarp.rotation.z = PI/2
 G.box(root,Vector3(6,0.18,-4.5),Vector3(5.5,0.18,1.3),STEEL)

static func barrel(parent: Node3D,pos: Vector3) -> void:
 G.cylinder(parent,pos+Vector3.UP*0.48,0.38,0.96,Color("b96741"))
 for y in [0.15,0.8]:
  G.ring(parent,pos+Vector3.UP*y,0.36,0.4,Color("7d563f"))

static func dugout(parent: Node3D,side: int) -> void:
 var root := group(parent,"HomeDugout" if side < 0 else "VisitorDugout",Vector3(side*27,0,-7))
 G.box(root,Vector3(0,0.08,0),Vector3(11.5,0.16,4.6),Color("c4b795"))
 G.box(root,Vector3(0,1.35,-1.8),Vector3(11,2.7,0.25),TEAL,true)
 for x in [-5.4,5.4]:
  G.box(root,Vector3(x,1.35,0),Vector3(0.24,2.7,4),TEAL,true)
  G.box(root,Vector3(x,1.5,1.9),Vector3(0.16,3,0.16),CREAM)
 G.box(root,Vector3(0,2.85,0),Vector3(12,0.22,5),Color("384f4c"))
 G.box(root,Vector3(0,2.65,2.45),Vector3(12,0.35,0.16),CREAM)
 var sign := G.label(root,"CEDAR GROVE  /  HOME" if side < 0 else "VISITING CLUB",Vector3(0,2.66,2.55),40)
 sign.pixel_size = 0.007
 sign.modulate = TEAL
 bench(root,Vector3(0,0.15,-0.7),8.5)
 for x in [-4.5,4.5]:
  G.cylinder(root,Vector3(x,0.48,0.8),0.24,0.7,Color("e7d5af"))

static func bench(parent: Node3D,pos: Vector3,width: float = 3.0) -> void:
 var root := group(parent,"Bench",pos)
 for z in [-0.2,0.05,0.3]:
  G.box(root,Vector3(0,0.52,z),Vector3(width,0.1,0.2),WOOD)
 for y in [0.85,1.1]:
  G.box(root,Vector3(0,y,-0.38),Vector3(width,0.18,0.09),WOOD)
 for x in [-width*0.38,width*0.38]:
  G.box(root,Vector3(x,0.27,0),Vector3(0.08,0.54,0.6),STEEL)
  G.box(root,Vector3(x,0.7,-0.38),Vector3(0.07,0.8,0.07),STEEL)

static func grandstand(parent: Node3D,side: int) -> void:
 var root := group(parent,"Grandstand",Vector3(side*12,0,11))
 var seats := PackedVector3Array()
 var backs := PackedVector3Array()
 for row in range(5):
  var y := 0.65+row*0.65
  var z := row*1.25
  G.box(root,Vector3(0,y-0.15,z),Vector3(17.5,0.18,1.2),Color("b4b9ac"),true)
  for x in [-8.0,8.0]:
   G.box(root,Vector3(x,y*0.5,z),Vector3(0.14,y,0.14),STEEL)
  for seat in range(22):
   var x := -8.0+seat*0.76
   if absf(x) < 0.8:
    continue
   seats.append(Vector3(x,y+0.18,z-0.12))
   backs.append(Vector3(x,y+0.48,z+0.15))
  for x in [-8.7,8.7]:
   G.box(root,Vector3(x,y+0.6,z),Vector3(0.07,1.2,0.07),CREAM)
 G.box_instances(root,seats,Vector3(0.62,0.15,0.57),TEAL,"SeatCushions")
 G.box_instances(root,backs,Vector3(0.62,0.6,0.1),TEAL,"SeatBacks")
 for side_x in [-8.7,8.7]:
  G.beam(root,Vector3(side_x,1.25,0),Vector3(side_x,3.85,5),0.09,CREAM)
 G.box(root,Vector3(0,4.8,2.5),Vector3(19.5,0.18,7.2),Color("4b6e66"))
 for x in [-9,9]:
  for z in [-0.5,5.6]:
   G.box(root,Vector3(x,2.4,z),Vector3(0.15,4.8,0.15),CREAM)
 G.box(root,Vector3(0,4.65,-1.1),Vector3(19.5,0.4,0.12),CREAM)
 var sign := G.label(root,"CEDAR GROVE BALLPARK",Vector3(0,4.64,-1.2),48)
 sign.rotation.y = PI
 sign.pixel_size = 0.008
 sign.modulate = TEAL

static func scoreboard(parent: Node3D) -> void:
 var root := group(parent,"Scoreboard",Vector3(0,0,-106))
 for x in [-7,7]:
  G.box(root,Vector3(x,4.5,0),Vector3(0.55,9,0.55),WOOD,true)
 G.box(root,Vector3(0,9,0),Vector3(21,8.3,0.55),CREAM,true)
 G.box(root,Vector3(0,9,0.35),Vector3(20.3,7.6,0.2),TEAL)
 for entry in [["CEDAR GROVE",12.0,80],["B A L L P A R K",10.9,38],["INNING    1    2    3    4    5    6    7    8    9      R",9.5,30],["HOME     0    0    0    0    0    0    0    0    0      0",8.5,30],["AWAY     0    0    0    0    0    0    0    0    0      0",7.5,30],["BALL    ● ● ●       STRIKE    ● ●       OUT    ● ●",6.2,28]]:
  var label := G.label(root,entry[0],Vector3(0,entry[1],0.5),entry[2])
  label.pixel_size = 0.018
  label.modulate = CREAM
 for y in [7.0,8.0,9.0,10.1]:
  G.box(root,Vector3(0,y,0.49),Vector3(19,0.035,0.03),Color("94ad98"))
 G.box(root,Vector3(0,13.3,0.1),Vector3(22,0.2,1),Color("4b6e66"))

static func tree(parent: Node3D,pos: Vector3,height: float,variant: int) -> void:
 var root := group(parent,"ShadeTree",pos)
 G.cylinder(root,Vector3(0,height*0.25,0),0.22,height*0.5,Color("775d42"))
 G.beam(root,Vector3(0,height*0.35,0),Vector3(height*0.19,height*0.63,0),0.13,Color("775d42"))
 var foliage: Color = [Color("44734b"),Color("66874b"),Color("346953")][variant%3]
 G.sphere(root,Vector3(0,height*0.77,0),Vector3(height*0.65,height*0.65,height*0.6),foliage)
 G.sphere(root,Vector3(height*0.22,height*0.65,height*0.1),Vector3.ONE*height*0.5,foliage.lightened(0.06))
 G.sphere(root,Vector3(-height*0.2,height*0.62,-height*0.08),Vector3.ONE*height*0.48,foliage.darkened(0.05))

static func light_tower(parent: Node3D,pos: Vector3) -> void:
 var root := group(parent,"LightTower",pos)
 G.cylinder(root,Vector3(0,10,0),0.16,20,STEEL)
 G.box(root,Vector3(0,20,0),Vector3(4.5,0.16,0.18),STEEL)
 for x in range(5):
  G.box(root,Vector3(x-2,20,0.1),Vector3(0.65,0.65,0.3),Color("455557"))
  G.box(root,Vector3(x-2,20,0.28),Vector3(0.5,0.48,0.04),CREAM)
