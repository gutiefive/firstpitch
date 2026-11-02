class_name DragAttachment
extends Node3D
@export var working_width := 2.8
@export var working_depth := 1.2
var lowered := false
var follow_field := true
var frame: Node3D
var tow_bars: Array[MeshInstance3D] = []
const G = preload("res://scripts/gameplay/geometry.gd")

func _ready() -> void:
 frame = Node3D.new()
 frame.name = "DragFrame"
 add_child(frame)
 var red := Color("a65d42")
 var steel := Color("72817b")
 for z in [-working_depth*0.5,working_depth*0.5]:
  G.box(frame,Vector3(0,0,z),Vector3(working_width,0.09,0.09),red)
 for x in [-working_width*0.5,working_width*0.5]:
  G.box(frame,Vector3(x,0,0),Vector3(0.09,0.09,working_depth),red)
 for i in range(15):
  var x := -working_width*0.5+i*working_width/14
  G.box(frame,Vector3(x,-0.035,0),Vector3(0.025,0.035,working_depth),steel)
 for z in [-0.35,0,0.35]:
  G.box(frame,Vector3(0,-0.025,z),Vector3(working_width,0.025,0.025),steel)
 for side in [-1,1]:
  tow_bars.append(G.beam(self,Vector3(0,0.42,-1.4),Vector3(side*0.95,0.15,-0.5),0.055,steel))
 G.ring(self,Vector3(0,0.42,-1.4),0.06,0.09,steel)
 set_lowered(false)

func set_lowered(value: bool) -> void:
 lowered = value
 if frame != null:
  frame.position.y = 0.10 if value else 0.6
  frame.rotation.x = 0 if value else 0.2
  update_tow_bars()

func _process(_delta: float) -> void:
 if lowered and follow_field:
  # The tractor collision body sits slightly below its visual wheel origin.
  # Anchor the mesh to the existing dirt height rather than to that body offset.
  var point := Vector2(global_position.x,global_position.z)
  var dirt_height := 0.13 if point.length() < 6 else 0.0375
  frame.global_position.y = dirt_height+0.06
 update_tow_bars()

func update_tow_bars() -> void:
 var hitch := Vector3(0,0.42,-1.4)
 for index in range(tow_bars.size()):
  var side := -1.0 if index == 0 else 1.0
  var end := frame.position+frame.basis*Vector3(side*0.95,0,-0.5)
  var direction := end-hitch
  var bar := tow_bars[index]
  bar.position = (hitch+end)*0.5
  bar.quaternion = Quaternion(Vector3.UP,direction.normalized())
  (bar.mesh as BoxMesh).size = Vector3(0.055,direction.length(),0.055)
