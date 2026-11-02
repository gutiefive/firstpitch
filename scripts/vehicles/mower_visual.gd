class_name MowerVisual
extends Node3D
const G = preload("res://scripts/gameplay/geometry.gd")
const YELLOW := Color("d9ad40")
const DARK := Color("344745")
var wheels: Array[MeshInstance3D] = []
var steering: MeshInstance3D
var deck: Node3D
var driver: CrewVisual

func _ready() -> void:
 # A compact garden tractor: rear fenders, raised hood, inset grille, and wide deck.
 G.box(self,Vector3(0,0.5,0),Vector3(1.35,0.23,2.2),DARK)
 G.box(self,Vector3(0,0.72,-0.58),Vector3(1.05,0.64,1.05),YELLOW)
 var hood := G.box(self,Vector3(0,1.08,-0.59),Vector3(1.07,0.14,1.1),Color("ecc256"))
 hood.rotation.x = -0.06
 G.box(self,Vector3(0,0.85,-1.13),Vector3(0.84,0.43,0.055),DARK)
 for i in range(7):
  G.box(self,Vector3(-0.33+i*0.11,0.85,-1.17),Vector3(0.035,0.34,0.025),Color("75867b"))
 for x in [-0.44,0.44]:
  G.box(self,Vector3(x,1.01,-1.145),Vector3(0.16,0.1,0.06),Color("f4e4b0"))
  G.box(self,Vector3(x,0.74,0.58),Vector3(0.3,0.12,1.1),YELLOW)
  G.box(self,Vector3(x*1.45,0.45,0),Vector3(0.28,0.1,0.65),DARK)
 for side in [-1,1]:
  G.box(self,Vector3(side*0.54,0.9,0.6),Vector3(0.3,0.15,0.94),YELLOW)
  G.box(self,Vector3(side*0.548,0.83,-0.55),Vector3(0.025,0.07,0.8),Color("f3dc91"))
  var badge := G.label(self,"CG • 24",Vector3(side*0.565,0.9,-0.55),32)
  badge.pixel_size = 0.0018
  badge.rotation.y = side*PI/2
  badge.modulate = DARK
 G.box(self,Vector3(0,1.02,0.46),Vector3(0.76,0.19,0.65),Color("293d3f"))
 var back := G.box(self,Vector3(0,1.36,0.8),Vector3(0.76,0.66,0.16),Color("293d3f"))
 back.rotation.x = -0.12
 G.box(self,Vector3(0,1.37,0.7),Vector3(0.58,0.46,0.03),Color("425659"))
 G.beam(self,Vector3(0,0.65,-0.05),Vector3(0,1.4,-0.3),0.07,DARK)
 steering = G.ring(self,Vector3(0,1.42,-0.3),0.22,0.26,DARK)
 steering.rotation.x = 0.32
 G.box(steering,Vector3.ZERO,Vector3(0.43,0.035,0.045),DARK)
 G.box(steering,Vector3(0,0,0.1),Vector3(0.04,0.035,0.2),DARK)
 deck = G.box(self,Vector3(0,0.22,-0.3),Vector3(2.4,0.18,1.15),Color("bfa13f"))
 for x in [-0.66,0.66]:
  G.cylinder(deck,Vector3(x,0.13,0),0.44,0.1,YELLOW)
 G.box(deck,Vector3(1.25,0.02,0),Vector3(0.35,0.12,0.63),DARK)
 G.box(self,Vector3(0,0.43,-1.25),Vector3(1.6,0.13,0.15),DARK)
 G.cylinder(self,Vector3(0.38,1.22,-0.75),0.055,0.5,DARK)
 for x in [-0.88,0.88]:
  for z in [-0.85,0.8]:
   var radius := 0.34 if z < 0 else 0.43
   var wheel := G.cylinder(self,Vector3(x,radius,z),radius,0.29,Color("273332"))
   wheel.rotation.z = PI/2
   wheels.append(wheel)
   G.cylinder(wheel,Vector3(0,0.16 if x < 0 else -0.16,0),radius*0.54,0.035,Color("d6d5b7"))
   G.cylinder(wheel,Vector3(0,0.19 if x < 0 else -0.19,0),radius*0.19,0.045,DARK)
   for lug in range(14):
    var a := TAU*lug/14.0
    var tread := G.box(wheel,Vector3(sin(a)*radius,0,cos(a)*radius),Vector3(0.12,0.32,0.045),Color("34413b"))
    tread.rotation.y = a
 driver = CrewVisual.new()
 driver.seated_pose = true
 driver.position = Vector3(0,-0.05,0.4)
 add_child(driver)
 driver.visible = false
