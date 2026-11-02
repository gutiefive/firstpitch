class_name ToolBay
extends Node3D
@export var service_radius := 9.0
var parked_drag: DragAttachment
var spare_deck: Node3D
const G = preload("res://scripts/gameplay/geometry.gd")

func _ready() -> void:
 name = "ToolBay"
 position = Vector3(35,0,-23)
 G.box(self,Vector3(0,0.15,0),Vector3(3.4,0.3,1.8),Color("a38c62"),true)
 parked_drag = DragAttachment.new()
 parked_drag.position.y = 0.22
 parked_drag.follow_field = false
 add_child(parked_drag)
 parked_drag.set_lowered(true)
 spare_deck = Node3D.new()
 spare_deck.position.y = 0.45
 add_child(spare_deck)
 G.box(spare_deck,Vector3.ZERO,Vector3(2.4,0.18,1.15),Color("d9ad40"))
 for x in [-0.65,0.65]:
  G.cylinder(spare_deck,Vector3(x,0.14,0),0.4,0.13,Color("ecc256"))
 spare_deck.visible = false
 for x in [-1.7,1.7]:
  G.box(self,Vector3(x,1.5,-0.9),Vector3(0.1,3,0.1),Color("28585a"))
 G.box(self,Vector3(0,2.7,-0.9),Vector3(3.5,0.65,0.12),Color("eee3c6"))
 var sign := G.label(self,"TOOL BAY\nQ  SWAP MOWER / DRAG",Vector3(0,2.7,-0.8),38)
 sign.pixel_size = 0.0045
 sign.modulate = Color("28585a")

func contains(world_position: Vector3) -> bool:
 return Vector2(world_position.x-global_position.x,world_position.z-global_position.z).length() <= service_radius

func show_equipped_drag(equipped: bool) -> void:
 parked_drag.visible = not equipped
 spare_deck.visible = equipped
