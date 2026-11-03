class_name FieldMarkings
extends Node3D
# Static field furniture: these marks are not part of the playable foul-line task.
const G = preload("res://scripts/gameplay/geometry.gd")
const WHITE := Color("f5edd6")
const FOOT := 0.3048
const PLATE_WIDTH := 17*0.0254
const BATTER_WIDTH := 4*FOOT
const BATTER_LENGTH := 6*FOOT
const COACH_WIDTH := 5*FOOT
const COACH_LENGTH := 20*FOOT
const COACH_LINE_CLEARANCE := 15*FOOT
const ON_DECK_RADIUS := 2.5*FOOT
const LINE_WIDTH := 0.05
var plate: MeshInstance3D
var batter_boxes: Array[Node3D] = []
var coach_boxes: Array[Node3D] = []
var on_deck_circles: Array[Node3D] = []

func _ready() -> void:
 name = "FieldMarkings"
 build_home_plate()
 for side in [-1,1]:
  var box := rectangle("BatterBox",Vector3(side*(PLATE_WIDTH*0.5+6*0.0254+BATTER_WIDTH*0.5),0.15,-PLATE_WIDTH*0.25),BATTER_WIDTH,BATTER_LENGTH)
  batter_boxes.append(box)
  var along := Vector3(side,0,-1).normalized()
  var outward := Vector3(side,0,1).normalized()
  var center := along*(90*FOOT-COACH_LENGTH*0.5)+outward*(COACH_LINE_CLEARANCE+COACH_WIDTH*0.5)
  center.y = 0.012
  var coach := rectangle("ThirdBaseCoachBox" if side < 0 else "FirstBaseCoachBox",center,COACH_WIDTH,COACH_LENGTH)
  coach.rotation.y = atan2(along.x,along.z)
  coach_boxes.append(coach)
  var circle := Node3D.new()
  circle.name = "HomeOnDeck" if side < 0 else "VisitorOnDeck"
  # Both circles lie 37 ft from home, inside the new foul-side fence.
  circle.position = Vector3(side*sqrt(pow(37*FOOT,2)-pow(2.5,2)),0,-2.5)
  add_child(circle)
  var clay := G.cylinder(circle,Vector3(0,0.006,0),1.12,0.012,Color("b7794c"))
  (clay.mesh as CylinderMesh).radial_segments = 64
  flat_ring(circle,ON_DECK_RADIUS-LINE_WIDTH*0.5,ON_DECK_RADIUS+LINE_WIDTH*0.5,0.016)
  on_deck_circles.append(circle)

func rectangle(title: String,center: Vector3,width: float,length: float) -> Node3D:
 var root := Node3D.new()
 root.name = title
 root.position = center
 add_child(root)
 for z in [-length*0.5,length*0.5]:
  G.box(root,Vector3(0,0,z),Vector3(width+LINE_WIDTH,0.007,LINE_WIDTH),WHITE)
 for x in [-width*0.5,width*0.5]:
  G.box(root,Vector3(x,0,0),Vector3(LINE_WIDTH,0.007,length),WHITE)
 return root

func build_home_plate() -> void:
 var half := PLATE_WIDTH*0.5
 var points := PackedVector2Array([Vector2(-half,-half),Vector2(half,-half),Vector2(half,0),Vector2(0,half),Vector2(-half,0)])
 polygon(points,0.145,1.07,Color("344b45"),"PlateBorder")
 plate = polygon(points,0.151,1,WHITE,"HomePlate")

func polygon(points: PackedVector2Array,height: float,scale_value: float,color: Color,title: String) -> MeshInstance3D:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in [0,1,2,0,2,3,0,3,4]:
  var p := points[index]*scale_value
  surface.set_normal(Vector3.UP)
  surface.add_vertex(Vector3(p.x,height,p.y))
 var node := MeshInstance3D.new()
 node.name = title
 node.mesh = surface.commit()
 node.material_override = G.material(color)
 add_child(node)
 return node

func flat_ring(parent: Node3D,inner: float,outer: float,height: float) -> void:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(64):
  var a := Vector3(cos(i*TAU/64),0,sin(i*TAU/64))
  var b := Vector3(cos((i+1)*TAU/64),0,sin((i+1)*TAU/64))
  for point in [a*inner,a*outer,b*outer,a*inner,b*outer,b*inner]:
   surface.set_normal(Vector3.UP)
   surface.add_vertex(point+Vector3.UP*height)
 var node := MeshInstance3D.new()
 node.name = "OnDeckPaint"
 node.mesh = surface.commit()
 node.material_override = G.material(WHITE)
 parent.add_child(node)
