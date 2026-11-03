class_name CrewVisual
extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")
var seated_pose := false
var pushing_pose := false
var watering_pose := false
var tamping_pose := false
var tamp_lift := 0.0
var limbs: Array[Node3D] = []
var phase := 0.0

func _ready() -> void:
 var shirt := Color("a99a77")
 var pants := Color("465159")
 var skin := Color("bd9279")
 var body_y := 1.12 if not seated_pose else 1.45
 G.tailored_body(self,Vector3(0,body_y,0),shirt)
 # Collar, belt, chest pocket, and a little grounds-crew badge.
 for side in [-1,1]:
  var collar := G.soft_box(self,Vector3(side*0.047,body_y+0.23,-0.16),Vector3(0.065,0.07,0.025),Color("c0b296"))
  collar.rotation.z = side*0.35
 G.soft_box(self,Vector3(0.12,body_y+0.02,-0.17),Vector3(0.10,0.11,0.018),Color("8e8164"))
 G.box(self,Vector3(-0.13,body_y+0.13,-0.19),Vector3(0.07,0.05,0.04),Color("2c625b"))
 G.soft_box(self,Vector3(0,body_y-0.3,0),Vector3(0.40,0.06,0.29),Color("614c37"))
 var head_y := body_y+0.57
 G.cylinder(self,Vector3(0,head_y-0.2,0),0.1,0.16,skin)
 G.sphere(self,Vector3(0,head_y,0),Vector3(0.31,0.39,0.32),skin)
 G.sphere(self,Vector3(0,head_y-0.025,-0.155),Vector3(0.06,0.075,0.065),skin)
 for side in [-1,1]:
  G.sphere(self,Vector3(side*0.153,head_y-0.015,0),Vector3(0.055,0.095,0.065),skin)
 G.sphere(self,Vector3(0,head_y-0.095,-0.145),Vector3(0.065,0.012,0.018),skin.darkened(0.18))
 G.sphere(self,Vector3(0,head_y+0.15,0.015),Vector3(0.35,0.16,0.35),Color("28585a"))
 G.sphere(self,Vector3(0,head_y+0.13,-0.17),Vector3(0.34,0.035,0.30),Color("28585a"))
 for x in [-0.065,0.065]:
  G.sphere(self,Vector3(x,head_y+0.025,-0.155),Vector3.ONE*0.024,Color("343a37"))
 for side in [-1,1]:
  var arm := Node3D.new()
  arm.position = Vector3(side*0.255,body_y+0.15,0)
  add_child(arm)
  G.sphere(arm,Vector3(0,-0.12,0),Vector3(0.19,0.31,0.21),shirt)
  var forearm := G.cylinder(arm,Vector3(0,-0.39,0),0.068,0.30,skin)
  (forearm.mesh as CylinderMesh).bottom_radius = 0.052
  G.sphere(arm,Vector3(0,-0.245,0),Vector3.ONE*0.135,skin)
  G.sphere(arm,Vector3(0,-0.56,0),Vector3(0.13,0.17,0.12),skin)
  if seated_pose or pushing_pose:
   arm.rotation.x = 0.95 if pushing_pose else 0.85
  limbs.append(arm)
  var leg := Node3D.new()
  leg.position = Vector3(side*0.15,body_y-0.32,0)
  add_child(leg)
  G.capsule(leg,Vector3(0,-0.27,0),0.108,0.62,pants)
  G.soft_box(leg,Vector3(0,-0.58,-0.06),Vector3(0.23,0.17,0.35),Color("594c3d"))
  if seated_pose:
   leg.rotation.x = 0.8
  limbs.append(leg)

func animate_walk(speed: float,delta: float) -> void:
 if seated_pose:
  return
 phase += speed*delta*2.6
 var strength := clampf(speed/4.5,0,1)
 for i in range(limbs.size()):
  if tamping_pose and i in [0,2]:
   limbs[i].rotation.x = 1.2+tamp_lift*0.4
   continue
  if watering_pose and i == 2:
   limbs[i].rotation.x = 1.1
   continue
  if pushing_pose and i in [0,2]:
   limbs[i].rotation.x = 0.95
   continue
  var sign_value := 1.0 if i in [0,3] else -1.0
  limbs[i].rotation.x = lerpf(limbs[i].rotation.x,sin(phase)*0.48*strength*sign_value,1-exp(-14*delta))
