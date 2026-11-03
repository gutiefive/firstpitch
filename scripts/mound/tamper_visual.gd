class_name TamperVisual
extends Node3D
func _ready() -> void:
 ParkGeometry.box(self,Vector3(0,0.04,0),Vector3(0.46,0.08,0.4),Color("526763"))
 ParkGeometry.box(self,Vector3(0,0.095,0),Vector3(0.2,0.04,0.18),Color("788279"))
 ParkGeometry.cylinder(self,Vector3(0,0.62,0),0.025,1.08,Color("bb925b"))
 ParkGeometry.box(self,Vector3(0,1.17,0),Vector3(0.42,0.055,0.055),Color("28585a"))
