class_name CrewVisual
extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")
var seated_pose := false
var pushing_pose := false
var limbs: Array[Node3D] = []
var phase := 0.0

func _ready() -> void:
 var shirt := Color("e0b85d")
 var pants := Color("365d69")
 var skin := Color("d69e76")
 var body_y := 1.12 if not seated_pose else 1.45
 G.sphere(self,Vector3(0,body_y,0),Vector3(0.63,0.74,0.39),shirt)
 # Collar, belt, chest pocket, and a little grounds-crew badge.
 G.box(self,Vector3(0,body_y+0.24,-0.19),Vector3(0.16,0.15,0.025),Color("f0d89a"))
 G.box(self,Vector3(0.14,body_y+0.02,-0.19),Vector3(0.12,0.13,0.03),Color("bd903d"))
 G.box(self,Vector3(-0.13,body_y+0.13,-0.19),Vector3(0.07,0.05,0.04),Color("2c625b"))
 G.box(self,Vector3(0,body_y-0.3,0),Vector3(0.48,0.08,0.31),Color("614c37"))
 var head_y := body_y+0.57
 G.cylinder(self,Vector3(0,head_y-0.2,0),0.1,0.16,skin)
 G.sphere(self,Vector3(0,head_y,0),Vector3(0.4,0.45,0.38),skin)
 G.sphere(self,Vector3(0,head_y-0.02,-0.2),Vector3(0.1,0.1,0.09),skin)
 G.sphere(self,Vector3(0,head_y+0.17,0.015),Vector3(0.44,0.22,0.42),Color("28585a"))
 G.box(self,Vector3(0,head_y+0.14,-0.2),Vector3(0.42,0.045,0.34),Color("28585a"))
 for x in [-0.085,0.085]:
  G.sphere(self,Vector3(x,head_y+0.025,-0.18),Vector3.ONE*0.04,Color("343a37"))
 for side in [-1,1]:
  var arm := Node3D.new()
  arm.position = Vector3(side*0.32,body_y+0.15,0)
  add_child(arm)
  G.sphere(arm,Vector3(0,-0.12,0),Vector3(0.23,0.35,0.25),shirt)
  G.cylinder(arm,Vector3(0,-0.39,0),0.085,0.28,skin)
  G.sphere(arm,Vector3(0,-0.56,0),Vector3(0.16,0.18,0.15),skin)
  if seated_pose or pushing_pose:
   arm.rotation.x = 0.95 if pushing_pose else 0.85
  limbs.append(arm)
  var leg := Node3D.new()
  leg.position = Vector3(side*0.15,body_y-0.32,0)
  add_child(leg)
  G.box(leg,Vector3(0,-0.27,0),Vector3(0.23,0.54,0.29),pants)
  G.box(leg,Vector3(0,-0.58,-0.06),Vector3(0.26,0.18,0.43),Color("594c3d"))
  if seated_pose:
   leg.rotation.x = 0.8
  limbs.append(leg)

func animate_walk(speed: float,delta: float) -> void:
 if seated_pose:
  return
 phase += speed*delta*2.6
 var strength := clampf(speed/4.5,0,1)
 for i in range(limbs.size()):
  if pushing_pose and i in [0,2]:
   limbs[i].rotation.x = 0.95
   continue
  var sign_value := 1.0 if i in [0,3] else -1.0
  limbs[i].rotation.x = lerpf(limbs[i].rotation.x,sin(phase)*0.48*strength*sign_value,1-exp(-14*delta))
